from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.models.schemas import RestoreRequest, TogetherRequest, JobResult, TimelineRequest, CelebrityRequest, ReuniteRequest, FamilyRequest
from app.models.database import User
from app.core.security import get_current_user
from app.services.image_processing import ImageProcessingService
from app.middleware.usage_validation import validate_usage, increment_usage, get_usage_status
import os
import io
import uuid
from typing import Optional
from PIL import Image
import boto3
from botocore.exceptions import ClientError

router = APIRouter(prefix="/api/v1", tags=["image-processing"])

@router.get("/usage-status")
async def get_usage_status_endpoint(
    current_user: User = Depends(get_current_user)
):
    """
    Get current usage status before processing.
    Frontend can call this to show warnings/cooldown info before user starts processing.
    """
    from app.middleware.usage_validation import get_usage_status
    return await get_usage_status(current_user)

# DigitalOcean Spaces Configuration for upload endpoint
DO_SPACES_KEY = os.getenv("DO_SPACES_KEY")
DO_SPACES_SECRET = os.getenv("DO_SPACES_SECRET")
DO_SPACES_REGION = os.getenv("DO_SPACES_REGION", "nyc3")
DO_SPACES_BUCKET = os.getenv("DO_SPACES_BUCKET")
DO_SPACES_ENDPOINT = os.getenv("DO_SPACES_ENDPOINT", "https://nyc3.digitaloceanspaces.com")
DO_SPACES_CDN_ENDPOINT = os.getenv("DO_SPACES_CDN_ENDPOINT")

# Initialize DigitalOcean Spaces client
s3_client = None
if DO_SPACES_KEY and DO_SPACES_SECRET:
    s3_client = boto3.client(
        's3',
        region_name="ams3",
        endpoint_url=DO_SPACES_ENDPOINT,
        aws_access_key_id=DO_SPACES_KEY,
        aws_secret_access_key=DO_SPACES_SECRET
    )

