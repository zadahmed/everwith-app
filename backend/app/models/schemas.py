from pydantic import BaseModel, EmailStr, field_validator, AnyHttpUrl
from typing import Optional, Literal
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    name: str

class UserCreate(UserBase):
    password: str
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if len(v) > 72:
            raise ValueError('Password must be no more than 72 characters long')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class GoogleAuthRequest(BaseModel):
    id_token: str  # Google ID token from client

class GoogleUserInfo(BaseModel):
    google_id: str
    email: EmailStr
    name: str
    picture: Optional[str] = None

class User(UserBase):
    id: str
    profile_image_url: Optional[str] = None
    is_google_user: bool = False
    is_active: bool = True
    created_at: datetime
    updated_at: datetime

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

# Image Processing Schemas
class RestoreRequest(BaseModel):
    image_url: AnyHttpUrl
    quality_target: Literal["standard", "premium"] = "standard"
    output_format: Literal["png", "webp", "jpg"] = "png"
    aspect_ratio: Literal["original", "4:5", "1:1", "16:9"] = "original"
    seed: Optional[int] = None

class TogetherBackground(BaseModel):
    mode: Literal["gallery", "generate"] = "gallery"
    scene_id: Optional[str] = None       # required if gallery
    prompt: Optional[str] = None         # used if generate
    use_ultra: bool = False

class LookControls(BaseModel):
    warmth: float = 0.0
    shadows: float = 0.0
    grain: float = 0.0

class TogetherRequest(BaseModel):
    subject_a_url: AnyHttpUrl
    subject_b_url: AnyHttpUrl
    subject_a_mask_url: Optional[AnyHttpUrl] = None    # optional if you send cutouts with alpha elsewhere
    subject_b_mask_url: Optional[AnyHttpUrl] = None
    background: TogetherBackground
    aspect_ratio: Literal["original", "4:5", "1:1", "16:9"] = "4:5"
    seed: Optional[int] = None
    look_controls: Optional[LookControls] = LookControls()

class JobResult(BaseModel):
    output_url: str
    meta: dict

# New Mode Schemas
class TimelineRequest(BaseModel):
    image_url: AnyHttpUrl
    target_age: Literal["young", "current", "old"] = "current"
    quality_target: Literal["standard", "premium"] = "standard"
    output_format: Literal["png", "webp", "jpg"] = "png"
    aspect_ratio: Literal["original", "4:5", "1:1", "16:9"] = "original"
    seed: Optional[int] = None

class CelebrityRequest(BaseModel):
    image_url: AnyHttpUrl
    celebrity_style: Literal["movie_star", "royal", "vintage_glamour", "modern_celebrity"] = "movie_star"
    quality_target: Literal["standard", "premium"] = "standard"
    output_format: Literal["png", "webp", "jpg"] = "png"
    aspect_ratio: Literal["original", "4:5", "1:1", "16:9"] = "original"
    seed: Optional[int] = None

class ReuniteRequest(BaseModel):
    image_a_url: AnyHttpUrl
    image_b_url: AnyHttpUrl
    background_prompt: Optional[str] = None
    quality_target: Literal["standard", "premium"] = "standard"
    output_format: Literal["png", "webp", "jpg"] = "png"
    aspect_ratio: Literal["original", "4:5", "1:1", "16:9"] = "original"
    seed: Optional[int] = None

class FamilyRequest(BaseModel):
    images: list[str]  # List of image URLs
    style: Literal["collage", "composite", "enhanced"] = "enhanced"
    quality_target: Literal["standard", "premium"] = "standard"
    output_format: Literal["png", "webp", "jpg"] = "png"
    aspect_ratio: Literal["original", "4:5", "1:1", "16:9"] = "original"
    seed: Optional[int] = None

# Processed Image Schemas
class ProcessedImageCreate(BaseModel):
    image_type: Literal["restore", "together", "timeline", "celebrity", "reunite", "family"]
    original_image_url: Optional[str] = None
    processed_image_url: str
    thumbnail_url: Optional[str] = None
    
    # Processing parameters
    quality_target: Optional[str] = None
    output_format: Optional[str] = None
    aspect_ratio: Optional[str] = None
    
    # For together images
    subject_a_url: Optional[str] = None
    subject_b_url: Optional[str] = None
    background_prompt: Optional[str] = None
    
    # Metadata
    width: Optional[int] = None
    height: Optional[int] = None
    file_size: Optional[int] = None

class ProcessedImage(BaseModel):
    id: str
    user_id: str
    image_type: str
    original_image_url: Optional[str] = None
    processed_image_url: str
    thumbnail_url: Optional[str] = None
    
    # Processing parameters
    quality_target: Optional[str] = None
    output_format: Optional[str] = None
    aspect_ratio: Optional[str] = None
    
    # For together images
    subject_a_url: Optional[str] = None
    subject_b_url: Optional[str] = None
    background_prompt: Optional[str] = None
    
    # Metadata
    width: Optional[int] = None
    height: Optional[int] = None
    file_size: Optional[int] = None
    
    created_at: datetime
    
    class Config:
        from_attributes = True

class ImageHistoryResponse(BaseModel):
    images: list[ProcessedImage]
    total: int
    page: int
    page_size: int
    
    model_config = {"from_attributes": True}