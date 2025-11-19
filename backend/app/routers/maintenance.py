"""
Maintenance and Cron Job Endpoints
For scheduled tasks like monthly usage resets
"""

from fastapi import APIRouter, HTTPException, Header
from typing import Optional
from datetime import datetime
from app.models.database import PremiumUsageTracking
import os
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/maintenance", tags=["maintenance"])

# Secret key for cron job authentication (set in environment)
CRON_SECRET = os.getenv("CRON_SECRET", "change-me-in-production")


@router.post("/reset-monthly-usage")
async def reset_monthly_usage(
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret")
):
    """
    Reset monthly usage tracking for all users.
    
    This endpoint should be called monthly (e.g., on the 1st of each month)
    via a cron job or scheduler (Heroku Scheduler, etc.).
    
    It cleans up old usage tracking records and prepares for the new month.
    
    Security: Requires X-Cron-Secret header matching CRON_SECRET env variable.
    """
    # Verify secret
    if not x_cron_secret or x_cron_secret != CRON_SECRET:
        logger.warning("Unauthorized cron job attempt - invalid secret")
        raise HTTPException(
            status_code=401,
            detail="Unauthorized: Invalid cron secret"
        )
    
    try:
        current_month = f"{datetime.utcnow().year}-{datetime.utcnow().month:02d}"
        previous_month = None
        
        # Calculate previous month
        if datetime.utcnow().month == 1:
            previous_month = f"{datetime.utcnow().year - 1}-12"
        else:
            previous_month = f"{datetime.utcnow().year}-{datetime.utcnow().month - 1:02d}"
        
        # Count records from previous month
        old_records = await PremiumUsageTracking.find(
            PremiumUsageTracking.month == previous_month
        ).to_list()
        
        old_count = len(old_records)
        
        # Delete old records (optional - you may want to keep them for analytics)
        # For now, we'll keep them but you can uncomment to delete:
        # for record in old_records:
        #     await record.delete()
        
        logger.info(f"Monthly usage reset check completed. Found {old_count} records from {previous_month}")
        logger.info(f"Current month: {current_month} - New records will be created automatically as needed")
        
        return {
            "status": "success",
            "message": "Monthly usage reset check completed",
            "previous_month": previous_month,
            "current_month": current_month,
            "old_records_found": old_count,
            "note": "Records are kept for analytics. New month tracking starts automatically."
        }
    
    except Exception as e:
        logger.error(f"Error in monthly usage reset: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to reset monthly usage: {str(e)}"
        )


@router.get("/usage-stats")
async def get_usage_stats(
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret")
):
    """
    Get usage statistics for monitoring.
    Requires cron secret for security.
    """
    if not x_cron_secret or x_cron_secret != CRON_SECRET:
        raise HTTPException(
            status_code=401,
            detail="Unauthorized: Invalid cron secret"
        )
    
    try:
        current_month = f"{datetime.utcnow().year}-{datetime.utcnow().month:02d}"
        
        # Get all records for current month
        current_records = await PremiumUsageTracking.find(
            PremiumUsageTracking.month == current_month
        ).to_list()
        
        # Calculate statistics
        total_users = len(current_records)
        total_usage = sum(r.usage_count for r in current_records)
        users_over_soft_limit = sum(1 for r in current_records if r.usage_count >= 100)
        users_over_cooldown = sum(1 for r in current_records if r.usage_count >= 150)
        max_usage = max((r.usage_count for r in current_records), default=0)
        avg_usage = total_usage / total_users if total_users > 0 else 0
        
        return {
            "current_month": current_month,
            "total_users_tracked": total_users,
            "total_usage": total_usage,
            "average_usage": round(avg_usage, 2),
            "max_usage": max_usage,
            "users_over_soft_limit": users_over_soft_limit,
            "users_over_cooldown": users_over_cooldown
        }
    
    except Exception as e:
        logger.error(f"Error getting usage stats: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get usage stats: {str(e)}"
        )