@router.post("/upload")
async def upload_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Upload an image file to DigitalOcean Spaces and return a CDN URL.
    """
    try:
        # Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Generate unique filename with everwith/ prefix
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        filename = f"everwith/{uuid.uuid4().hex}.{file_extension}"
        
        # Read file content
        content = await file.read()
        
        # Upload to DigitalOcean Spaces if configured
        if s3_client and DO_SPACES_BUCKET:
            try:
                # Determine content type
                content_type = file.content_type or 'image/jpeg'
                
                # Upload to Spaces
                s3_client.upload_fileobj(
                    io.BytesIO(content),
                    DO_SPACES_BUCKET,
                    filename,
                    ExtraArgs={
                        'ContentType': content_type,
                        'ACL': 'public-read',  # Public for fast CDN access
                        'CacheControl': 'max-age=31536000'
                    }
                )
                
                # Return CDN URL for authenticated access
                if DO_SPACES_CDN_ENDPOINT:
                    file_url = f"{DO_SPACES_CDN_ENDPOINT}/{filename}"
                else:
                    file_url = f"https://{DO_SPACES_BUCKET}.{DO_SPACES_REGION}.digitaloceanspaces.com/{filename}"
                
                print(f"✅ Uploaded to Spaces: {file_url}")
                
                # CRITICAL: Verify the uploaded file is publicly accessible
                print(f"🔍 Verifying public access...")
                try:
                    import requests
                    test_response = requests.head(file_url, timeout=5)
                    if test_response.status_code == 200:
                        print(f"✅ File is publicly accessible! BFL can access it.")
                    else:
                        print(f"⚠️ WARNING: File returned status {test_response.status_code}")
                        print(f"⚠️ BFL may not be able to access this URL!")
                except Exception as e:
                    print(f"⚠️ WARNING: Could not verify public access: {e}")
                    print(f"⚠️ This may cause issues with BFL API!")
                
                return {"url": file_url, "filename": filename}
                
            except ClientError as e:
                print(f"❌ Failed to upload to Spaces: {e}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to upload to cloud storage: {str(e)}"
                )
        
        # Fallback: Save locally (for development)
        print("⚠️⚠️⚠️ DigitalOcean Spaces not configured - using local storage")
        print("⚠️ WARNING: file:// URLs will NOT work with BFL API!")
        print("⚠️ Please configure in .env:")
        print("⚠️   DO_SPACES_KEY=your-key")
        print("⚠️   DO_SPACES_SECRET=your-secret")
        print("⚠️   DO_SPACES_BUCKET=your-bucket-name")
        
        raise HTTPException(
            status_code=500,
            detail="DigitalOcean Spaces not configured. Local file storage cannot be used with external APIs. Please configure DO_SPACES_KEY, DO_SPACES_SECRET, and DO_SPACES_BUCKET in your .env file."
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"File upload failed: {str(e)}"
        )

@router.post("/restore", response_model=JobResult)
async def restore_photo(
    req: RestoreRequest,
    current_user: User = Depends(get_current_user),
    usage_status: dict = Depends(validate_usage)
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
        print(f"🔵 Restore API called with image_url: {req.image_url}")
        result = ImageProcessingService.restore_pipeline(req)
        print(f"✅ Restore successful: {result.output_url}")
        
        # Increment usage tracking for all users after successful processing
        tracking = await increment_usage(current_user)
        # Get updated status after incrementing
        updated_status = await get_usage_status(current_user)
        # Always include usage info in meta for frontend display
        if result.meta is None:
            result.meta = {}
        result.meta["usage_info"] = {
            "usage_count": updated_status["usage_count"],
            "soft_limit": updated_status["soft_limit"],
            "cooldown_limit": updated_status["cooldown_limit"],
            "in_cooldown": updated_status["in_cooldown"],
            "at_soft_limit": updated_status.get("at_soft_limit", False),
            "approaching_limit": updated_status.get("approaching_limit", False),
            "message": updated_status.get("message"),
            "processing_speed_multiplier": updated_status.get("processing_speed_multiplier", 1.0),
            "estimated_wait_seconds": updated_status.get("estimated_wait_seconds"),
            "remaining_until_soft_limit": updated_status.get("remaining_until_soft_limit", 0),
            "remaining_until_cooldown": updated_status.get("remaining_until_cooldown", 0)
        }
        
        return result
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Restore failed with error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Image restoration failed: {str(e)}"
        )

@router.post("/together", response_model=JobResult)
async def together_photo(
    req: TogetherRequest,
    current_user: User = Depends(get_current_user),
    usage_status: dict = Depends(validate_usage)
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
        result = ImageProcessingService.together_pipeline(req)
        
        # Increment usage tracking for all users after successful processing
        tracking = await increment_usage(current_user)
        # Get updated status after incrementing
        updated_status = await get_usage_status(current_user)
        # Always include usage info in meta for frontend display
        if result.meta is None:
            result.meta = {}
        result.meta["usage_info"] = {
            "usage_count": updated_status["usage_count"],
            "soft_limit": updated_status["soft_limit"],
            "cooldown_limit": updated_status["cooldown_limit"],
            "in_cooldown": updated_status["in_cooldown"],
            "at_soft_limit": updated_status.get("at_soft_limit", False),
            "approaching_limit": updated_status.get("approaching_limit", False),
            "message": updated_status.get("message"),
            "processing_speed_multiplier": updated_status.get("processing_speed_multiplier", 1.0),
            "estimated_wait_seconds": updated_status.get("estimated_wait_seconds"),
            "remaining_until_soft_limit": updated_status.get("remaining_until_soft_limit", 0),
            "remaining_until_cooldown": updated_status.get("remaining_until_cooldown", 0)
        }
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Together photo creation failed: {str(e)}"
        )

@router.post("/timeline", response_model=JobResult)
async def timeline_photo(
    req: TimelineRequest,
    current_user: User = Depends(get_current_user),
    usage_status: dict = Depends(validate_usage)
):
    """
    Create age progression or regression for a person.
    
    This endpoint transforms a photo to show the person at a different age.
    """
    try:
        result = ImageProcessingService.timeline_pipeline(req)
        
        # Increment usage tracking for all users after successful processing
        tracking = await increment_usage(current_user)
        # Get updated status after incrementing
        updated_status = await get_usage_status(current_user)
        # Always include usage info in meta for frontend display
        if result.meta is None:
            result.meta = {}
        result.meta["usage_info"] = {
            "usage_count": updated_status["usage_count"],
            "soft_limit": updated_status["soft_limit"],
            "cooldown_limit": updated_status["cooldown_limit"],
            "in_cooldown": updated_status["in_cooldown"],
            "at_soft_limit": updated_status.get("at_soft_limit", False),
            "approaching_limit": updated_status.get("approaching_limit", False),
            "message": updated_status.get("message"),
            "processing_speed_multiplier": updated_status.get("processing_speed_multiplier", 1.0),
            "estimated_wait_seconds": updated_status.get("estimated_wait_seconds"),
            "remaining_until_soft_limit": updated_status.get("remaining_until_soft_limit", 0),
            "remaining_until_cooldown": updated_status.get("remaining_until_cooldown", 0)
        }
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Timeline transformation failed: {str(e)}"
        )

@router.post("/celebrity", response_model=JobResult)
async def celebrity_photo(
    req: CelebrityRequest,
    current_user: User = Depends(get_current_user),
    usage_status: dict = Depends(validate_usage)
):
    """
    Transform a photo to give it a celebrity glamour treatment.
    
    This endpoint:
    - Applies glamour makeup and styling
    - Enhances lighting and composition
    - Adds celebrity-like polish and refinement
    """
    try:
        result = ImageProcessingService.celebrity_pipeline(req)
        
        # Increment usage tracking for all users after successful processing
        tracking = await increment_usage(current_user)
        # Get updated status after incrementing
        updated_status = await get_usage_status(current_user)
        # Always include usage info in meta for frontend display
        if result.meta is None:
            result.meta = {}
        result.meta["usage_info"] = {
            "usage_count": updated_status["usage_count"],
            "soft_limit": updated_status["soft_limit"],
            "cooldown_limit": updated_status["cooldown_limit"],
            "in_cooldown": updated_status["in_cooldown"],
            "at_soft_limit": updated_status.get("at_soft_limit", False),
            "approaching_limit": updated_status.get("approaching_limit", False),
            "message": updated_status.get("message"),
            "processing_speed_multiplier": updated_status.get("processing_speed_multiplier", 1.0),
            "estimated_wait_seconds": updated_status.get("estimated_wait_seconds"),
            "remaining_until_soft_limit": updated_status.get("remaining_until_soft_limit", 0),
            "remaining_until_cooldown": updated_status.get("remaining_until_cooldown", 0)
        }
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Celebrity transformation failed: {str(e)}"
        )

@router.post("/reunite", response_model=JobResult)
async def reunite_photo(
    req: ReuniteRequest,
    current_user: User = Depends(get_current_user),
    usage_status: dict = Depends(validate_usage)
):
    """
    Create a photo that reunites two people who couldn't be together in real life.
    
    This endpoint combines two people into a natural scene together.
    """
    try:
        result = ImageProcessingService.reunite_pipeline(req)
        
        # Increment usage tracking for all users after successful processing
        tracking = await increment_usage(current_user)
        # Get updated status after incrementing
        updated_status = await get_usage_status(current_user)
        # Always include usage info in meta for frontend display
        if result.meta is None:
            result.meta = {}
        result.meta["usage_info"] = {
            "usage_count": updated_status["usage_count"],
            "soft_limit": updated_status["soft_limit"],
            "cooldown_limit": updated_status["cooldown_limit"],
            "in_cooldown": updated_status["in_cooldown"],
            "at_soft_limit": updated_status.get("at_soft_limit", False),
            "approaching_limit": updated_status.get("approaching_limit", False),
            "message": updated_status.get("message"),
            "processing_speed_multiplier": updated_status.get("processing_speed_multiplier", 1.0),
            "estimated_wait_seconds": updated_status.get("estimated_wait_seconds"),
            "remaining_until_soft_limit": updated_status.get("remaining_until_soft_limit", 0),
            "remaining_until_cooldown": updated_status.get("remaining_until_cooldown", 0)
        }
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Reunite photo creation failed: {str(e)}"
        )

@router.post("/family", response_model=JobResult)
async def family_photo(
    req: FamilyRequest,
    current_user: User = Depends(get_current_user),
    usage_status: dict = Depends(validate_usage)
):
    """
    Create enhanced family photos or memory collages.
    
    This endpoint combines and enhances multiple family photos.
    """
    try:
        result = ImageProcessingService.family_pipeline(req)
        
        # Increment usage tracking for all users after successful processing
        tracking = await increment_usage(current_user)
        # Get updated status after incrementing
        updated_status = await get_usage_status(current_user)
        # Always include usage info in meta for frontend display
        if result.meta is None:
            result.meta = {}
        result.meta["usage_info"] = {
            "usage_count": updated_status["usage_count"],
            "soft_limit": updated_status["soft_limit"],
            "cooldown_limit": updated_status["cooldown_limit"],
            "in_cooldown": updated_status["in_cooldown"],
            "at_soft_limit": updated_status.get("at_soft_limit", False),
            "approaching_limit": updated_status.get("approaching_limit", False),
            "message": updated_status.get("message"),
            "processing_speed_multiplier": updated_status.get("processing_speed_multiplier", 1.0),
            "estimated_wait_seconds": updated_status.get("estimated_wait_seconds"),
            "remaining_until_soft_limit": updated_status.get("remaining_until_soft_limit", 0),
            "remaining_until_cooldown": updated_status.get("remaining_until_cooldown", 0)
        }
        
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Family photo processing failed: {str(e)}"
        )
