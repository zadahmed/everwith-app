"""
Subscription and Purchase Management API
Handles premium subscriptions, credit purchases, and payment tracking
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from datetime import datetime, timedelta
from app.models.schemas import User
from app.models.database import User as DBUser, Subscription, CreditTransaction
from app.core.security import get_current_user
from pydantic import BaseModel
from enum import Enum

router = APIRouter(prefix="/api/subscriptions", tags=["subscriptions"])


class SubscriptionTier(str, Enum):
    FREE = "free"
    MONTHLY = "monthly"
    YEARLY = "yearly"
    LIFETIME = "lifetime"


class SubscriptionStatus(str, Enum):
    ACTIVE = "active"
    CANCELLED = "cancelled"
    EXPIRED = "expired"
    TRIAL = "trial"


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
    
    if subscription_data.tier == SubscriptionTier.MONTHLY:
        end_date = start_date + timedelta(days=30)
        trial_end_date = start_date + timedelta(days=7)  # 7-day trial
    elif subscription_data.tier == SubscriptionTier.YEARLY:
        end_date = start_date + timedelta(days=365)
        trial_end_date = start_date + timedelta(days=7)  # 7-day trial
    elif subscription_data.tier == SubscriptionTier.LIFETIME:
        end_date = None
        trial_end_date = None
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


# MARK: - Credit System

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
            "monthly": {
                "price": 5.99,
                "currency": "GBP",
                "trial_days": 3,
                "features": [
                    "Unlimited restores & merges",
                    "4K HD exports",
                    "Instant results",
                    "No watermark",
                    "All filters unlocked"
                ]
            },
            "yearly": {
                "price": 29.99,
                "currency": "GBP",
                "trial_days": 7,
                "savings": "58%",
                "price_per_month": 2.50,
                "features": [
                    "Everything in Monthly",
                    "Best value",
                    "Save £42 per year"
                ]
            },
            "lifetime": {
                "price": 79.99,
                "currency": "GBP",
                "features": [
                    "Pay once, use forever",
                    "All premium features",
                    "Future updates included"
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

