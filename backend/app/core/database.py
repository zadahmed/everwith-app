from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
import os
from dotenv import load_dotenv
from app.models.database import User, Message, Event

# Load environment variables first
load_dotenv()

# MongoDB connection settings
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "everwith_db")

# Global client instance
client: AsyncIOMotorClient = None

async def init_db():
    """Initialize MongoDB connection and Beanie"""
    global client
    
    print(f"🔗 Connecting to MongoDB...")
    print(f"🗄️ Database: {DATABASE_NAME}")
    print(f"🔗 Connection URL: {MONGODB_URL.replace('://', '://***:***@') if '@' in MONGODB_URL else MONGODB_URL}")
    
    # Create motor client
    client = AsyncIOMotorClient(MONGODB_URL)
    
    # Initialize Beanie with the database and document models
    await init_beanie(
        database=client[DATABASE_NAME],
        document_models=[User, Message, Event]
    )
    
    print(f"✅ Connected to MongoDB: {DATABASE_NAME}")

async def close_db():
    """Close MongoDB connection"""
    global client
    if client:
        client.close()
        print("✅ MongoDB connection closed")

def get_client() -> AsyncIOMotorClient:
    """Get the MongoDB client instance"""
    return client
