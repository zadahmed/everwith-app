from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
import os
import ssl
from dotenv import load_dotenv
from app.models.database import User, Message, Event, ProcessedImage
import logging

# Load environment variables first
load_dotenv()

# MongoDB connection settings
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "everwith_db")

# Global client instance
client: AsyncIOMotorClient = None

logger = logging.getLogger(__name__)

def get_mongodb_client_options():
    """Get MongoDB client options based on connection string"""
    options = {
        "serverSelectionTimeoutMS": 10000,
        "connectTimeoutMS": 10000,
        "socketTimeoutMS": 10000,
    }
    
    # Handle SSL/TLS based on connection string
    if "mongodb+srv://" in MONGODB_URL:
        # MongoDB Atlas or cloud with SRV
        options.update({
            "tls": True,
            "tlsAllowInvalidCertificates": True,
            "tlsAllowInvalidHostnames": True,
        })
    elif "mongodb://" in MONGODB_URL and ("ondigitalocean.com" in MONGODB_URL or "mongodb.net" in MONGODB_URL):
        # DigitalOcean or other cloud providers
        options.update({
            "tls": True,
            "tlsAllowInvalidCertificates": True,
            "tlsAllowInvalidHostnames": True,
        })
    
    return options

async def test_connection():
    """Test MongoDB connection with different configurations"""
    test_configs = [
        {
            "name": "Default configuration",
            "url": MONGODB_URL,
            "options": get_mongodb_client_options()
        },
        {
            "name": "No SSL",
            "url": MONGODB_URL,
            "options": {
                "serverSelectionTimeoutMS": 10000,
                "connectTimeoutMS": 10000,
                "socketTimeoutMS": 10000,
                "tls": False
            }
        },
        {
            "name": "SSL with relaxed settings",
            "url": MONGODB_URL,
            "options": {
                "serverSelectionTimeoutMS": 10000,
                "connectTimeoutMS": 10000,
                "socketTimeoutMS": 10000,
                "tls": True,
                "tlsAllowInvalidCertificates": True,
                "tlsAllowInvalidHostnames": True,
                "tlsInsecure": True
            }
        }
    ]
    
    for config in test_configs:
        try:
            logger.info(f"Testing {config['name']}...")
            test_client = AsyncIOMotorClient(config['url'], **config['options'])
            
            # Test connection
            await test_client.admin.command('ping')
            logger.info(f"✅ {config['name']} - Connection successful!")
            
            # Test database access
            db = test_client[DATABASE_NAME]
            collections = await db.list_collection_names()
            logger.info(f"✅ {config['name']} - Database access successful! Collections: {collections}")
            
            test_client.close()
            return config
            
        except Exception as e:
            logger.warning(f"❌ {config['name']} - Failed: {e}")
            try:
                test_client.close()
            except:
                pass
    
    return None

async def init_db():
    """Initialize MongoDB connection and Beanie"""
    global client
    
    logger.info(f"🔗 Connecting to MongoDB...")
    logger.info(f"🗄️ Database: {DATABASE_NAME}")
    logger.info(f"🔗 Connection URL: {MONGODB_URL.replace('://', '://***:***@') if '@' in MONGODB_URL else MONGODB_URL}")
    
    # Test different connection configurations
    working_config = await test_connection()
    
    if not working_config:
        logger.error("❌ All MongoDB connection attempts failed!")
        logger.error("Please check:")
        logger.error("1. MongoDB instance is running")
        logger.error("2. Connection string is correct")
        logger.error("3. Network access is allowed")
        logger.error("4. Credentials are valid")
        raise Exception("Failed to connect to MongoDB")
    
    logger.info(f"✅ Using working configuration: {working_config['name']}")
    
    # Create motor client with working configuration
    client = AsyncIOMotorClient(working_config['url'], **working_config['options'])
    
    # Initialize Beanie with the database and document models
    await init_beanie(
        database=client[DATABASE_NAME],
        document_models=[User, Message, Event, ProcessedImage]
    )
    
    logger.info(f"✅ Connected to MongoDB: {DATABASE_NAME}")

async def close_db():
    """Close MongoDB connection"""
    global client
    if client:
        client.close()
        print("✅ MongoDB connection closed")

def get_client() -> AsyncIOMotorClient:
    """Get the MongoDB client instance"""
    return client
