"""
Usage Validation Middleware for All Users
Implements fair-use quota system with soft limits and gentle messaging.
Applies to all users regardless of subscription tier.
"""

from fastapi import HTTPException, Depends
from typing import Optional, Dict
from datetime import datetime
from app.models.database import User, PremiumUsageTracking
from app.core.security import get_current_user
import logging

logger = logging.getLogger(__name__)

# Fair-use quota configuration
SOFT_LIMIT = 100  # Soft limit: gentle message starts here
COOLDOWN_LIMIT = 150  # Cooldown: processing may slow after this
GENTLE_MESSAGE = "You've created many memories this month — processing may slow slightly."

# Processing speed multipliers (for frontend display)
NORMAL_PROCESSING_SPEED = 1.0  # Normal speed
SLOWED_PROCESSING_SPEED = 1.5  # 50% slower when in cooldown


def get_current_month() -> str:
    """Get current month in YYYY-MM format"""
    now = datetime.utcnow()
    return f"{now.year}-{now.month:02d}"


async def get_or_create_usage_tracking(user: User, month: str) -> PremiumUsageTracking:
    """Get or create usage tracking record for user and month"""
    tracking = await PremiumUsageTracking.find_one(
        PremiumUsageTracking.user_id == user.id,
        PremiumUsageTracking.month == month
    )
    
    if not tracking:
        tracking = PremiumUsageTracking(
            user_id=user,
            month=month,
            usage_count=0
        )
        await tracking.insert()
    
    return tracking


async def increment_usage(user: User) -> PremiumUsageTracking:
    """Increment usage count for current month and return tracking record"""
    month = get_current_month()
    tracking = await get_or_create_usage_tracking(user, month)
    
    tracking.usage_count += 1
    tracking.updated_at = datetime.utcnow()
    await tracking.save()
    
    logger.info(f"User {user.email} usage incremented: {tracking.usage_count}/{COOLDOWN_LIMIT} for {month}")
    
    return tracking


async def validate_usage(
    current_user: User = Depends(get_current_user)
) -> Dict[str, any]:
    """
    Middleware to validate user usage and return status.
    Applies to ALL users regardless of subscription tier.
    
    Returns:
        Dict with:
        - allowed: bool - Whether processing should proceed
        - message: Optional[str] - Gentle message if approaching/at limits
        - usage_count: int - Current usage for the month
        - soft_limit: int - Soft limit threshold
        - cooldown_limit: int - Cooldown threshold
        - in_cooldown: bool - Whether user is in cooldown (processing may slow)
    """
    # Track usage for ALL users
    month = get_current_month()
    tracking = await get_or_create_usage_tracking(current_user, month)
    
    usage_count = tracking.usage_count
    in_cooldown = usage_count >= COOLDOWN_LIMIT
    at_soft_limit = usage_count >= SOFT_LIMIT
    approaching_limit = usage_count >= (SOFT_LIMIT * 0.8)  # 80% of soft limit
    
    # Always allow processing (soft limit, not hard block)
    # But provide gentle messaging and processing speed info
    message = None
    processing_speed_multiplier = NORMAL_PROCESSING_SPEED
    estimated_wait_seconds = None
    
    if in_cooldown:
        message = GENTLE_MESSAGE
        processing_speed_multiplier = SLOWED_PROCESSING_SPEED
        # Estimate: if in cooldown, processing may take 50% longer
        estimated_wait_seconds = 30  # Base estimate, frontend can adjust based on operation
    elif at_soft_limit:
        message = GENTLE_MESSAGE
        processing_speed_multiplier = 1.2  # Slightly slower
    elif approaching_limit:
        # Warning before hitting soft limit
        remaining = SOFT_LIMIT - usage_count
        message = f"You're approaching your monthly limit ({remaining} images remaining). Processing may slow after {SOFT_LIMIT} images."
    
    return {
        "allowed": True,  # Never block, just inform
        "message": message,
        "usage_count": usage_count,
        "soft_limit": SOFT_LIMIT,
        "cooldown_limit": COOLDOWN_LIMIT,
        "in_cooldown": in_cooldown,
        "at_soft_limit": at_soft_limit,
        "approaching_limit": approaching_limit,
        "processing_speed_multiplier": processing_speed_multiplier,
        "estimated_wait_seconds": estimated_wait_seconds,
        "remaining_until_soft_limit": max(0, SOFT_LIMIT - usage_count),
        "remaining_until_cooldown": max(0, COOLDOWN_LIMIT - usage_count)
    }


async def get_usage_status(
    current_user: User = Depends(get_current_user)
) -> Dict[str, any]:
    """
    Get current usage status without incrementing.
    Useful for checking status before processing.
    Applies to ALL users regardless of subscription tier.
    """
    month = get_current_month()
    tracking = await get_or_create_usage_tracking(current_user, month)
    
    usage_count = tracking.usage_count
    in_cooldown = usage_count >= COOLDOWN_LIMIT
    at_soft_limit = usage_count >= SOFT_LIMIT
    approaching_limit = usage_count >= (SOFT_LIMIT * 0.8)  # 80% of soft limit
    
    message = None
    processing_speed_multiplier = NORMAL_PROCESSING_SPEED
    estimated_wait_seconds = None
    
    if in_cooldown:
        message = GENTLE_MESSAGE
        processing_speed_multiplier = SLOWED_PROCESSING_SPEED
        estimated_wait_seconds = 30
    elif at_soft_limit:
        message = GENTLE_MESSAGE
        processing_speed_multiplier = 1.2
    elif approaching_limit:
        remaining = SOFT_LIMIT - usage_count
        message = f"You're approaching your monthly limit ({remaining} images remaining). Processing may slow after {SOFT_LIMIT} images."
    
    return {
        "usage_count": usage_count,
        "soft_limit": SOFT_LIMIT,
        "cooldown_limit": COOLDOWN_LIMIT,
        "in_cooldown": in_cooldown,
        "at_soft_limit": at_soft_limit,
        "approaching_limit": approaching_limit,
        "message": message,
        "processing_speed_multiplier": processing_speed_multiplier,
        "estimated_wait_seconds": estimated_wait_seconds,
        "remaining_until_soft_limit": max(0, SOFT_LIMIT - usage_count),
        "remaining_until_cooldown": max(0, COOLDOWN_LIMIT - usage_count)
    }

