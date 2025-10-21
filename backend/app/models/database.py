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
