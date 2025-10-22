"""
Feedback and Support API
Handles user feedback, bug reports, and support requests
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, List
from datetime import datetime
from app.models.database import User as DBUser, UserFeedback, ShareEvent, UserStats, CreditTransaction
from app.core.security import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/api/feedback", tags=["feedback"])


class FeedbackCreate(BaseModel):
    feedback_type: str  # "general", "bug", "feature", "help"
    subject: str
    message: str
    device_info: Optional[dict] = None
    app_version: Optional[str] = "1.0.0"


class FeedbackResponse(BaseModel):
    id: str
    feedback_type: str
    subject: str
    message: str
    status: str
    created_at: datetime


class ShareRewardRequest(BaseModel):
    share_type: str  # "social", "direct", "link"
    platform: Optional[str] = None
    image_id: Optional[str] = None


class UserStatsResponse(BaseModel):
    total_images_processed: int
    total_restores: int
    total_merges: int
    total_shares: int
    credits_earned_from_shares: int
    favorite_filter: Optional[str]
    member_since: datetime


@router.post("/submit", response_model=dict)
async def submit_feedback(
    feedback: FeedbackCreate,
    current_user: DBUser = Depends(get_current_user)
):
    """Submit user feedback"""
    
    # Validate feedback type
    valid_types = ["general", "bug", "feature", "help"]
    if feedback.feedback_type not in valid_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid feedback type. Must be one of: {', '.join(valid_types)}"
        )
    
    # Create feedback entry
    user_feedback = UserFeedback(
        user_id=current_user,
        feedback_type=feedback.feedback_type,
        subject=feedback.subject,
        message=feedback.message,
        device_info=feedback.device_info,
        app_version=feedback.app_version,
        status="pending"
    )
    
    await user_feedback.insert()
    
    # Send notification to support team (implement email/slack notification)
    # await send_feedback_notification(user_feedback)
    
    return {
        "message": "Feedback submitted successfully",
        "feedback_id": str(user_feedback.id),
        "status": "pending"
    }


@router.get("/my-feedback", response_model=List[FeedbackResponse])
async def get_my_feedback(
    current_user: DBUser = Depends(get_current_user)
):
    """Get user's submitted feedback"""
    
    feedback_list = await UserFeedback.find(
        UserFeedback.user_id == current_user.id
    ).sort("-created_at").to_list()
    
    return [
        FeedbackResponse(
            id=str(f.id),
            feedback_type=f.feedback_type,
            subject=f.subject,
            message=f.message,
            status=f.status,
            created_at=f.created_at
        )
        for f in feedback_list
    ]


@router.post("/share-reward", response_model=dict)
async def track_share_and_reward(
    share_data: ShareRewardRequest,
    current_user: DBUser = Depends(get_current_user)
):
    """Track share event and reward user with credit"""
    
    # Check if user already received reward today (prevent abuse)
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    recent_shares = await ShareEvent.find(
        ShareEvent.user_id == current_user.id,
        ShareEvent.created_at >= today_start,
        ShareEvent.verified == True
    ).count()
    
    if recent_shares >= 3:  # Max 3 share rewards per day
        return {
            "message": "Daily share limit reached",
            "credits_earned": 0,
            "limit_reached": True
        }
    
    # Create share event
    share_event = ShareEvent(
        user_id=current_user,
        share_type=share_data.share_type,
        platform=share_data.platform,
        reward_credits=1,
        verified=True  # Auto-verify for now, implement actual verification later
    )
    
    await share_event.insert()
    
    # Reward user with credit
    if share_event.verified:
        credit_transaction = CreditTransaction(
            user_id=current_user,
            credits=1,
            transaction_type="reward",
            description=f"Earned from sharing on {share_data.platform or 'app'}"
        )
        await credit_transaction.insert()
        
        # Update user stats
        stats = await UserStats.find_one(UserStats.user_id == current_user.id)
        if stats:
            stats.total_shares += 1
            stats.credits_earned_from_shares += 1
            stats.updated_at = datetime.utcnow()
            await stats.save()
        else:
            # Create stats if doesn't exist
            stats = UserStats(
                user_id=current_user,
                total_shares=1,
                credits_earned_from_shares=1
            )
            await stats.insert()
    
    return {
        "message": "Thank you for sharing! You've earned 1 free credit 🎉",
        "credits_earned": 1,
        "total_credits_from_shares": (stats.credits_earned_from_shares if stats else 1)
    }


@router.get("/stats", response_model=UserStatsResponse)
async def get_user_stats(
    current_user: DBUser = Depends(get_current_user)
):
    """Get user's statistics"""
    
    stats = await UserStats.find_one(UserStats.user_id == current_user.id)
    
    if not stats:
        # Create default stats
        stats = UserStats(
            user_id=current_user,
            total_images_processed=0,
            total_restores=0,
            total_merges=0,
            total_shares=0,
            credits_earned_from_shares=0
        )
        await stats.insert()
    
    return UserStatsResponse(
        total_images_processed=stats.total_images_processed,
        total_restores=stats.total_restores,
        total_merges=stats.total_merges,
        total_shares=stats.total_shares,
        credits_earned_from_shares=stats.credits_earned_from_shares,
        favorite_filter=stats.favorite_filter,
        member_since=current_user.created_at
    )


@router.post("/rate-app", response_model=dict)
async def track_app_rating(
    rating: int,
    current_user: DBUser = Depends(get_current_user)
):
    """Track app rating (called after user rates on App Store)"""
    
    if rating < 1 or rating > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    # Could reward user for rating
    if rating >= 4:
        # Optional: Give bonus credit for positive rating
        pass
    
    return {
        "message": "Thank you for your rating!",
        "rating": rating
    }


@router.get("/faq", response_model=List[dict])
async def get_faq():
    """Get frequently asked questions"""
    
    return [
        {
            "question": "How does photo restoration work?",
            "answer": "We use advanced AI to analyze and enhance old photos, fixing scratches, improving colors, and sharpening details.",
            "category": "features"
        },
        {
            "question": "Are my photos stored on your servers?",
            "answer": "Photos are temporarily stored during processing and automatically deleted after 24 hours. Your originals always remain on your device.",
            "category": "privacy"
        },
        {
            "question": "How do credits work?",
            "answer": "Each credit processes one photo. Credits never expire and can be used for any restoration or merge.",
            "category": "credits"
        },
        {
            "question": "Can I cancel my subscription?",
            "answer": "Yes, you can cancel anytime from your device settings. You'll retain access until the end of your billing period.",
            "category": "subscription"
        },
        {
            "question": "What formats are supported?",
            "answer": "We support JPG, PNG, and HEIC formats. For best results, use the highest quality images available.",
            "category": "technical"
        },
        {
            "question": "How long does processing take?",
            "answer": "Most photos process in 10-30 seconds. Premium subscribers get priority processing for faster results.",
            "category": "technical"
        },
        {
            "question": "Can I download my processed photos?",
            "answer": "Yes! All processed photos can be saved directly to your device's photo library.",
            "category": "features"
        },
        {
            "question": "Is there a free trial?",
            "answer": "Yes! Monthly and yearly subscriptions include a free trial period. You won't be charged until the trial ends.",
            "category": "subscription"
        }
    ]

