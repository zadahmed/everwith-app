"""
EverWith Subscription API Endpoints
Comprehensive subscription and monetization management with RevenueCat integration
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import logging
from app.models.database import User as DBUser, Subscription, CreditTransaction, UsageLog, Transaction
from app.core.security import get_current_user
from enum import Enum

# Configure logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/subscriptions", tags=["subscriptions"])

# Enums
class SubscriptionTier(str, Enum):
    FREE = "free"
    PREMIUM_MONTHLY = "premium_monthly"
    PREMIUM_YEARLY = "premium_yearly"

class SubscriptionStatus(str, Enum):
    ACTIVE = "active"
    CANCELLED = "cancelled"
    EXPIRED = "expired"
    TRIAL = "trial"

# Pydantic models for RevenueCat integration
class AccessCheckRequest(BaseModel):
    user_id: str
    mode: str

class AccessCheckResponse(BaseModel):
    has_access: bool
    remaining_credits: int
    free_uses_remaining: int
    subscription_tier: str
    message: Optional[str] = None

class CreditUsageRequest(BaseModel):
    user_id: str
    mode: str
    transaction_id: Optional[str] = None

class CreditUsageResponse(BaseModel):
    success: bool
    remaining_credits: int
    free_uses_remaining: int
    message: Optional[str] = None

class PurchaseNotificationRequest(BaseModel):
    user_id: str
    product_id: str
    transaction_id: str
    purchase_type: str
    revenue_cat_data: Dict[str, Any]

class CreditsResponse(BaseModel):
    credits: int

# Pydantic models for subscription management
class SubscriptionCreate(BaseModel):
    tier: SubscriptionTier
    receipt_data: str  # Apple/Google receipt
    transaction_id: str

class SubscriptionResponse(BaseModel):
    id: str
    user_id: str
    tier: str
    status: str
    start_date: datetime
    end_date: Optional[datetime]
    is_active: bool
    trial_end_date: Optional[datetime]
    auto_renew: bool

class CreditPurchase(BaseModel):
    credits: int
    price: float
    currency: str = "GBP"
    receipt_data: str
    transaction_id: str

class UserCreditsResponse(BaseModel):
    credits_remaining: int
    total_purchased: int
    total_used: int
    last_purchase_date: Optional[datetime]

# Helper functions
def reset_daily_free_uses_if_needed(user: DBUser) -> bool:
    """Reset free uses if it's a new day. Returns True if reset occurred."""
    if user.last_free_use_date is None:
        user.free_uses_remaining = 1
        return True
    
    if user.last_free_use_date.date() < datetime.utcnow().date():
        user.free_uses_remaining = 1
        user.last_free_use_date = None
        return True
    
    return False

def can_use_feature(user: DBUser) -> bool:
    """Check if user can use a feature based on their subscription status."""
    if user.subscription_tier in ["premium_monthly", "premium_yearly"]:
        return True
    
    if user.subscription_tier == "free":
        reset_daily_free_uses_if_needed(user)
        return user.free_uses_remaining > 0
    
    return False

# API Endpoints

@router.post("/check-access", response_model=AccessCheckResponse)
async def check_access(request: AccessCheckRequest, current_user: DBUser = Depends(get_current_user)):
    """Check if user has access to a feature."""
    try:
        # Reset daily free uses if needed
        reset_daily_free_uses_if_needed(current_user)
        await current_user.save()
        
        has_access = can_use_feature(current_user)
        
        return AccessCheckResponse(
            has_access=has_access,
            remaining_credits=current_user.credits,
            free_uses_remaining=current_user.free_uses_remaining,
            subscription_tier=current_user.subscription_tier,
            message="Access granted" if has_access else "No access remaining"
        )
    
    except Exception as e:
        logger.error(f"Error checking access: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/use-credit", response_model=CreditUsageResponse)
