from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.models.schemas import RestoreRequest, TogetherRequest, JobResult
from app.models.database import User
from app.core.security import get_current_user
from app.services.image_processing import ImageProcessingService
import os
import io
import uuid
from typing import Optional
from PIL import Image
import boto3
from botocore.exceptions import ClientError

router = APIRouter(prefix="/api/v1", tags=["image-processing"])

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
        print(f"🔵 Restore API called with image_url: {req.image_url}")
        result = ImageProcessingService.restore_pipeline(req)
        print(f"✅ Restore successful: {result.output_url}")
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
