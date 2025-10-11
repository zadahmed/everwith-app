from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from app.models.schemas import Message, MessageCreate, Event, EventCreate
from app.models.database import Message as DBMessage, Event as DBEvent, User
from app.core.security import get_current_user
from bson import ObjectId

router = APIRouter(prefix="/api", tags=["messages"])

@router.get("/messages", response_model=dict)
async def get_messages(
    current_user: User = Depends(get_current_user)
):
    """Get all messages for the current user"""
    messages = await DBMessage.find(
        (DBMessage.sender_id == current_user.id) | 
        (DBMessage.receiver_id == current_user.id)
    ).to_list()
    
    return {
        "messages": [
            {
                "id": str(msg.id),
                "content": msg.content,
                "sender_id": str(msg.sender_id),
                "receiver_id": str(msg.receiver_id),
                "created_at": msg.created_at
            } for msg in messages
        ]
    }

@router.post("/messages", response_model=dict)
async def create_message(
    message: MessageCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new message"""
    try:
        # Convert string IDs to ObjectId
        receiver_object_id = ObjectId(message.receiver_id)
        
        db_message = DBMessage(
            content=message.content,
            sender_id=current_user.id,
            receiver_id=receiver_object_id
        )
        
        await db_message.insert()
        
        return {
            "message": "Message sent successfully",
            "data": {
                "id": str(db_message.id),
                "content": db_message.content,
                "sender_id": str(db_message.sender_id),
                "receiver_id": str(db_message.receiver_id),
                "created_at": db_message.created_at
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid receiver ID: {str(e)}"
        )

@router.get("/events", response_model=dict)
async def get_events(
    current_user: User = Depends(get_current_user)
):
    """Get all events"""
    events = await DBEvent.find_all().to_list()
    
    return {
        "events": [
            {
                "id": str(event.id),
                "title": event.title,
                "description": event.description,
                "date": event.date,
                "location": event.location,
                "created_by": str(event.created_by),
                "created_at": event.created_at
            } for event in events
        ]
    }

@router.post("/events", response_model=dict)
async def create_event(
    event: EventCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new event"""
    db_event = DBEvent(
        title=event.title,
        description=event.description,
        date=event.date,
        location=event.location,
        created_by=current_user.id
    )
    
    await db_event.insert()
    
    return {
        "message": "Event created successfully",
        "data": {
            "id": str(db_event.id),
            "title": db_event.title,
            "description": db_event.description,
            "date": db_event.date,
            "location": db_event.location,
            "created_by": str(db_event.created_by),
            "created_at": db_event.created_at
        }
    }

@router.get("/users", response_model=dict)
async def get_users(
    current_user: User = Depends(get_current_user)
):
    """Get all users"""
    users = await User.find_all().to_list()
    
    return {
        "users": [
            {
                "id": str(user.id),
                "email": user.email,
                "name": user.name,
                "profile_image_url": user.profile_image_url,
                "is_google_user": user.is_google_user,
                "is_active": user.is_active,
                "created_at": user.created_at,
                "updated_at": user.updated_at
            } for user in users
        ]
    }