async def use_credit(request: CreditUsageRequest, current_user: DBUser = Depends(get_current_user)):
    """Use a credit or free use for processing."""
    try:
        # Reset daily free uses if needed
        reset_daily_free_uses_if_needed(current_user)
        
        success = False
        used_credit = False
        used_free_use = False
        
        if current_user.subscription_tier in ["premium_monthly", "premium_yearly"]:
            # Premium users have unlimited access
            success = True
        elif current_user.credits > 0:
            # Use a credit
            current_user.credits -= 1
            success = True
            used_credit = True
        elif current_user.free_uses_remaining > 0:
            # Use free use
            current_user.free_uses_remaining -= 1
            current_user.last_free_use_date = datetime.utcnow()
            success = True
            used_free_use = True
        
        if success:
            # Log the usage
            usage_log = UsageLog(
                user_id=current_user,
                mode=request.mode,
                used_credit=used_credit,
                used_free_use=used_free_use
            )
            await usage_log.insert()
        
        await current_user.save()
        
        return CreditUsageResponse(
            success=success,
            remaining_credits=current_user.credits,
            free_uses_remaining=current_user.free_uses_remaining,
            message="Credit used successfully" if success else "No credits or free uses remaining"
        )
    
    except Exception as e:
        logger.error(f"Error using credit: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/purchase-notification")
async def purchase_notification(
    request: PurchaseNotificationRequest, 
    current_user: DBUser = Depends(get_current_user)
):
    """Handle purchase notifications from RevenueCat."""
    try:
        # Log the transaction
        transaction = Transaction(
            user_id=current_user,
            product_id=request.product_id,
            transaction_id=request.transaction_id,
            purchase_type=request.purchase_type,
            revenue_cat_data=str(request.revenue_cat_data)
        )
        await transaction.insert()
        
        # Update user based on purchase type
        if request.purchase_type == "subscription":
            if "premium_monthly" in request.product_id:
                current_user.subscription_tier = "premium_monthly"
                # Set expiration date (30 days from now)
                current_user.subscription_expires_at = datetime.utcnow() + timedelta(days=30)
            elif "premium_yearly" in request.product_id:
                current_user.subscription_tier = "premium_yearly"
                # Set expiration date (365 days from now)
                current_user.subscription_expires_at = datetime.utcnow() + timedelta(days=365)
        
        elif request.purchase_type == "credit_pack":
            # Add credits based on product ID
            credit_amounts = {
                "credits_5": 5,
                "credits_10": 10,
                "credits_25": 25,
                "credits_50": 50
            }
            credits_to_add = credit_amounts.get(request.product_id, 0)
            current_user.credits += credits_to_add
            
            # Log credit transaction
            credit_transaction = CreditTransaction(
                user_id=current_user,
                credits=credits_to_add,
                transaction_type="purchase",
                transaction_id=request.transaction_id,
                receipt_data=str(request.revenue_cat_data)
            )
            await credit_transaction.insert()
        
        await current_user.save()
        
        logger.info(f"Purchase processed for user {request.user_id}: {request.product_id}")
        
        return {"status": "success", "message": "Purchase processed"}
    
    except Exception as e:
        logger.error(f"Error processing purchase: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/credits/{user_id}", response_model=CreditsResponse)
async def get_user_credits(user_id: str, current_user: DBUser = Depends(get_current_user)):
    """Get user's current credit balance."""
    try:
        return CreditsResponse(credits=current_user.credits)
    
    except Exception as e:
        logger.error(f"Error getting credits: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/user/{user_id}")
async def get_user_status(user_id: str, current_user: DBUser = Depends(get_current_user)):
    """Get comprehensive user subscription status."""
    try:
        # Reset daily free uses if needed
        reset_daily_free_uses_if_needed(current_user)
        await current_user.save()
        
        return {
            "user_id": str(current_user.id),
            "subscription_tier": current_user.subscription_tier,
            "subscription_expires_at": current_user.subscription_expires_at,
            "credits": current_user.credits,
            "free_uses_remaining": current_user.free_uses_remaining,
            "last_free_use_date": current_user.last_free_use_date,
            "can_use_feature": can_use_feature(current_user)
        }
    
    except Exception as e:
        logger.error(f"Error getting user status: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/reset-daily-uses/{user_id}")
