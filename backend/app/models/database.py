from beanie import Document, Indexed
from pydantic import Field, EmailStr, ConfigDict
from typing import Optional, List
from datetime import datetime
from bson import ObjectId

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
    sender_id: ObjectId
    receiver_id: ObjectId
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
    created_by: ObjectId
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
