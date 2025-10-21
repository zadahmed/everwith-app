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
        # Debug: Log what we're storing
        logger.info(f"🔍 Saving image for user: {current_user.id} (type: {type(current_user.id)})")
        from bson import ObjectId, DBRef
        processed_image = db_models.ProcessedImage(
            user_id=DBRef("users", ObjectId(current_user.id)),  # Store as DBRef for consistency
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
        # Handle DBRef properly - extract the actual ID from the nested structure
        user_id_str = None
        if hasattr(processed_image.user_id, 'id'):
            user_id_str = str(processed_image.user_id.id)
        elif isinstance(processed_image.user_id, dict) and '$id' in processed_image.user_id:
            # Handle MongoDB DBRef structure: {"$ref": "users", "$id": {"$oid": "..."}}
            if isinstance(processed_image.user_id['$id'], dict) and '$oid' in processed_image.user_id['$id']:
                user_id_str = processed_image.user_id['$id']['$oid']
            else:
                user_id_str = str(processed_image.user_id['$id'])
        elif hasattr(processed_image.user_id, '__str__'):
            # Fallback if it's a DBRef or other reference type
            user_id_str = str(processed_image.user_id)
        
        response_data = schemas.ProcessedImage(
            id=str(processed_image.id),
            user_id=user_id_str,
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
        # Build query - handle DBRef structure properly
        from bson import ObjectId, DBRef
        from pymongo import MongoClient
        
        # Try DBRef approach first (this is how it's actually stored)
        query = {"user_id": DBRef("users", ObjectId(current_user.id))}
        if image_type:
            query["image_type"] = image_type
        
        # Debug: Log the query and user info
        logger.info(f"🔍 Querying for user_id: {current_user.id} (type: {type(current_user.id)})")
        logger.info(f"🔍 Query: {query}")
        
        # Get total count
        total = await db_models.ProcessedImage.find(query).count()
        logger.info(f"🔍 Found {total} images with DBRef query: {query}")
        
        # If no results with DBRef, try other approaches
        if total == 0:
            logger.info(f"🔍 No results with DBRef, trying ObjectId approach")
            query_objectid = {"user_id": ObjectId(current_user.id)}
            if image_type:
                query_objectid["image_type"] = image_type
            total = await db_models.ProcessedImage.find(query_objectid).count()
            logger.info(f"🔍 Found {total} images with ObjectId query: {query_objectid}")
            query = query_objectid
            
            # If still no results, try direct user_id
            if total == 0:
                logger.info(f"🔍 No results with ObjectId, trying direct user_id approach")
                query_direct = {"user_id": current_user.id}
                if image_type:
                    query_direct["image_type"] = image_type
                total = await db_models.ProcessedImage.find(query_direct).count()
                logger.info(f"🔍 Found {total} images with direct user_id query: {query_direct}")
                query = query_direct
        
        # Get paginated results
        skip = (page - 1) * page_size
        images = await db_models.ProcessedImage.find(query).sort("-created_at").skip(skip).limit(page_size).to_list()
        
        # Debug: Log what we found
        logger.info(f"🔍 Retrieved {len(images)} images from database")
        for i, img in enumerate(images):
            logger.info(f"🔍 Image {i+1}: id={img.id}, user_id={img.user_id}, type={img.image_type}")
        
        # Convert to response schema
        image_list = []
        for img in images:
            # Handle DBRef properly - extract the actual ID from the nested structure
            user_id_str = None
            if hasattr(img.user_id, 'id'):
                user_id_str = str(img.user_id.id)
            elif hasattr(img.user_id, 'ref') and hasattr(img.user_id, 'id'):
                user_id_str = str(img.user_id.id)
            elif isinstance(img.user_id, dict) and '$id' in img.user_id:
                if isinstance(img.user_id['$id'], dict) and '$oid' in img.user_id['$id']:
                    user_id_str = img.user_id['$id']['$oid']
                else:
                    user_id_str = str(img.user_id['$id'])
            else:
                user_id_str = str(current_user.id)  # Use current user's ID as fallback
            
            image_list.append(schemas.ProcessedImage(
                id=str(img.id),
                user_id=user_id_str,
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
            ))
        
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
        
        # Check ownership - handle different user_id formats
        user_id_str = None
        if hasattr(image.user_id, 'id'):
            user_id_str = str(image.user_id.id)
        elif hasattr(image.user_id, 'ref') and hasattr(image.user_id, 'id'):
            user_id_str = str(image.user_id.id)
        elif isinstance(image.user_id, dict) and '$id' in image.user_id:
            if isinstance(image.user_id['$id'], dict) and '$oid' in image.user_id['$id']:
                user_id_str = image.user_id['$id']['$oid']
            else:
                user_id_str = str(image.user_id['$id'])
        else:
            user_id_str = str(image.user_id)
        
        if user_id_str != str(current_user.id):
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
        # Count by type - use DBRef approach (how data is actually stored)
        from bson import ObjectId, DBRef
        
        restore_count = await db_models.ProcessedImage.find({
            "user_id": DBRef("users", ObjectId(current_user.id)),
            "image_type": "restore"
        }).count()
        
        together_count = await db_models.ProcessedImage.find({
            "user_id": DBRef("users", ObjectId(current_user.id)),
            "image_type": "together"
        }).count()
        
        # If no results, try ObjectId approach
        if restore_count == 0 and together_count == 0:
            restore_count = await db_models.ProcessedImage.find({
                "user_id": ObjectId(current_user.id),
                "image_type": "restore"
            }).count()
            
            together_count = await db_models.ProcessedImage.find({
                "user_id": ObjectId(current_user.id),
                "image_type": "together"
            }).count()
            
            # If still no results, try direct user_id
            if restore_count == 0 and together_count == 0:
                restore_count = await db_models.ProcessedImage.find({
                    "user_id": current_user.id,
                    "image_type": "restore"
                }).count()
                
                together_count = await db_models.ProcessedImage.find({
                    "user_id": current_user.id,
                    "image_type": "together"
                }).count()
        
        total_count = restore_count + together_count
        
        # Get most recent image - try DBRef first, then fallbacks
        recent_image = await db_models.ProcessedImage.find_one(
            {"user_id": DBRef("users", ObjectId(current_user.id))},
            sort=[("created_at", -1)]
        )
        
        if not recent_image:
            recent_image = await db_models.ProcessedImage.find_one(
                {"user_id": ObjectId(current_user.id)},
                sort=[("created_at", -1)]
            )
            
        if not recent_image:
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