async def reset_daily_uses(user_id: str, current_user: DBUser = Depends(get_current_user)):
    """Manually reset daily free uses (for testing)."""
    try:
        current_user.free_uses_remaining = 1
        current_user.last_free_use_date = None
        await current_user.save()
        
        return {"status": "success", "message": "Daily uses reset"}
    
    except Exception as e:
        logger.error(f"Error resetting daily uses: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

# MARK: - Subscription Management Endpoints

@router.get("/status", response_model=SubscriptionResponse)
async def get_subscription_status(
    current_user: DBUser = Depends(get_current_user)
):
    """Get current user's subscription status"""
    subscription = await Subscription.find_one(
        Subscription.user_id == current_user,
        Subscription.status == SubscriptionStatus.ACTIVE
    )
    
    if not subscription:
        # Return free tier status
        return SubscriptionResponse(
            id="free",
            user_id=str(current_user.id),
            tier=SubscriptionTier.FREE,
            status=SubscriptionStatus.ACTIVE,
            start_date=current_user.created_at,
            end_date=None,
            is_active=True,
            trial_end_date=None,
            auto_renew=False
        )
    
    return SubscriptionResponse(
        id=str(subscription.id),
        user_id=str(subscription.user_id.ref.id),
        tier=subscription.tier,
        status=subscription.status,
        start_date=subscription.start_date,
        end_date=subscription.end_date,
        is_active=subscription.is_active(),
        trial_end_date=subscription.trial_end_date,
        auto_renew=subscription.auto_renew
    )

@router.post("/subscribe", response_model=dict)
async def create_subscription(
    subscription_data: SubscriptionCreate,
    current_user: DBUser = Depends(get_current_user)
):
    """Create or update subscription (after successful payment)"""
    
    # Verify receipt with Apple/Google (implement actual verification)
    # For now, we'll simulate successful verification
    
    # Calculate dates based on tier
    start_date = datetime.utcnow()
    trial_end_date = None
    
    if subscription_data.tier == SubscriptionTier.PREMIUM_MONTHLY:
        end_date = start_date + timedelta(days=30)
        trial_end_date = start_date + timedelta(days=7)  # 7-day trial
    elif subscription_data.tier == SubscriptionTier.PREMIUM_YEARLY:
        end_date = start_date + timedelta(days=365)
        trial_end_date = start_date + timedelta(days=7)  # 7-day trial
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid subscription tier"
        )
    
    # Cancel any existing active subscriptions
    existing = await Subscription.find(
        Subscription.user_id == current_user,
        Subscription.status == SubscriptionStatus.ACTIVE
    ).to_list()
    
    for sub in existing:
        sub.status = SubscriptionStatus.CANCELLED
        await sub.save()
    
    # Create new subscription
    subscription = Subscription(
        user_id=current_user,
        tier=subscription_data.tier,
        status=SubscriptionStatus.TRIAL if trial_end_date else SubscriptionStatus.ACTIVE,
        start_date=start_date,
        end_date=end_date,
        trial_end_date=trial_end_date,
        transaction_id=subscription_data.transaction_id,
        receipt_data=subscription_data.receipt_data,
        auto_renew=True
    )
    
    await subscription.insert()
    
    return {
        "message": "Subscription created successfully",
        "subscription_id": str(subscription.id),
        "tier": subscription.tier,
        "status": subscription.status,
        "trial_days": 7 if trial_end_date else 0
    }

@router.post("/cancel", response_model=dict)
async def cancel_subscription(
    current_user: DBUser = Depends(get_current_user)
):
    """Cancel user's subscription (will expire at end of period)"""
    
    subscription = await Subscription.find_one(
        Subscription.user_id == current_user,
        Subscription.status.in_([SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL])
    )
    
    if not subscription:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active subscription found"
        )
    
    subscription.auto_renew = False
    subscription.cancelled_at = datetime.utcnow()
    await subscription.save()
    
    return {
        "message": "Subscription will be cancelled at end of period",
        "end_date": subscription.end_date
    }

@router.post("/restore", response_model=dict)
async def restore_purchases(
    receipt_data: str,
    current_user: DBUser = Depends(get_current_user)
):
    """Restore purchases from receipt"""
    
    # Verify receipt with Apple/Google
    # Restore any valid subscriptions
    
    return {
        "message": "Purchases restored successfully",
        "restored_subscriptions": [],
        "restored_credits": 0
    }

