import os
import io
import uuid
import time
import requests
from typing import Optional
from fastapi import HTTPException
from PIL import Image, ImageFilter, ImageOps, ImageEnhance
import numpy as np
import boto3
from botocore.exceptions import ClientError
from app.models.schemas import RestoreRequest, TogetherRequest, JobResult, LookControls, TimelineRequest, CelebrityRequest, ReuniteRequest, FamilyRequest

# Configuration
BFL_API_KEY = os.getenv("BFL_API_KEY")
BFL_API_BASE = os.getenv("BFL_API_BASE", "https://api.bfl.ai/v1")
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "./outputs")

# Validate BFL API key on startup
if not BFL_API_KEY:
    print("⚠️  WARNING: BFL_API_KEY not set in environment!")
else:
    print(f"✅ BFL API Key loaded...")

# DigitalOcean Spaces Configuration
DO_SPACES_KEY = os.getenv("DO_SPACES_KEY")
DO_SPACES_SECRET = os.getenv("DO_SPACES_SECRET")
DO_SPACES_REGION = os.getenv("DO_SPACES_REGION", "nyc3")
DO_SPACES_BUCKET = os.getenv("DO_SPACES_BUCKET", "everwith")
DO_SPACES_ENDPOINT = os.getenv("DO_SPACES_ENDPOINT", "https://nyc3.digitaloceanspaces.com")
DO_SPACES_CDN_ENDPOINT = os.getenv("DO_SPACES_CDN_ENDPOINT")

# Initialize DigitalOcean Spaces client (S3-compatible)
s3_client = None
if DO_SPACES_KEY and DO_SPACES_SECRET:
    s3_client = boto3.client(
        's3',
        region_name="ams3",
        endpoint_url=DO_SPACES_ENDPOINT,
        aws_access_key_id=DO_SPACES_KEY,
        aws_secret_access_key=DO_SPACES_SECRET
    )
    print(f"✅ DigitalOcean Spaces configured: {DO_SPACES_BUCKET}")
else:
    print("⚠️ DigitalOcean Spaces not configured - using local storage fallback")

# Ensure output directory exists (fallback)
os.makedirs(OUTPUT_DIR, exist_ok=True)

