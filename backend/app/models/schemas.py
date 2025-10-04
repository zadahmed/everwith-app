from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    name: str

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class User(UserBase):
    id: str
    profile_image_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class MessageBase(BaseModel):
    content: str
    receiver_id: str

class MessageCreate(MessageBase):
    pass

class Message(MessageBase):
    id: str
    sender_id: str
    created_at: datetime

    class Config:
        from_attributes = True

class EventBase(BaseModel):
    title: str
    description: Optional[str] = None
    date: datetime
    location: Optional[str] = None

class EventCreate(EventBase):
    pass

class Event(EventBase):
    id: str
    created_by: str
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