# MARK: - Credit Management Endpoints

@router.get("/credits", response_model=UserCreditsResponse)
async def get_user_credits(
    current_user: DBUser = Depends(get_current_user)
):
    """Get user's credit balance and history"""
    
    # Calculate credits
    purchases = await CreditTransaction.find(
        CreditTransaction.user_id == current_user,
        CreditTransaction.transaction_type == "purchase"
    ).to_list()
    
    usage = await CreditTransaction.find(
        CreditTransaction.user_id == current_user,
        CreditTransaction.transaction_type == "usage"
    ).to_list()
    
    total_purchased = sum(t.credits for t in purchases)
    total_used = sum(abs(t.credits) for t in usage)
    
    last_purchase = max(
        (t.created_at for t in purchases),
        default=None
    )
    
    return UserCreditsResponse(
        credits_remaining=total_purchased - total_used,
        total_purchased=total_purchased,
        total_used=total_used,
        last_purchase_date=last_purchase
    )

@router.post("/credits/purchase", response_model=dict)
async def purchase_credits(
    purchase: CreditPurchase,
    current_user: DBUser = Depends(get_current_user)
):
    """Purchase credits"""
    
    # Verify receipt with payment provider
    
    # Create credit transaction
    transaction = CreditTransaction(
        user_id=current_user,
        credits=purchase.credits,
        transaction_type="purchase",
        amount=purchase.price,
        currency=purchase.currency,
        transaction_id=purchase.transaction_id,
        receipt_data=purchase.receipt_data
    )
    
    await transaction.insert()
    
    # Get updated balance
    credits_response = await get_user_credits(current_user)
    
    return {
        "message": "Credits purchased successfully",
        "credits_added": purchase.credits,
        "credits_remaining": credits_response.credits_remaining,
        "transaction_id": str(transaction.id)
    }

@router.post("/credits/use", response_model=dict)
async def use_credit(
    image_type: str,
    current_user: DBUser = Depends(get_current_user)
):
    """Use a credit for processing"""
    
    # Check if user has subscription
    subscription = await Subscription.find_one(
        Subscription.user_id == current_user,
        Subscription.status == SubscriptionStatus.ACTIVE
    )
    
    if subscription and subscription.is_active():
        return {
            "message": "Processing with subscription",
            "credits_used": 0,
            "subscription_active": True
        }
    
    # Check credit balance
    credits_response = await get_user_credits(current_user)
    
    if credits_response.credits_remaining <= 0:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Insufficient credits. Please purchase more credits or upgrade to premium."
        )
    
    # Deduct credit
    transaction = CreditTransaction(
        user_id=current_user,
        credits=-1,
        transaction_type="usage",
        description=f"Used for {image_type} processing"
    )
    
    await transaction.insert()
    
    return {
        "message": "Credit used successfully",
        "credits_used": 1,
        "credits_remaining": credits_response.credits_remaining - 1,
        "subscription_active": False
    }

@router.get("/pricing", response_model=dict)
async def get_pricing():
    """Get current pricing information"""
    
    return {
        "subscriptions": {
            "premium_monthly": {
                "price": 9.99,
                "currency": "GBP",
                "trial_days": 7,
                "features": [
                    "Unlimited restores & merges",
                    "4K HD exports",
                    "Instant results",
                    "No watermark",
                    "All filters unlocked"
                ]
            },
            "premium_yearly": {
                "price": 69.99,
                "currency": "GBP",
                "trial_days": 7,
                "savings": "40%",
                "price_per_month": 5.83,
                "features": [
                    "Everything in Monthly",
                    "Best value",
                    "Save £50 per year",
                    "40% discount"
                ]
            }
        },
        "credits": {
            "packages": [
                {"credits": 5, "price": 4.99, "currency": "GBP"},
                {"credits": 15, "price": 9.99, "currency": "GBP", "badge": "POPULAR"},
                {"credits": 50, "price": 24.99, "currency": "GBP", "badge": "BEST VALUE"}
            ],
            "note": "Credits never expire"
        }
    }

# Health check endpoint
@router.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow()}