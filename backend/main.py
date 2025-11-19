from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, api, image_processing, image_history, feedback, subscription_api, share
from app.core.database import init_db, close_db
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan events"""
    # Startup
    await init_db()
    yield
    # Shutdown
    await close_db()

app = FastAPI(
    title="EverWith API",
    description="Backend API for EverWith mobile app",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:8080,http://localhost:8000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(api.router)
app.include_router(image_processing.router)
app.include_router(image_history.router, prefix="/images", tags=["images"])
app.include_router(feedback.router)
app.include_router(subscription_api.router)
app.include_router(share.router)

@app.get("/")
async def root():
    return {"message": "EverWith API is running!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    import os
    
    # Only enable reload in development
    reload = os.getenv("ENVIRONMENT", "development") == "development"
    
    # Exclude virtual environment and other directories from file watching
    reload_dirs = ["app"] if reload else None
    reload_excludes = [".venv", "__pycache__", "*.pyc", "*.pyo", "node_modules", ".git"]
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=reload,
        reload_dirs=reload_dirs,
        reload_excludes=reload_excludes
    )