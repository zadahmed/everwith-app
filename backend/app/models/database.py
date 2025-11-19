from beanie import Document, Indexed, Link
from pydantic import Field, EmailStr, ConfigDict
from typing import Optional, List
from datetime import datetime

class User(Document):
    """User document model for MongoDB"""
    
    email: Indexed(EmailStr, unique=True)
    name: str
    hashed_password: Optional[str] = None  # None for Google OAuth users
    profile_image_url: Optional[str] = None
    google_id: Optional[Indexed(str, unique=True)] = None
    is_google_user: bool = False
    is_active: bool = True
    
    # Monetization fields
    subscription_tier: str = "free"  # free, premium_monthly, premium_yearly
    subscription_expires_at: Optional[datetime] = None
    credits: int = 0  # Credits required for all processing (credit-driven system)
    free_uses_remaining: int = 0  # No free uses - everything requires credits
    last_free_use_date: Optional[datetime] = None
    
    # Monthly credit allocation tracking
    monthly_credits_reset_date: Optional[datetime] = None  # When monthly credits were last reset
    premium_usage_this_month: int = 0  # Track premium user monthly usage for cost control
    premium_usage_reset_date: Optional[datetime] = None  # When monthly premium usage was last reset
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "users"
        indexes = [
            "email",
            "google_id",
            "is_active"
        ]
    
    def __str__(self):
        return f"User(id={self.id}, email={self.email}, name={self.name})"

class Message(Document):
    """Message document model for MongoDB"""
    
    content: str
    sender_id: Link[User]
    receiver_id: Link[User]
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "messages"
        indexes = [
            "sender_id",
            "receiver_id",
            "created_at"
        ]
    
    def __str__(self):
        return f"Message(id={self.id}, sender={self.sender_id}, receiver={self.receiver_id})"

class Event(Document):
    """Event document model for MongoDB"""
    
    title: str
    description: Optional[str] = None
    date: datetime
    location: Optional[str] = None
    created_by: Link[User]
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "events"
        indexes = [
            "created_by",
            "date",
            "created_at"
        ]
    
    def __str__(self):
        return f"Event(id={self.id}, title={self.title}, date={self.date})"

class ProcessedImage(Document):
    """Processed image document model for MongoDB"""
    
    user_id: Link[User]
    image_type: str  # "restore" or "together"
    original_image_url: Optional[str] = None
    processed_image_url: str
    thumbnail_url: Optional[str] = None
    
    # Processing parameters
    quality_target: Optional[str] = None  # "standard" or "premium"
    output_format: Optional[str] = None   # "png", "webp", "jpg"
    aspect_ratio: Optional[str] = None    # "original", "4:5", "1:1", "16:9"
    
    # For together images
    subject_a_url: Optional[str] = None
    subject_b_url: Optional[str] = None
    background_prompt: Optional[str] = None
    
    # Metadata
    width: Optional[int] = None
    height: Optional[int] = None
    file_size: Optional[int] = None
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "processed_images"
        indexes = [
            "user_id",
            "image_type",
            "created_at"
        ]
    
    def __str__(self):
        return f"ProcessedImage(id={self.id}, user_id={self.user_id}, type={self.image_type})"


class Subscription(Document):
    """Subscription document model for MongoDB"""
    
    user_id: Link[User]
    tier: str  # "free", "premium_monthly", "premium_yearly"
    status: str  # "active", "cancelled", "expired", "trial"
    start_date: datetime
    end_date: Optional[datetime] = None
    trial_end_date: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    transaction_id: str
    receipt_data: str
    auto_renew: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "subscriptions"
        indexes = [
            "user_id",
            "status",
            "tier",
            "end_date"
        ]
    
    def is_active(self) -> bool:
        """Check if subscription is currently active"""
        if self.status not in ["active", "trial"]:
            return False
        if self.end_date and self.end_date < datetime.utcnow():
            return False
        return True
    
    def __str__(self):
        return f"Subscription(id={self.id}, user_id={self.user_id}, tier={self.tier})"


