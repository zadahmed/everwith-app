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
from app.core.credit_config import (
    ServiceType, get_credit_cost, get_all_costs, 
    FREE_MONTHLY_CREDITS, INITIAL_SIGNUP_CREDITS,
    PREMIUM_CREDITS_ON_UPGRADE, PREMIUM_YEARLY_BONUS,
    PREMIUM_SOFT_LIMIT
)
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
def reset_free_user_monthly_credits(user: DBUser) -> bool:
    """Reset free user's monthly credits if it's a new month. Returns True if reset occurred."""
    if user.subscription_tier != "free":
        return False
    
    now = datetime.utcnow()
    
    # If never reset before, do initial setup
    if user.monthly_credits_reset_date is None:
        user.monthly_credits_reset_date = now
        user.credits = FREE_MONTHLY_CREDITS
        return True
    
    # Check if a new month has started
    if user.monthly_credits_reset_date.month != now.month or user.monthly_credits_reset_date.year != now.year:
        user.monthly_credits_reset_date = now
        user.credits = FREE_MONTHLY_CREDITS  # Reset to monthly allocation
        return True
    
    return False

def reset_premium_usage_tracking(user: DBUser) -> bool:
    """Reset premium usage counter if it's a new month. Returns True if reset occurred."""
    if user.subscription_tier not in ["premium_monthly", "premium_yearly"]:
        return False
    
    now = datetime.utcnow()
    
    # Initialize if never tracked
    if user.premium_usage_reset_date is None:
        user.premium_usage_this_month = 0
        user.premium_usage_reset_date = now
        return True
    
    # Check if a new month has started
    if user.premium_usage_reset_date.month != now.month or user.premium_usage_reset_date.year != now.year:
        user.premium_usage_this_month = 0
        user.premium_usage_reset_date = now
        return True
    
    return False

def can_use_feature(user: DBUser, credits_needed: int = 1) -> bool:
    """Check if user can use a feature based on their subscription status.
    
    Credit-driven system:
    - Premium users: Unlimited access (with internal soft limit monitoring)
    - Free users: Requires credits
    """
    if user.subscription_tier in ["premium_monthly", "premium_yearly"]:
        # Check if premium user has hit soft limit
        reset_premium_usage_tracking(user)
        if user.premium_usage_this_month >= PREMIUM_SOFT_LIMIT:
            logger.warning(f"Premium user {user.email} has hit soft limit: {user.premium_usage_this_month}/{PREMIUM_SOFT_LIMIT}")
            return False  # Block access to protect costs
        return True  # Premium users have access within soft limit
    
    # Free users must have credits
    reset_free_user_monthly_credits(user)  # Check monthly reset
    return user.credits >= credits_needed

# API Endpoints

@router.post("/check-access", response_model=AccessCheckResponse)
async def check_access(request: AccessCheckRequest, current_user: DBUser = Depends(get_current_user)):
    """Check if user has access to a feature (credit-driven system with service-specific costs)."""
    try:
        # Determine service type based on mode
        service_type_map = {
            "restore": ServiceType.PHOTO_RESTORE,
            "together": ServiceType.MEMORY_MERGE,
            "cinematic": ServiceType.CINEMATIC_FILTER,
        }
        
        service_type = service_type_map.get(request.mode, ServiceType.PHOTO_RESTORE)
        credits_needed = get_credit_cost(service_type)
        
        has_access = can_use_feature(current_user, credits_needed)
        
        # Build message based on user type
        if current_user.subscription_tier in ["premium_monthly", "premium_yearly"]:
            reset_premium_usage_tracking(current_user)
            remaining_uses = PREMIUM_SOFT_LIMIT - current_user.premium_usage_this_month
            message = f"Access granted. {remaining_uses}/{PREMIUM_SOFT_LIMIT} uses remaining this month" if has_access else f"Monthly limit reached ({PREMIUM_SOFT_LIMIT} uses)"
        elif has_access:
            message = f"Access granted ({credits_needed} credit(s) required)"
        else:
            message = f"Insufficient credits. Need {credits_needed}, have {current_user.credits} credits"
        
        return AccessCheckResponse(
            has_access=has_access,
            remaining_credits=current_user.credits,
            free_uses_remaining=0,  # No free uses in credit-driven system
            subscription_tier=current_user.subscription_tier,
            message=message
        )
    
    except Exception as e:
        logger.error(f"Error checking access: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/use-credit", response_model=CreditUsageResponse)
