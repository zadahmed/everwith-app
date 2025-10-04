from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, api
from app.core.database import engine
from app.models.database import Base
import os

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="EverWith API",
    description="Backend API for EverWith mobile app",
    version="1.0.0"
)

# CORS middleware
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:8080").split(",")
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

@app.get("/")
async def root():
    return {"message": "EverWith API is running!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )