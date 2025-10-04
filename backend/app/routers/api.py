from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.models.schemas import Message, MessageCreate, Event, EventCreate
from app.models.database import Message as DBMessage, Event as DBEvent
from app.core.security import get_current_user
from app.models.database import User

router = APIRouter(prefix="/api", tags=["messages"])

@router.get("/messages", response_model=dict)
async def get_messages(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    messages = db.query(DBMessage).filter(
        (DBMessage.sender_id == current_user.id) | 
        (DBMessage.receiver_id == current_user.id)
    ).all()
    return {"messages": [Message.from_orm(msg) for msg in messages]}

@router.post("/messages", response_model=dict)
async def create_message(
    message: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_message = DBMessage(
        content=message.content,
        sender_id=current_user.id,
        receiver_id=message.receiver_id
    )
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    return {
        "message": "Message sent successfully",
        "data": Message.from_orm(db_message)
    }

@router.get("/events", response_model=dict)
async def get_events(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    events = db.query(DBEvent).all()
    return {"events": [Event.from_orm(event) for event in events]}

@router.post("/events", response_model=dict)
async def create_event(
    event: EventCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_event = DBEvent(
        title=event.title,
        description=event.description,
        date=event.date,
        location=event.location,
        created_by=current_user.id
    )
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    
    return {
        "message": "Event created successfully",
        "data": Event.from_orm(db_event)
    }

@router.get("/users", response_model=dict)
async def get_users(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    users = db.query(User).all()
    return {"users": [User.from_orm(user) for user in users]}
