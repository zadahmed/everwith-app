"""
Share verification endpoints for viral sharing incentives.
"""

from datetime import datetime, timedelta
from typing import List, Optional

import requests
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, HttpUrl, Field

from app.core.security import get_current_user
from app.models.database import (
    User as DBUser,
    ShareEvent,
    CreditTransaction,
    UserStats,
)

router = APIRouter(prefix="/api/share", tags=["share"])

SUPPORTED_PLATFORMS = {"instagram", "tiktok"}
REQUIRED_HASHTAG = "#everwithapp"
MAX_REWARDS_PER_DAY = 3
COOLDOWN_HOURS = 6


class ShareVerificationRequest(BaseModel):
    platform: str
    share_url: Optional[HttpUrl] = None
    caption: Optional[str] = None
    hashtags: List[str] = Field(default_factory=list)
    share_type: str = "viral_share"


class ShareVerificationResponse(BaseModel):
    message: str
    credits_awarded: int
    new_credit_balance: int
    verification_id: str
    already_claimed: bool = False


def _validate_hashtag(payload: ShareVerificationRequest) -> None:
    hashtag = REQUIRED_HASHTAG.lower()
    caption = (payload.caption or "").lower()
    hashtags = [tag.lower() for tag in payload.hashtags]
    if hashtag not in hashtags and hashtag not in caption:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Share must include the {REQUIRED_HASHTAG} hashtag.",
        )


async def _enforce_limits(user: DBUser) -> Optional[ShareEvent]:
    """Enforce per-day and cooldown limits. Returns recent event if still in cooldown."""
    now = datetime.utcnow()
    day_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    
    daily_count = await ShareEvent.find(
        ShareEvent.user_id == user.id,
        ShareEvent.created_at >= day_start,
        ShareEvent.verified == True,
    ).count()
    
    if daily_count >= MAX_REWARDS_PER_DAY:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Daily sharing reward limit reached. Please try again tomorrow.",
        )
    
    cooldown_cutoff = now - timedelta(hours=COOLDOWN_HOURS)
    recent_share_list = await ShareEvent.find(
        ShareEvent.user_id == user.id,
        ShareEvent.created_at >= cooldown_cutoff,
        ShareEvent.verified == True,
    ).sort("-created_at").limit(1).to_list()
    
    recent_share = recent_share_list[0] if recent_share_list else None
    
    return recent_share


def _verify_share_url(share_url: Optional[str]) -> None:
    if not share_url:
        return
    try:
        response = requests.head(share_url, timeout=5)
        if response.status_code >= 400:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unable to verify the shared link. Please make sure it is public.",
            )
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Could not reach the shared link: {exc}",
        ) from exc


@router.post("/verify", response_model=ShareVerificationResponse)
async def verify_share(
    payload: ShareVerificationRequest,
    current_user: DBUser = Depends(get_current_user),
):
    """Verify a public social share and reward the user with a credit."""
    platform = payload.platform.lower()
    if platform not in SUPPORTED_PLATFORMS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported platform '{payload.platform}'.",
        )
    
    _validate_hashtag(payload)
    _verify_share_url(payload.share_url)
    
    # Limit duplicate URLs
    if payload.share_url:
        duplicate = await ShareEvent.find_one(
            ShareEvent.share_url == str(payload.share_url),
            ShareEvent.user_id == current_user.id,
        )
        if duplicate:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This post has already been submitted.",
            )
    
    recent_share = await _enforce_limits(current_user)
    if recent_share:
        cooldown_remaining = (
            recent_share.created_at + timedelta(hours=COOLDOWN_HOURS) - datetime.utcnow()
        )
        if cooldown_remaining.total_seconds() > 0:
            hours = int(cooldown_remaining.total_seconds() // 3600) + 1
            return ShareVerificationResponse(
                message=f"You can earn another share credit in about {hours} hour(s).",
                credits_awarded=0,
                new_credit_balance=current_user.credits,
                verification_id=str(recent_share.id),
                already_claimed=True,
            )
    
    share_event = ShareEvent(
        user_id=current_user,
        share_type=payload.share_type,
        platform=platform,
        share_url=str(payload.share_url) if payload.share_url else None,
        caption=payload.caption,
        hashtags=[tag.lower() for tag in payload.hashtags],
        reward_credits=1,
        verification_status="verified",
        verified=True,
        verified_at=datetime.utcnow(),
        verification_notes=f"Hashtag verified for {platform}",
    )
    await share_event.insert()
    
    current_user.credits += share_event.reward_credits
    await current_user.save()
    
    credit_transaction = CreditTransaction(
        user_id=current_user,
        credits=share_event.reward_credits,
        transaction_type="reward",
        description=f"Verified share on {platform}",
    )
    await credit_transaction.insert()
    
    stats = await UserStats.find_one(UserStats.user_id == current_user.id)
    if stats:
        stats.total_shares += 1
        stats.credits_earned_from_shares += share_event.reward_credits
        stats.updated_at = datetime.utcnow()
        await stats.save()
    else:
        stats = UserStats(
            user_id=current_user,
            total_shares=1,
            credits_earned_from_shares=share_event.reward_credits,
        )
        await stats.insert()
    
    return ShareVerificationResponse(
        message="Thanks for sharing! You've earned +1 credit.",
        credits_awarded=share_event.reward_credits,
        new_credit_balance=current_user.credits,
        verification_id=str(share_event.id),
        already_claimed=False,
    )