class ImageProcessingService:
    """Service for handling image processing operations using Black Forest Labs APIs"""
    
    @staticmethod
    def _http_json(url: str, body: dict, timeout=180):
        """Make HTTP request to BFL API"""
        if not BFL_API_KEY:
            print("❌ BFL_API_KEY is not set!")
            raise HTTPException(status_code=500, detail="BFL API key not configured")
        
        headers = {
            "x-key": BFL_API_KEY,  # BFL uses x-key header, not Bearer
            "Content-Type": "application/json"
        }
        print(f"🔵 BFL API Request: {url}")
        print(f"📦 Body: {body}")
        print(f"🔑 Using BFL API Key: {BFL_API_KEY[:20]}..." if BFL_API_KEY else "❌ No API key!")
        
        r = requests.post(url, json=body, headers=headers, timeout=timeout)
        
        print(f"📥 Response Status: {r.status_code}")
        print(f"📥 Response Headers: {dict(r.headers)}")
        
        if not r.ok:
            print(f"❌ BFL API Error {r.status_code}: {r.text}")
            raise HTTPException(status_code=r.status_code, detail=f"BFL API Error: {r.text}")
        print(f"✅ BFL API Success")
        return r.json()

    @staticmethod
    def _download_image(url: str) -> Image.Image:
        """Download image from URL"""
        r = requests.get(url, timeout=60)
        if not r.ok:
            raise HTTPException(status_code=400, detail=f"Failed to download: {url}")
        return Image.open(io.BytesIO(r.content)).convert("RGBA")

    @staticmethod
    def migrate_bfl_url_to_spaces(bfl_url: str, ext: str = "png") -> str:
        """
        Download image from BFL URL and upload to Digital Ocean Spaces.
        Returns the permanent Spaces URL.
        """
        try:
            print(f"🔄 Migrating BFL URL to Spaces: {bfl_url}")
            
            # Download image from BFL
            img = ImageProcessingService._download_image(bfl_url)
            
            # Upload to Digital Ocean Spaces
            permanent_url = ImageProcessingService._save_image(img, ext)
            
            print(f"✅ Successfully migrated BFL URL to Spaces: {permanent_url}")
            return permanent_url
            
        except Exception as e:
            print(f"❌ Failed to migrate BFL URL {bfl_url}: {e}")
            # Return original URL as fallback
            return bfl_url

    @staticmethod
    def _save_image(img: Image.Image, ext: str = "png") -> str:
        """Save image to DigitalOcean Spaces and return CDN URL"""
        fname = f"everwith/{uuid.uuid4().hex}.{ext}"  # Add everwith/ prefix
        buffer = io.BytesIO()
        
        # Prepare image for saving
        save_params = {}
        if ext.lower() in ["jpg", "jpeg"]:
            img = img.convert("RGB")
            img.save(buffer, format='JPEG', quality=92)
            content_type = 'image/jpeg'
        else:
            img.save(buffer, format='PNG')
            content_type = 'image/png'
        
        buffer.seek(0)
        
        # Upload to DigitalOcean Spaces if configured
        if s3_client and DO_SPACES_BUCKET:
            try:
                s3_client.upload_fileobj(
                    buffer,
                    DO_SPACES_BUCKET,
                    fname,
                    ExtraArgs={
                        'ContentType': content_type,
                        'ACL': 'public-read',  # Public for fast CDN access
                        'CacheControl': 'max-age=31536000'  # Cache for 1 year
                    }
                )
                
                # Return CDN URL for authenticated access
                if DO_SPACES_CDN_ENDPOINT:
                    return f"{DO_SPACES_CDN_ENDPOINT}/{fname}"
                else:
                    return f"https://{DO_SPACES_BUCKET}.{DO_SPACES_REGION}.digitaloceanspaces.com/{fname}"
                    
            except ClientError as e:
                print(f"❌ Failed to upload to Spaces: {e}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to upload to DigitalOcean Spaces: {str(e)}. Cloud storage is required for image processing."
                )
        
        # Fallback: Spaces not configured at all
        print("⚠️⚠️⚠️ CRITICAL ERROR: DigitalOcean Spaces not configured!")
        print("⚠️ Local file:// URLs cannot be used with BFL API")
        print("⚠️ Please configure in .env:")
        print("⚠️   DO_SPACES_KEY=your-key")
        print("⚠️   DO_SPACES_SECRET=your-secret")
        print("⚠️   DO_SPACES_BUCKET=your-bucket-name")
        
        raise HTTPException(
            status_code=500,
            detail="DigitalOcean Spaces not configured. Cloud storage is required for image processing. Please configure DO_SPACES_KEY, DO_SPACES_SECRET, and DO_SPACES_BUCKET in your .env file."
        )

    @staticmethod
    def _apply_aspect(img: Image.Image, target: str) -> Image.Image:
        """Apply aspect ratio transformation to image"""
        if target == "original":
            return img
        ratios = {"4:5": 4/5, "1:1": 1/1, "16:9": 16/9}
        if target not in ratios:
            return img
        tr = ratios[target]
        w, h = img.size
        cr = w / h
        if abs(cr - tr) < 1e-3:
            return img
        # letterbox with transparency to preserve content
        if tr > cr:
            new_w = w
            new_h = int(w / tr)
        else:
            new_h = h
            new_w = int(h * tr)
        img_cropped = ImageOps.fit(img, (new_w, new_h), Image.LANCZOS, bleed=0.0, centering=(0.5, 0.5))
        return img_cropped

    @staticmethod
    def _finish_look(img: Image.Image, controls: LookControls) -> Image.Image:
        """Apply finishing touches to image"""
        # Warmth: simple white-balance tilt via color balance
        if controls.warmth != 0:
            r, g, b, a = img.split()
            r = ImageEnhance.Brightness(r).enhance(1 + controls.warmth * 0.5)
            b = ImageEnhance.Brightness(b).enhance(1 - controls.warmth * 0.5)
            img = Image.merge("RGBA", (r, g, b, a))
        
        # Shadows: lift shadows with a soft curve (approximate using autocontrast + blend)
        if controls.shadows != 0:
            lifted = ImageOps.autocontrast(img, cutoff=0)
            img = Image.blend(img, lifted, min(max(controls.shadows, 0.0), 1.0))
        
        # Grain: overlay monochrome noise
        if controls.grain > 0:
            arr = np.array(img)
            noise = (np.random.randn(*arr.shape[:2]) * 255 * 0.08).astype("int16")
            for c in range(3):
                arr[..., c] = np.clip(arr[..., c].astype("int16") + noise, 0, 255).astype("uint8")
            img = Image.fromarray(arr, mode="RGBA")
        
        return img

    @staticmethod
    def flux_kontext_edit(image_url: str, prompt: str, strength: float = 0.8, seed: Optional[int] = None, out_format: str = "png") -> str:
        """Call BFL Flux Kontext API for image editing/restoration (async with polling)"""
        
        # CRITICAL: BFL requires HTTPS URLs - file:// will NOT work!
        if image_url.startswith("file://"):
            raise HTTPException(
                status_code=500, 
                detail="Cannot use local file:// URLs with BFL API. Please configure DigitalOcean Spaces (DO_SPACES_KEY, DO_SPACES_SECRET, DO_SPACES_BUCKET in .env)"
            )
        
        # Step 1: Create the job
        url = f"{BFL_API_BASE}/flux-kontext-pro"
        body = {
            "prompt": prompt,
            "input_image": image_url,  # FIXED: BFL uses "input_image" not "image"
            "strength": strength,
            "output_format": out_format
        }
        if seed:
            body["seed"] = seed
        
        print(f"\n📤 Creating BFL job...")
        print(f"🌐 API Endpoint: {url}")
        print(f"🔗 YOUR Image URL being sent: {image_url}")
        print(f"📝 Prompt: {prompt[:100]}...")
        print(f"💪 Strength: {strength}")
        
        response = ImageProcessingService._http_json(url, body)
        
        # Step 2: Get job ID and polling URL
        job_id = response.get("id")
        polling_url = response.get("polling_url") or f"{BFL_API_BASE}/get_result?id={job_id}"
        
        print(f"✅ Job created: {job_id}")
        print(f"📊 Polling URL: {polling_url}")
        
        # Step 3: Poll for result
        return ImageProcessingService._poll_for_result(polling_url, job_id)
    
    @staticmethod
    def _poll_for_result(polling_url: str, job_id: str, max_attempts: int = 120, interval: float = 0.5) -> str:
        """Poll BFL API for job completion (matches BFL documentation pattern)"""
        if not BFL_API_KEY:
            raise HTTPException(status_code=500, detail="BFL API key not configured")
        
        headers = {
            "x-key": BFL_API_KEY,
            "accept": "application/json"
        }
        
        for attempt in range(max_attempts):
            time.sleep(interval)
            
            print(f"⏳ Polling attempt {attempt + 1}/{max_attempts}...")
            
            try:
                r = requests.get(polling_url, headers=headers, timeout=30)
                
                if not r.ok:
                    print(f"❌ Polling error {r.status_code}: {r.text}")
                    raise HTTPException(status_code=r.status_code, detail=f"Polling failed: {r.text}")
                
                result = r.json()
                status = result.get("status")
                
                print(f"📊 Job status: {status}")
                
                if status == "Ready":
                    # Extract image URL from result
                    result_url = result.get("result", {}).get("sample")
                    if result_url:
                        print(f"✅ Job complete! Image ready: {result_url}")
                        return result_url
                    else:
                        print(f"❌ Job ready but no result URL found: {result}")
                        raise HTTPException(status_code=500, detail="No result URL in response")
                
                elif status in ["Error", "Failed"]:
                    error_msg = result.get("error") or result.get("message", "Unknown error")
                    print(f"❌ Generation failed: {result}")
                    raise HTTPException(status_code=500, detail=f"BFL job failed: {error_msg}")
                
                elif status == "Content Moderated":
                    print(f"🚫 Content moderation triggered: {result}")
                    raise HTTPException(status_code=400, detail="Image content was flagged by moderation system. Please try a different image.")
                
                # Status is Pending/Processing - continue polling
                
            except requests.exceptions.RequestException as e:
                print(f"⚠️ Request error during polling: {e}")
                if attempt == max_attempts - 1:
                    raise HTTPException(status_code=500, detail=f"Polling request failed: {str(e)}")
                # Otherwise continue polling
        
        # Max attempts reached
        print(f"❌ Polling timeout after {max_attempts * interval} seconds")
        raise HTTPException(status_code=504, detail="Job processing timeout")

    @staticmethod
    def flux_fill(image_url: str, prompt: str, mask_url: Optional[str] = None, seed: Optional[int] = None, out_format: str = "png") -> str:
        """Call BFL Flux Fill API for inpainting"""
        url = f"{BFL_API_BASE}/flux-pro-1.0-fill-finetuned"
        body = {
            "prompt": prompt,
            "input_image": image_url,  # FIXED: BFL uses "input_image"
            "mask": mask_url,
            "seed": seed,
            "output_format": out_format
        }
        data = ImageProcessingService._http_json(url, body)
        return data.get("output_url") or (data.get("output") or [None])[0]

    @staticmethod
    def flux_ultra_background(prompt: str, seed: Optional[int] = None, aspect_ratio: str = "4:5") -> str:
        """Call BFL Flux Ultra API for background generation (async with polling)"""
        url = f"{BFL_API_BASE}/flux-pro-1.1-ultra"
        body = {
            "prompt": prompt,
            "aspect_ratio": aspect_ratio,
            "raw": True
        }
        if seed:
            body["seed"] = seed
        
        print(f"📤 Creating BFL Ultra background job...")
        response = ImageProcessingService._http_json(url, body)
        
        job_id = response.get("id")
        polling_url = response.get("polling_url") or f"{BFL_API_BASE}/get_result?id={job_id}"
        
        print(f"✅ Background job created: {job_id}")
        
        return ImageProcessingService._poll_for_result(polling_url, job_id)

    @staticmethod
    def restore_pipeline(req: RestoreRequest) -> JobResult:
        """Process image restoration request"""
        print(f"\n{'='*60}")
        print(f"🎯 RESTORE PIPELINE STARTED")
        print(f"📥 Input image URL from upload: {req.image_url}")
        print(f"{'='*60}\n")
        
        # Use the uploaded HTTPS URL directly - no need to download and re-upload!
        image_url = str(req.image_url)
        
        # Verify it's an HTTPS URL that BFL can access
        if not image_url.startswith("https://"):
            print(f"❌ ERROR: Image URL must be HTTPS, got: {image_url}")
            raise HTTPException(
                status_code=400,
                detail=f"Image URL must be HTTPS (from DigitalOcean Spaces). Got: {image_url[:50]}..."
            )
        
        print(f"✅ Using uploaded HTTPS URL directly: {image_url}")
        
        # CRITICAL: Verify the URL is actually accessible before sending to BFL
        print(f"\n🔍 TESTING: Can we access this URL?")
        try:
            test_response = requests.head(image_url, timeout=5)
            print(f"✅ URL is accessible! Status: {test_response.status_code}")
            print(f"📦 Content-Type: {test_response.headers.get('Content-Type')}")
            print(f"📏 Content-Length: {test_response.headers.get('Content-Length')} bytes")
        except Exception as e:
            print(f"❌ ERROR: Cannot access URL! BFL won't be able to access it either!")
            print(f"❌ Error: {e}")
            raise HTTPException(
                status_code=400,
                detail=f"Uploaded image URL is not publicly accessible: {str(e)}. Please check DigitalOcean Spaces ACL settings."
            )
        
        print(f"\n📤 Sending YOUR image to BFL API...")
        print(f"🔗 Image URL being sent to BFL: {image_url}")
        print(f"💪 Strength: {0.8 if req.quality_target == 'standard' else 0.9}")
        
        # Send directly to BFL Kontext for restoration
        prompt = (
            "Restore and enhance this photo in the same composition and style. "
            "Preserve identity, clothing and lighting. Remove noise, banding and stains. "
            "Keep natural appearance and texture. Avoid plastic look and avoid AI artifacts."
        )
        print(f"📝 Prompt: {prompt}")
        
        out_url = ImageProcessingService.flux_kontext_edit(
            image_url=image_url,
            prompt=prompt,
            strength=0.8 if req.quality_target == "standard" else 0.9,
            seed=req.seed,
            out_format=req.output_format
        )
        if not out_url:
            raise HTTPException(status_code=502, detail="No output from Kontext")
        
        print(f"✅ BFL returned restored image URL: {out_url}")

        # Always migrate BFL URL to permanent storage first
        if "bfl.ai" in out_url:
            print(f"🔗 Detected BFL URL, migrating to Spaces...")
            # Download and migrate
            img = ImageProcessingService._download_image(out_url)
            final_url = ImageProcessingService.migrate_bfl_url_to_spaces(out_url, req.output_format)
            
            # Then apply finishing touches if needed
            try:
                img_processed = ImageProcessingService._download_image(final_url)
                img_processed = ImageProcessingService._apply_aspect(img_processed, req.aspect_ratio)
                controls = LookControls(warmth=0.05, shadows=0.05, grain=0.02)
                img_processed = ImageProcessingService._finish_look(img_processed, controls)
                final_url = ImageProcessingService._save_image(img_processed, req.output_format)
            except Exception as e:
                print(f"⚠️ Finishing touches skipped: {e}")
        else:
            # Already a Spaces URL, just apply finishing
            try:
                img = ImageProcessingService._download_image(out_url)
                img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
                controls = LookControls(warmth=0.05, shadows=0.05, grain=0.02)
                img = ImageProcessingService._finish_look(img, controls)
                final_url = ImageProcessingService._save_image(img, req.output_format)
            except Exception as e:
                print(f"⚠️ Finishing failed: {e}")
                final_url = out_url

        meta = {
            "steps": ["preclean", "flux_kontext", "finish"],
            "quality_target": req.quality_target,
            "aspect_ratio": req.aspect_ratio
        }
        return JobResult(output_url=final_url, meta=meta)

    @staticmethod
    def together_pipeline(req: TogetherRequest) -> JobResult:
        """Process together photo creation request - FIXED VERSION"""
        
        # Step 1: Download and process subject images
        print("📸 Step 1: Downloading subject images...")
        subject_a = ImageProcessingService._download_image(str(req.subject_a_url))
        subject_b = ImageProcessingService._download_image(str(req.subject_b_url))
        
        # Step 2: Remove backgrounds from subjects using rembg
        print("🎭 Step 2: Removing backgrounds from subjects...")
        try:
            import rembg
            subject_a_nobg = rembg.remove(subject_a)
            subject_b_nobg = rembg.remove(subject_b)
        except Exception as e:
            print(f"⚠️ Background removal failed: {e}")
            # Fallback: use original images
            subject_a_nobg = subject_a
            subject_b_nobg = subject_b
        
        # Save subjects without background
        subject_a_url = ImageProcessingService._save_image(subject_a_nobg, "png")
        subject_b_url = ImageProcessingService._save_image(subject_b_nobg, "png")
        
        # Create masks from alpha channel
        def create_mask(img_with_alpha):
            """Extract alpha channel as mask"""
            if img_with_alpha.mode == 'RGBA':
                mask = img_with_alpha.split()[-1]  # Get alpha channel
            else:
                # No alpha channel, create white mask
                mask = Image.new('L', img_with_alpha.size, 255)
            return mask
        
        mask_a = create_mask(subject_a_nobg)
        mask_b = create_mask(subject_b_nobg)
        
        # Save masks
        mask_a_url = ImageProcessingService._save_image(mask_a, "png")
        mask_b_url = ImageProcessingService._save_image(mask_b, "png")
        
        # Step 3: Generate or select background
        print("🌄 Step 3: Generating/selecting background...")
        if req.background.mode == "gallery":
            if not req.background.scene_id:
                raise HTTPException(status_code=400, detail="scene_id required for gallery mode")
            background_url = req.background.scene_id  # Pre-made background
        else:
            prompt = req.background.prompt or "soft warm tribute background with gentle bokeh"
            background_url = ImageProcessingService.flux_ultra_background(
                prompt=prompt,
                seed=req.seed,
                aspect_ratio=req.aspect_ratio
            )
        
        if not background_url:
            raise HTTPException(status_code=502, detail="Failed to generate background")
        
        # Step 4: Composite subjects onto background
        print("🖼️ Step 4: Compositing subjects onto background...")
        background = ImageProcessingService._download_image(background_url)
        
        # Resize subjects to fit nicely
        bg_w, bg_h = background.size
        max_subject_height = int(bg_h * 0.65)  # Subjects take up 65% of height
        
        # Resize subject A
        a_ratio = subject_a_nobg.size[0] / subject_a_nobg.size[1]
        a_new_h = max_subject_height
        a_new_w = int(a_new_h * a_ratio)
        subject_a_resized = subject_a_nobg.resize((a_new_w, a_new_h), Image.Resampling.LANCZOS)
        
        # Resize subject B
        b_ratio = subject_b_nobg.size[0] / subject_b_nobg.size[1]
        b_new_h = max_subject_height
        b_new_w = int(b_new_h * b_ratio)
        subject_b_resized = subject_b_nobg.resize((b_new_w, b_new_h), Image.Resampling.LANCZOS)
        
        # Position subjects (side by side, centered)
        gap = 50  # 50px gap between subjects
        total_width = a_new_w + b_new_w + gap
        start_x = (bg_w - total_width) // 2
        start_y = (bg_h - max_subject_height) // 2
        
        # Composite
        composite = background.copy().convert('RGBA')
        composite.paste(subject_a_resized, (start_x, start_y), subject_a_resized)
        composite.paste(subject_b_resized, (start_x + a_new_w + gap, start_y), subject_b_resized)
        
        # Save composited image
        composite_url = ImageProcessingService._save_image(composite, "png")
        
        # Step 5: Use Flux Kontext to blend edges and harmonize lighting
        print("✨ Step 5: Blending and harmonizing...")
        blend_prompt = (
            "Seamlessly blend the subjects into the background. "
            "Match lighting and perspective. Add subtle shadows and reflections. "
            "Make it look natural like they were always there together. "
            "Preserve facial details and clothing."
        )
        
        try:
            final_url = ImageProcessingService.flux_kontext_edit(
                image_url=composite_url,
                prompt=blend_prompt,
                strength=0.35,  # Light touch to preserve subjects
                seed=req.seed,
                out_format="png"
            )
        except Exception as e:
            print(f"⚠️ Blending failed: {e}, using composite")
            final_url = composite_url  # Fallback to composite without blending
        
        if not final_url:
            final_url = composite_url
        
        # Step 6: Apply aspect ratio and finishing touches
        print("🎨 Step 6: Applying finishing touches...")
        # Always migrate BFL URLs first
        if final_url and "bfl.ai" in final_url:
            print(f"🔗 Detected BFL URL, migrating to Spaces...")
            final_url = ImageProcessingService.migrate_bfl_url_to_spaces(final_url, "png")
        else:
            try:
                img = ImageProcessingService._download_image(final_url)
                img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
                img = ImageProcessingService._finish_look(img, req.look_controls or LookControls())
                final_url = ImageProcessingService._save_image(img, "png")
            except Exception as e:
                print(f"⚠️ Finishing failed: {e}, using: {final_url}")
        
        meta = {
            "background_src": background_url,
            "subject_a_processed": subject_a_url,
            "subject_b_processed": subject_b_url,
            "composite_url": composite_url,
            "aspect_ratio": req.aspect_ratio,
            "steps": ["remove_bg", "composite", "blend", "finish"]
        }
        return JobResult(output_url=final_url, meta=meta)

    @staticmethod
    def timeline_pipeline(req: TimelineRequest) -> JobResult:
        """Process timeline transformation request"""
        print(f"\n{'='*60}")
        print(f"🎯 TIMELINE PIPELINE STARTED")
        print(f"📥 Input image URL: {req.image_url}")
        print(f"🎂 Target age: {req.target_age}")
        print(f"{'='*60}\n")
        
        image_url = str(req.image_url)
        
        # Age-specific prompts
        age_prompts = {
            "young": "Make this person look younger, as they would have appeared 20-30 years ago. Show them with vibrant appearance, fewer wrinkles, and youthful energy while keeping their identity.",
            "current": "Enhance this photo with professional lighting and clarity while maintaining their current age and appearance.",
            "old": "Show how this person might look with age, adding gentle wisdom lines and silver hair, while preserving their core features and personality."
        }
        
        prompt = age_prompts.get(req.target_age, age_prompts["current"])
        
        out_url = ImageProcessingService.flux_kontext_edit(
            image_url=image_url,
            prompt=prompt,
            strength=0.7,
            seed=req.seed,
            out_format=req.output_format
        )
        
        # Always migrate BFL URL to permanent storage
        if "bfl.ai" in out_url:
            print(f"🔗 Detected BFL URL, migrating to Spaces...")
            final_url = ImageProcessingService.migrate_bfl_url_to_spaces(out_url, req.output_format)
        else:
            # Apply aspect ratio and finishing if not already from Spaces
            try:
                img = ImageProcessingService._download_image(out_url)
                img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
                final_url = ImageProcessingService._save_image(img, req.output_format)
            except Exception:
                print(f"⚠️ Failed to process URL, using directly: {out_url}")
                final_url = out_url
        
        meta = {
            "target_age": req.target_age,
            "aspect_ratio": req.aspect_ratio,
            "steps": ["timeline_transform", "finish"]
        }
        return JobResult(output_url=final_url, meta=meta)

    @staticmethod
    def celebrity_pipeline(req: CelebrityRequest) -> JobResult:
        """Process celebrity transformation request"""
        print(f"\n{'='*60}")
        print(f"🎯 CELEBRITY PIPELINE STARTED")
        print(f"📥 Input image URL: {req.image_url}")
        print(f"⭐ Celebrity style: {req.celebrity_style}")
        print(f"{'='*60}\n")
        
        image_url = str(req.image_url)
        
        # Celebrity style prompts
        style_prompts = {
            "movie_star": "Transform this into a glamorous movie star photo with professional lighting, smooth appearance, elegant styling, and Hollywood-quality polish while preserving the person's features.",
            "royal": "Give this photo a royal elegance treatment with refined lighting, sophisticated styling, and regal composition while maintaining the person's appearance.",
            "vintage_glamour": "Apply a vintage Hollywood glamour treatment with soft focus, classic black and white or sepia tones, and timeless elegance.",
            "modern_celebrity": "Create a modern celebrity look with high-fashion lighting, editorial styling, and magazine-quality polish."
        }
        
        prompt = style_prompts.get(req.celebrity_style, style_prompts["movie_star"])
        
        out_url = ImageProcessingService.flux_kontext_edit(
            image_url=image_url,
            prompt=prompt,
            strength=0.75,
            seed=req.seed,
            out_format=req.output_format
        )
        
        # Always migrate BFL URL to permanent storage
        if "bfl.ai" in out_url:
            print(f"🔗 Detected BFL URL, migrating to Spaces...")
            final_url = ImageProcessingService.migrate_bfl_url_to_spaces(out_url, req.output_format)
        else:
            # Apply aspect ratio and finishing if not already from Spaces
            try:
                img = ImageProcessingService._download_image(out_url)
                img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
                controls = LookControls(warmth=0.1, shadows=0.1, grain=0.01)
                img = ImageProcessingService._finish_look(img, controls)
                final_url = ImageProcessingService._save_image(img, req.output_format)
            except Exception as e:
                print(f"⚠️ Failed to process URL: {e}, using directly: {out_url}")
                final_url = out_url
        
        meta = {
            "celebrity_style": req.celebrity_style,
            "aspect_ratio": req.aspect_ratio,
            "steps": ["celebrity_transform", "finish"]
        }
        return JobResult(output_url=final_url, meta=meta)

    @staticmethod
    def reunite_pipeline(req: ReuniteRequest) -> JobResult:
        """Process reunite photo request - simplified together flow"""
        print(f"\n{'='*60}")
        print(f"🎯 REUNITE PIPELINE STARTED")
        print(f"{'='*60}\n")
        
        # This is similar to together_pipeline but with emotional context
        # Download and process subjects
        subject_a = ImageProcessingService._download_image(str(req.image_a_url))
        subject_b = ImageProcessingService._download_image(str(req.image_b_url))
        
        # Remove backgrounds
        try:
            import rembg
            subject_a_nobg = rembg.remove(subject_a)
            subject_b_nobg = rembg.remove(subject_b)
        except Exception:
            subject_a_nobg = subject_a
            subject_b_nobg = subject_b
        
        # Save subjects
        subject_a_url = ImageProcessingService._save_image(subject_a_nobg, "png")
        subject_b_url = ImageProcessingService._save_image(subject_b_nobg, "png")
        
        # Generate reunite background
        background_prompt = req.background_prompt or "warm emotional background with soft lighting perfect for a reunification moment"
        background_url = ImageProcessingService.flux_ultra_background(
            prompt=background_prompt,
            seed=req.seed,
            aspect_ratio=req.aspect_ratio
        )
        
        # Composite
        background = ImageProcessingService._download_image(background_url)
        bg_w, bg_h = background.size
        max_height = int(bg_h * 0.6)
        
        # Resize and position subjects
        a_new_h = max_height
        a_new_w = int(a_new_h * (subject_a_nobg.size[0] / subject_a_nobg.size[1]))
        subject_a_resized = subject_a_nobg.resize((a_new_w, a_new_h), Image.Resampling.LANCZOS)
        
        b_new_h = max_height
        b_new_w = int(b_new_h * (subject_b_nobg.size[0] / subject_b_nobg.size[1]))
        subject_b_resized = subject_b_nobg.resize((b_new_w, b_new_h), Image.Resampling.LANCZOS)
        
        # Position subjects together
        gap = 30
        total_width = a_new_w + b_new_w + gap
        start_x = (bg_w - total_width) // 2
        start_y = (bg_h - max_height) // 2
        
        composite = background.copy().convert('RGBA')
        composite.paste(subject_a_resized, (start_x, start_y), subject_a_resized)
        composite.paste(subject_b_resized, (start_x + a_new_w + gap, start_y), subject_b_resized)
        
        composite_url = ImageProcessingService._save_image(composite, "png")
        
        # Blend harmoniously
        blend_prompt = "Create a touching reunion moment with warm lighting. Make it look natural as if they've always been together, with emotional depth and warmth."
        
        try:
            final_url = ImageProcessingService.flux_kontext_edit(
                image_url=composite_url,
                prompt=blend_prompt,
                strength=0.35,
                seed=req.seed,
                out_format="png"
            )
        except Exception:
            final_url = composite_url
        
        # Finish - always migrate BFL URLs
        if final_url and "bfl.ai" in final_url:
            print(f"🔗 Detected BFL URL in final step, migrating to Spaces...")
            final_url = ImageProcessingService.migrate_bfl_url_to_spaces(final_url, req.output_format)
        else:
            try:
                img = ImageProcessingService._download_image(final_url)
                img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
                final_url = ImageProcessingService._save_image(img, req.output_format)
            except Exception as e:
                print(f"⚠️ Failed to finish processing: {e}, using: {final_url}")
                # final_url already set
        
        meta = {
            "background_prompt": background_prompt,
            "aspect_ratio": req.aspect_ratio,
            "steps": ["reunite", "composite", "blend", "finish"]
        }
        return JobResult(output_url=final_url, meta=meta)

    @staticmethod
    def family_pipeline(req: FamilyRequest) -> JobResult:
        """Process family photo request"""
        print(f"\n{'='*60}")
        print(f"🎯 FAMILY PIPELINE STARTED")
        print(f"📥 Images count: {len(req.images)}")
        print(f"🎨 Style: {req.style}")
        print(f"{'='*60}\n")
        
        if len(req.images) == 0:
            raise HTTPException(status_code=400, detail="At least one image required")
        
        # For single image, just enhance it
        if len(req.images) == 1:
            image_url = req.images[0]
            
            if req.style == "enhanced":
                prompt = "Enhance this family photo with professional lighting, clarity, and warmth. Make it look polished and timeless while preserving authentic moments and genuine emotions."
            else:
                prompt = "Restore and enhance this family photo with professional quality, keeping it natural and authentic."
            
            out_url = ImageProcessingService.flux_kontext_edit(
                image_url=image_url,
                prompt=prompt,
                strength=0.7,
                seed=req.seed,
                out_format=req.output_format
            )
            
            # Always migrate BFL URL to permanent storage
            if "bfl.ai" in out_url:
                print(f"🔗 Detected BFL URL, migrating to Spaces...")
                final_url = ImageProcessingService.migrate_bfl_url_to_spaces(out_url, req.output_format)
            else:
                try:
                    img = ImageProcessingService._download_image(out_url)
                    img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
                    final_url = ImageProcessingService._save_image(img, req.output_format)
                except Exception as e:
                    print(f"⚠️ Failed to process URL: {e}, using directly: {out_url}")
                    final_url = out_url
            
            meta = {
                "style": req.style,
                "aspect_ratio": req.aspect_ratio,
                "steps": ["enhance", "finish"]
            }
            return JobResult(output_url=final_url, meta=meta)
        
        # For multiple images, create a composite
        elif req.style == "collage":
            # Download all images
            images = [ImageProcessingService._download_image(img_url) for img_url in req.images]
            
            # Resize to similar size
            target_size = min(min(img.size for img in images))
            resized_images = [img.resize((target_size, target_size), Image.Resampling.LANCZOS) for img in images]
            
            # Create grid layout
            cols = 2 if len(resized_images) <= 4 else 3
            rows = (len(resized_images) + cols - 1) // cols
            composite = Image.new('RGB', (cols * target_size, rows * target_size), 'white')
            
            for i, img in enumerate(resized_images):
                row = i // cols
                col = i % cols
                x = col * target_size
                y = row * target_size
                composite.paste(img.convert('RGB'), (x, y))
            
            final_url = ImageProcessingService._save_image(composite, req.output_format)
            
            meta = {
                "style": "collage",
                "image_count": len(req.images),
                "aspect_ratio": req.aspect_ratio,
                "steps": ["collage", "finish"]
            }
            return JobResult(output_url=final_url, meta=meta)
        
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported style for multiple images: {req.style}")