async def use_credit(request: CreditUsageRequest, current_user: DBUser = Depends(get_current_user)):
    """Use credits for processing (credit-driven system with service-specific costs)."""
    try:
        # Determine service type based on mode
        service_type_map = {
            "restore": ServiceType.PHOTO_RESTORE,
            "together": ServiceType.MEMORY_MERGE,
            "cinematic": ServiceType.CINEMATIC_FILTER,
        }
        
        service_type = service_type_map.get(request.mode, ServiceType.PHOTO_RESTORE)
        credits_needed = get_credit_cost(service_type)
        
        success = False
        used_credit = False
        credits_used = 0
        is_premium = current_user.subscription_tier in ["premium_monthly", "premium_yearly"]
        
        if is_premium:
            # Premium users have unlimited access (within soft limit)
            # Track usage for cost control
            reset_premium_usage_tracking(current_user)
            
            if current_user.premium_usage_this_month >= PREMIUM_SOFT_LIMIT:
                raise HTTPException(
                    status_code=429,
                    detail=f"Monthly usage limit reached. You've used {current_user.premium_usage_this_month}/{PREMIUM_SOFT_LIMIT} this month."
                )
            
            current_user.premium_usage_this_month += 1
            success = True
            used_credit = False  # Premium users don't use credits
        elif current_user.credits >= credits_needed:
            # Free users: Deduct the required credits
            current_user.credits -= credits_needed
            success = True
            used_credit = True
            credits_used = credits_needed
        else:
            # Not enough credits
            raise HTTPException(
                status_code=402,
                detail=f"Insufficient credits. Need {credits_needed}, have {current_user.credits}"
            )
        
        if success:
            # Log the usage
            usage_log = UsageLog(
                user_id=current_user,
                mode=request.mode,
                used_credit=used_credit,
                used_free_use=False  # No free uses in credit-driven system
            )
            await usage_log.insert()
            
            # Log credit transaction if credit was used
            if used_credit and credits_used > 0:
                import uuid
                credit_transaction = CreditTransaction(
                    user_id=current_user,
                    credits=-credits_used,
                    transaction_type="usage",
                    description=f"Used for {request.mode} processing",
                    transaction_id=request.transaction_id if hasattr(request, 'transaction_id') else str(uuid.uuid4())
                )
                await credit_transaction.insert()
        
        await current_user.save()
        
        message = ""
        if is_premium:
            message = f"Processing started (Premium - Unlimited access)"
        elif used_credit:
            message = f"Processing started using {credits_needed} credit(s)"
        else:
            message = "No credits remaining"
        
        return CreditUsageResponse(
            success=success,
            remaining_credits=current_user.credits,
            free_uses_remaining=0,  # No free uses in credit-driven system
            message=message
        )
    
    except HTTPException:
        raise
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
            was_free_user = current_user.subscription_tier == "free"
            
            if "premium_monthly" in request.product_id:
                current_user.subscription_tier = "premium_monthly"
                # Set expiration date (30 days from now)
                current_user.subscription_expires_at = datetime.utcnow() + timedelta(days=30)
                # Initialize premium usage tracking
                current_user.premium_usage_this_month = 0
                current_user.premium_usage_reset_date = datetime.utcnow()
                
                # Give upgrade bonus if converting from free
                if was_free_user:
                    current_user.credits += PREMIUM_CREDITS_ON_UPGRADE
                    credit_transaction = CreditTransaction(
                        user_id=current_user,
                        credits=PREMIUM_CREDITS_ON_UPGRADE,
                        transaction_type="reward",
                        description="Premium Monthly Upgrade - Welcome bonus",
                        transaction_id=request.transaction_id
                    )
                    await credit_transaction.insert()
                
            elif "premium_yearly" in request.product_id:
                current_user.subscription_tier = "premium_yearly"
                # Set expiration date (365 days from now)
                current_user.subscription_expires_at = datetime.utcnow() + timedelta(days=365)
                # Initialize premium usage tracking
                current_user.premium_usage_this_month = 0
                current_user.premium_usage_reset_date = datetime.utcnow()
                
                # Give upgrade bonus + yearly bonus if converting from free
                if was_free_user:
                    bonus_credits = PREMIUM_CREDITS_ON_UPGRADE + PREMIUM_YEARLY_BONUS
                    current_user.credits += bonus_credits
                    credit_transaction = CreditTransaction(
                        user_id=current_user,
                        credits=bonus_credits,
                        transaction_type="reward",
                        description="Premium Yearly Upgrade - Welcome bonus + annual bonus",
                        transaction_id=request.transaction_id
                    )
                    await credit_transaction.insert()
                else:
                    # Existing premium users get the yearly bonus
                    current_user.credits += PREMIUM_YEARLY_BONUS
                    credit_transaction = CreditTransaction(
                        user_id=current_user,
                        credits=PREMIUM_YEARLY_BONUS,
                        transaction_type="reward",
                        description="Premium Yearly Subscription - Annual bonus",
                        transaction_id=request.transaction_id
                    )
                    await credit_transaction.insert()
        
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
    """Get comprehensive user subscription status (credit-driven system)."""
    try:
        return {
            "user_id": str(current_user.id),
            "subscription_tier": current_user.subscription_tier,
            "subscription_expires_at": current_user.subscription_expires_at,
            "credits": current_user.credits,
            "free_uses_remaining": 0,  # No free uses in credit-driven system
            "last_free_use_date": None,
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
    
    # Use the user's credits field as the source of truth
    # This is maintained by the system when credits are added/deducted
    user_credits = current_user.credits
    
    # Also calculate from transactions for history transparency
    purchases = await CreditTransaction.find(
        CreditTransaction.user_id == current_user,
        CreditTransaction.transaction_type == "purchase"
    ).to_list()
    
    total_purchased = sum(t.credits for t in purchases)
    
    usage = await CreditTransaction.find(
        CreditTransaction.user_id == current_user,
        CreditTransaction.transaction_type == "usage"
    ).to_list()
    
    total_used = sum(abs(t.credits) for t in usage)
    
    last_purchase = max(
        (t.created_at for t in purchases),
        default=None
    )
    
    return UserCreditsResponse(
        credits_remaining=user_credits,  # Use actual user.credits field
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

@router.get("/credit-costs", response_model=dict)
async def get_credit_costs():
    """Get credit costs for all services (centralized configuration)."""
    try:
        service_costs = get_all_costs()
        return {
            "message": "Credit costs retrieved successfully",
            "service_costs": service_costs,
            "description": {
                ServiceType.PHOTO_RESTORE.value: "Restore old photos to HD quality",
                ServiceType.MEMORY_MERGE.value: "Merge multiple photos together",
                ServiceType.CINEMATIC_FILTER.value: "Apply cinematic filters"
            },
            "initial_signup_credits": 3,
            "premium_unlimited": True
        }
    except Exception as e:
        logger.error(f"Error getting credit costs: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

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