class CreditTransaction(Document):
    """Credit transaction document model for MongoDB"""
    
    user_id: Link[User]
    credits: int  # Positive for purchase, negative for usage
    transaction_type: str  # "purchase", "usage", "reward", "refund"
    amount: Optional[float] = None  # Amount paid (for purchases)
    currency: Optional[str] = "GBP"
    transaction_id: Optional[str] = None
    receipt_data: Optional[str] = None
    description: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "credit_transactions"
        indexes = [
            "user_id",
            "transaction_type",
            "created_at"
        ]
    
    def __str__(self):
        return f"CreditTransaction(id={self.id}, user_id={self.user_id}, credits={self.credits})"


class UserFeedback(Document):
    """User feedback document model for MongoDB"""
    
    user_id: Link[User]
    feedback_type: str  # "general", "bug", "feature", "help"
    subject: str
    message: str
    device_info: Optional[dict] = None
    app_version: Optional[str] = None
    status: str = "pending"  # "pending", "reviewed", "resolved"
    admin_notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "user_feedback"
        indexes = [
            "user_id",
            "feedback_type",
            "status",
            "created_at"
        ]
    
    def __str__(self):
        return f"UserFeedback(id={self.id}, type={self.feedback_type}, status={self.status})"


class ShareEvent(Document):
    """Share event tracking for rewards"""
    
    user_id: Link[User]
    share_type: str  # "social", "direct", "link"
    platform: Optional[str] = None  # "instagram", "tiktok", etc.
    image_id: Optional[Link[ProcessedImage]] = None
    share_url: Optional[str] = None
    caption: Optional[str] = None
    hashtags: List[str] = Field(default_factory=list)
    reward_credits: int = 1
    verification_status: str = "pending"  # pending, verified, rejected
    verified: bool = False
    verified_at: Optional[datetime] = None
    verification_notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "share_events"
        indexes = [
            "user_id",
            "platform",
            "share_url",
            "verified",
            "created_at"
        ]
    
    def __str__(self):
        status = "verified" if self.verified else "pending"
        return f"ShareEvent(id={self.id}, user_id={self.user_id}, platform={self.platform}, status={status})"


class UsageLog(Document):
    """Usage log for tracking feature usage"""
    
    user_id: Link[User]
    mode: str  # "restore", "merge"
    used_credit: bool = False
    used_free_use: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "usage_logs"
        indexes = [
            "user_id",
            "mode",
            "created_at"
        ]
    
    def __str__(self):
        return f"UsageLog(id={self.id}, user_id={self.user_id}, mode={self.mode})"


class Transaction(Document):
    """Transaction document for purchase tracking"""
    
    user_id: Link[User]
    product_id: str
    transaction_id: str
    purchase_type: str  # "subscription", "credit_pack"
    amount: Optional[float] = None
    currency: str = "GBP"
    revenue_cat_data: Optional[str] = None  # JSON string
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "transactions"
        indexes = [
            "user_id",
            "transaction_id",
            "purchase_type",
            "created_at"
        ]
    
    def __str__(self):
        return f"Transaction(id={self.id}, user_id={self.user_id}, product_id={self.product_id})"


class UserStats(Document):
    """User statistics and analytics"""
    
    user_id: Link[User]
    total_images_processed: int = 0
    total_restores: int = 0
    total_merges: int = 0
    total_shares: int = 0
    credits_earned_from_shares: int = 0
    favorite_filter: Optional[str] = None
    last_active: datetime = Field(default_factory=datetime.utcnow)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    class Settings:
        name = "user_stats"
        indexes = [
            "user_id",
            "last_active"
        ]
    
    def __str__(self):
        return f"UserStats(id={self.id}, user_id={self.user_id}, total_processed={self.total_images_processed})"
