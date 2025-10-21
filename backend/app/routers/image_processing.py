from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.models.schemas import RestoreRequest, TogetherRequest, JobResult
from app.models.database import User
from app.core.security import get_current_user
from app.services.image_processing import ImageProcessingService
import os
import uuid
from typing import Optional

router = APIRouter(prefix="/api/v1", tags=["image-processing"])

@router.post("/upload")
async def upload_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Upload an image file and return a URL for processing.
    """
    try:
        # Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Generate unique filename
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        filename = f"{uuid.uuid4().hex}.{file_extension}"
        
        # Save file to outputs directory
        output_dir = os.getenv("OUTPUT_DIR", "./outputs")
        os.makedirs(output_dir, exist_ok=True)
        file_path = os.path.join(output_dir, filename)
        
        # Write file
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        # Return file URL (in production, this would be a cloud storage URL)
        file_url = f"file://{os.path.abspath(file_path)}"
        
        return {"url": file_url, "filename": filename}
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"File upload failed: {str(e)}"
        )

@router.post("/restore", response_model=JobResult)
async def restore_photo(
    req: RestoreRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Restore and enhance a photo using AI image processing.
    
    This endpoint takes an image URL and applies restoration techniques to:
    - Remove noise, banding, and stains
    - Preserve identity, clothing, and lighting
    - Maintain natural skin texture
    - Apply optional aspect ratio adjustments
    """
    try:
        return ImageProcessingService.restore_pipeline(req)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Image restoration failed: {str(e)}"
        )

@router.post("/together", response_model=JobResult)
async def together_photo(
    req: TogetherRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Create a 'together' photo by combining two subjects into a single scene.
    
    This endpoint:
    - Generates or selects a background
    - Places two subjects naturally into the scene
    - Matches lighting and perspective
    - Applies finishing touches and aspect ratio adjustments
    """
    try:
        return ImageProcessingService.together_pipeline(req)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Together photo creation failed: {str(e)}"
        )
