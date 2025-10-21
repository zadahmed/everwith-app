from fastapi import APIRouter, Depends, HTTPException, Query
from app.models import database as db_models
from app.models import schemas
from app.core.security import get_current_user
from typing import List
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/save", response_model=schemas.ProcessedImage)
async def save_processed_image(
    image_data: schemas.ProcessedImageCreate,
    current_user: db_models.User = Depends(get_current_user)
):
    """Save a processed image to user's history"""
    try:
        # Create ProcessedImage document
        processed_image = db_models.ProcessedImage(
            user_id=current_user,
            image_type=image_data.image_type,
            original_image_url=image_data.original_image_url,
            processed_image_url=image_data.processed_image_url,
            thumbnail_url=image_data.thumbnail_url,
            quality_target=image_data.quality_target,
            output_format=image_data.output_format,
            aspect_ratio=image_data.aspect_ratio,
            subject_a_url=image_data.subject_a_url,
            subject_b_url=image_data.subject_b_url,
            background_prompt=image_data.background_prompt,
            width=image_data.width,
            height=image_data.height,
            file_size=image_data.file_size
        )
        
        # Save to database
        await processed_image.insert()
        
        logger.info(f"✅ Saved processed image for user {current_user.email}")
        
        # Create response object
        response_data = schemas.ProcessedImage(
            id=str(processed_image.id),
            user_id=str(processed_image.user_id.id),
            image_type=processed_image.image_type,
            original_image_url=processed_image.original_image_url,
            processed_image_url=processed_image.processed_image_url,
            thumbnail_url=processed_image.thumbnail_url,
            quality_target=processed_image.quality_target,
            output_format=processed_image.output_format,
            aspect_ratio=processed_image.aspect_ratio,
            subject_a_url=processed_image.subject_a_url,
            subject_b_url=processed_image.subject_b_url,
            background_prompt=processed_image.background_prompt,
            width=processed_image.width,
            height=processed_image.height,
            file_size=processed_image.file_size,
            created_at=processed_image.created_at
        )
        
        # Debug: Print the response data
        logger.info(f"🔍 Response data: {response_data.model_dump()}")
        
        return response_data
        
    except Exception as e:
        logger.error(f"❌ Error saving processed image: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history", response_model=schemas.ImageHistoryResponse)
async def get_image_history(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    image_type: str = Query(None, description="Filter by image type (restore/together)"),
    current_user: db_models.User = Depends(get_current_user)
):
    """Get user's processed image history with pagination"""
    try:
        # Build query
        query = {"user_id": current_user.id}
        if image_type:
            query["image_type"] = image_type
        
        # Get total count
        total = await db_models.ProcessedImage.find(query).count()
        
        # Get paginated results
        skip = (page - 1) * page_size
        images = await db_models.ProcessedImage.find(query).sort("-created_at").skip(skip).limit(page_size).to_list()
        
        # Convert to response schema
        image_list = [
            schemas.ProcessedImage(
                id=str(img.id),
                user_id=str(img.user_id.id),
                image_type=img.image_type,
                original_image_url=img.original_image_url,
                processed_image_url=img.processed_image_url,
                thumbnail_url=img.thumbnail_url,
                quality_target=img.quality_target,
                output_format=img.output_format,
                aspect_ratio=img.aspect_ratio,
                subject_a_url=img.subject_a_url,
                subject_b_url=img.subject_b_url,
                background_prompt=img.background_prompt,
                width=img.width,
                height=img.height,
                file_size=img.file_size,
                created_at=img.created_at
            )
            for img in images
        ]
        
        logger.info(f"✅ Retrieved {len(image_list)} images for user {current_user.email}")
        
        return schemas.ImageHistoryResponse(
            images=image_list,
            total=total,
            page=page,
            page_size=page_size
        )
        
    except Exception as e:
        logger.error(f"❌ Error retrieving image history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{image_id}")
async def delete_processed_image(
    image_id: str,
    current_user: db_models.User = Depends(get_current_user)
):
    """Delete a processed image from history"""
    try:
        # Find image
        image = await db_models.ProcessedImage.find_one(
            db_models.ProcessedImage.id == image_id
        )
        
        if not image:
            raise HTTPException(status_code=404, detail="Image not found")
        
        # Check ownership
        if str(image.user_id.id) != str(current_user.id):
            raise HTTPException(status_code=403, detail="Not authorized to delete this image")
        
        # Delete image
        await image.delete()
        
        logger.info(f"✅ Deleted image {image_id} for user {current_user.email}")
        
        return {"message": "Image deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting image: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_image_stats(
    current_user: db_models.User = Depends(get_current_user)
):
    """Get user's image processing statistics"""
    try:
        # Count by type
        restore_count = await db_models.ProcessedImage.find({
            "user_id": current_user.id,
            "image_type": "restore"
        }).count()
        
        together_count = await db_models.ProcessedImage.find({
            "user_id": current_user.id,
            "image_type": "together"
        }).count()
        
        total_count = restore_count + together_count
        
        # Get most recent image
        recent_image = await db_models.ProcessedImage.find_one(
            {"user_id": current_user.id},
            sort=[("created_at", -1)]
        )
        
        return {
            "total_images": total_count,
            "restore_count": restore_count,
            "together_count": together_count,
            "most_recent": recent_image.created_at if recent_image else None
        }
        
    except Exception as e:
        logger.error(f"❌ Error getting image stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))

