from google.auth.transport import requests
from google.oauth2 import id_token
from app.models.database import User
from app.models.schemas import GoogleUserInfo
from app.core.security import create_access_token
from datetime import timedelta
import os
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

# Google OAuth2 configuration
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")

class GoogleAuthService:
    def __init__(self):
        self.client_id = GOOGLE_CLIENT_ID
        self.client_secret = GOOGLE_CLIENT_SECRET
        if not self.client_id:
            logger.warning("GOOGLE_CLIENT_ID not set in environment variables")
        if not self.client_secret:
            logger.info("GOOGLE_CLIENT_SECRET not set - using ID Token verification only")
    
    def verify_google_token(self, id_token_str: str) -> GoogleUserInfo:
        """
        Verify Google ID token and extract user information
        """
        try:
            # Verify the token
            idinfo = id_token.verify_oauth2_token(
                id_token_str, 
                requests.Request(), 
                self.client_id
            )
            
            # Extract user information
            google_user = GoogleUserInfo(
                google_id=idinfo['sub'],
                email=idinfo['email'],
                name=idinfo['name'],
                picture=idinfo.get('picture')
            )
            
            return google_user
            
        except ValueError as e:
            logger.error(f"Invalid Google token: {e}")
            raise ValueError("Invalid Google token")
        except Exception as e:
            logger.error(f"Error verifying Google token: {e}")
            raise ValueError("Error verifying Google token")
    
    async def get_or_create_user(self, google_user: GoogleUserInfo) -> User:
        """
        Get existing user or create new user from Google authentication
        """
        # Check if user exists by Google ID
        user = await User.find_one(User.google_id == google_user.google_id)
        
        if user:
            # Update user info if needed
            if user.email != google_user.email or user.name != google_user.name:
                user.email = google_user.email
                user.name = google_user.name
                user.profile_image_url = google_user.picture
                await user.save()
            return user
        
        # Check if user exists by email (for users who might have signed up with email first)
        existing_user = await User.find_one(User.email == google_user.email)
        if existing_user:
            # Link Google account to existing email account
            existing_user.google_id = google_user.google_id
            existing_user.is_google_user = True
            existing_user.profile_image_url = google_user.picture
            await existing_user.save()
            return existing_user
        
        # Create new user
        new_user = User(
            email=google_user.email,
            name=google_user.name,
            google_id=google_user.google_id,
            is_google_user=True,
            profile_image_url=google_user.picture,
            hashed_password=None  # No password for Google users
        )
        
        await new_user.insert()
        return new_user
    
    async def authenticate_google_user(self, id_token_str: str) -> dict:
        """
        Complete Google authentication flow
        """
        # Verify Google token
        google_user = self.verify_google_token(id_token_str)
        
        # Get or create user
        user = await self.get_or_create_user(google_user)
        
        # Create access token
        access_token_expires = timedelta(minutes=30)
        access_token = create_access_token(
            data={"sub": user.email}, 
            expires_delta=access_token_expires
        )
        
        return {
            "message": "Google authentication successful",
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

# Create singleton instance
google_auth_service = GoogleAuthService()
