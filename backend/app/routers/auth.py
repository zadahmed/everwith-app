from fastapi import APIRouter, Depends, HTTPException, status
from app.models.schemas import User, UserCreate, UserLogin, GoogleAuthRequest
from app.models.database import User as DBUser
from app.core.security import get_password_hash, verify_password, create_access_token, get_current_user
from app.services.google_auth import google_auth_service
from datetime import timedelta
import os
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["authentication"])

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

@router.post("/register", response_model=dict)
async def register(user: UserCreate):
    """
    Register a new user with email and password
    """
    try:
        # Check if user already exists
        existing_user = await DBUser.find_one(DBUser.email == user.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Validate password length (additional check)
        if len(user.password) > 72:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Password must be no more than 72 characters long"
            )
        
        # Create new user
        hashed_password = get_password_hash(user.password)
        db_user = DBUser(
            email=user.email,
            name=user.name,
            hashed_password=hashed_password,
            is_google_user=False
        )
        
        await db_user.insert()
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.email}, expires_delta=access_token_expires
        )
        
        return {
            "message": "User created successfully",
            "user": {
                "id": str(db_user.id),
                "email": db_user.email,
                "name": db_user.name,
                "profile_image_url": db_user.profile_image_url,
                "is_google_user": db_user.is_google_user,
                "is_active": db_user.is_active,
                "created_at": db_user.created_at.isoformat() if db_user.created_at else None,
                "updated_at": db_user.updated_at.isoformat() if db_user.updated_at else None
            },
            "access_token": access_token,
            "token_type": "bearer"
        }
    except HTTPException:
        raise
    except ValueError as e:
        # Handle Pydantic validation errors
        logger.error(f"Validation error during registration: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error during registration: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during registration"
        )

@router.post("/login", response_model=dict)
async def login(user_credentials: UserLogin):
    """
    Login with email and password
    """
    try:
        # Authenticate user
        user = await DBUser.find_one(DBUser.email == user_credentials.email)
        if not user or not user.hashed_password or not verify_password(user_credentials.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Account is deactivated"
            )
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.email}, expires_delta=access_token_expires
        )
        
        return {
            "message": "Login successful",
            "user": {
                "id": str(user.id),
                "email": user.email,
                "name": user.name,
                "profile_image_url": user.profile_image_url,
                "is_google_user": user.is_google_user,
                "is_active": user.is_active,
                "created_at": user.created_at.isoformat() if user.created_at else None,
                "updated_at": user.updated_at.isoformat() if user.updated_at else None
            },
            "access_token": access_token,
            "token_type": "bearer"
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during login: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during login"
        )

@router.post("/google", response_model=dict)
async def google_auth(google_request: GoogleAuthRequest):
    """
    Authenticate with Google Sign-In
    """
    try:
        result = await google_auth_service.authenticate_google_user(google_request.id_token)
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error during Google authentication: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during Google authentication"
        )

@router.get("/me", response_model=dict)
async def get_current_user_info(current_user: DBUser = Depends(get_current_user)):
    """
    Get current authenticated user information.
    
    Returns 200 with user data if authenticated.
    Returns 401 if token is missing, invalid, or expired.
    
    This endpoint is used by the mobile app to validate sessions on startup.
    """
    logger.info(f"Session validated for user: {current_user.email}")
    return {
        "id": str(current_user.id),
        "email": current_user.email,
        "name": current_user.name,
        "profile_image_url": current_user.profile_image_url,
        "is_google_user": current_user.is_google_user,
        "is_active": current_user.is_active,
        "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        "updated_at": current_user.updated_at.isoformat() if current_user.updated_at else None
    }

@router.post("/logout", response_model=dict)
async def logout():
    """
    Logout endpoint (client should discard the token)
    """
    return {"message": "Logout successful"}

@router.post("/refresh", response_model=dict)
async def refresh_token(current_user: DBUser = Depends(get_current_user)):
    """
    Refresh access token
    """
    try:
        # Create new access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": current_user.email}, expires_delta=access_token_expires
        )
        
        return {
            "message": "Token refreshed successfully",
            "access_token": access_token,
            "token_type": "bearer"
        }
    except Exception as e:
        logger.error(f"Error during token refresh: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during token refresh"
        )
