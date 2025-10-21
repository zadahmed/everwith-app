import os
import io
import uuid
import requests
from typing import Optional
from fastapi import HTTPException
from PIL import Image, ImageFilter, ImageOps, ImageEnhance
import numpy as np
import boto3
from botocore.exceptions import ClientError
from app.models.schemas import RestoreRequest, TogetherRequest, JobResult, LookControls

# Configuration
BFL_API_KEY = os.getenv("BFL_API_KEY")
BFL_API_BASE = os.getenv("BFL_API_BASE", "https://api.bfl.ai/v1")
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "./outputs")

# DigitalOcean Spaces Configuration
DO_SPACES_KEY = os.getenv("DO_SPACES_KEY")
DO_SPACES_SECRET = os.getenv("DO_SPACES_SECRET")
DO_SPACES_REGION = os.getenv("DO_SPACES_REGION", "nyc3")
DO_SPACES_BUCKET = os.getenv("DO_SPACES_BUCKET")
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
        headers = {"Authorization": f"Bearer {BFL_API_KEY}"}
        r = requests.post(url, json=body, headers=headers, timeout=timeout)
        if not r.ok:
            raise HTTPException(status_code=r.status_code, detail=r.text)
        return r.json()

    @staticmethod
    def _download_image(url: str) -> Image.Image:
        """Download image from URL"""
        r = requests.get(url, timeout=60)
        if not r.ok:
            raise HTTPException(status_code=400, detail=f"Failed to download: {url}")
        return Image.open(io.BytesIO(r.content)).convert("RGBA")

    @staticmethod
    def _save_image(img: Image.Image, ext: str = "png") -> str:
        """Save image to DigitalOcean Spaces and return CDN URL"""
        fname = f"{uuid.uuid4().hex}.{ext}"
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
                        'ACL': 'public-read',  # Make publicly accessible
                        'CacheControl': 'max-age=31536000'  # Cache for 1 year
                    }
                )
                
                # Return CDN URL if available, otherwise direct Spaces URL
                if DO_SPACES_CDN_ENDPOINT:
                    return f"{DO_SPACES_CDN_ENDPOINT}/{fname}"
                else:
                    return f"https://{DO_SPACES_BUCKET}.{DO_SPACES_REGION}.digitaloceanspaces.com/{fname}"
                    
            except ClientError as e:
                print(f"❌ Failed to upload to Spaces: {e}")
                # Fall back to local storage
        
        # Fallback: Save locally (for development)
        print("⚠️ Using local storage fallback")
        fpath = os.path.join(OUTPUT_DIR, fname)
        buffer.seek(0)
        with open(fpath, 'wb') as f:
            f.write(buffer.read())
        return f"file://{os.path.abspath(fpath)}"

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
        """Call BFL Flux Kontext API for image editing"""
        url = f"{BFL_API_BASE}/flux-pro-1.0-kontext"
        body = {
            "prompt": prompt,
            "image": image_url,
            "strength": strength,
            "seed": seed,
            "output_format": out_format
        }
        data = ImageProcessingService._http_json(url, body)
        # Some deployments return list of urls, others a single url
        return data.get("output_url") or (data.get("output") or [None])[0]

    @staticmethod
    def flux_fill(image_url: str, prompt: str, mask_url: Optional[str] = None, seed: Optional[int] = None, out_format: str = "png") -> str:
        """Call BFL Flux Fill API for inpainting"""
        url = f"{BFL_API_BASE}/flux-pro-1.0-fill-finetuned"
        body = {
            "prompt": prompt,
            "image": image_url,
            "mask": mask_url,
            "seed": seed,
            "output_format": out_format
        }
        data = ImageProcessingService._http_json(url, body)
        return data.get("output_url") or (data.get("output") or [None])[0]

    @staticmethod
    def flux_ultra_background(prompt: str, seed: Optional[int] = None, aspect_ratio: str = "4:5") -> str:
        """Call BFL Flux Ultra API for background generation"""
        url = f"{BFL_API_BASE}/flux-pro-1.1-ultra"
        body = {"prompt": prompt, "seed": seed, "aspect_ratio": aspect_ratio, "raw": True}
        data = ImageProcessingService._http_json(url, body)
        return data.get("output_url") or (data.get("output") or [None])[0]

    @staticmethod
    def restore_pipeline(req: RestoreRequest) -> JobResult:
        """Process image restoration request"""
        # 1) Optional light preclean to help the model on very noisy scans
        try:
            pil = ImageProcessingService._download_image(str(req.image_url))
            pil = pil.filter(ImageFilter.MedianFilter(size=3))
            # Upload to cloud storage - now returns HTTPS URL
            temp_url = ImageProcessingService._save_image(pil, "png")
        except Exception:
            # If preclean fails, still try original
            temp_url = str(req.image_url)

        # 2) Single Flux Kontext call to recreate same look but nicer
        prompt = (
            "Restore and recreate this photo in the same composition and style. "
            "Preserve identity, clothing and lighting. Remove noise, banding and stains. "
            "Keep natural skin texture. Avoid plastic skin and avoid AI artifacts."
        )
        out_url = ImageProcessingService.flux_kontext_edit(
            image_url=temp_url,
            prompt=prompt,
            strength=0.8 if req.quality_target == "standard" else 0.9,
            seed=req.seed,
            out_format=req.output_format
        )
        if not out_url:
            raise HTTPException(status_code=502, detail="No output from Kontext")

        # 3) Optional local finishing and aspect
        try:
            img = ImageProcessingService._download_image(out_url)
            img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
            # gentle finishing
            controls = LookControls(warmth=0.05, shadows=0.05, grain=0.02)
            img = ImageProcessingService._finish_look(img, controls)
            final_url = ImageProcessingService._save_image(img, req.output_format)
        except Exception:
            # If finishing fails, at least return model output url
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
            "Preserve facial features and clothing details."
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
        try:
            img = ImageProcessingService._download_image(final_url)
            img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
            img = ImageProcessingService._finish_look(img, req.look_controls or LookControls())
            final_url = ImageProcessingService._save_image(img, "png")
        except Exception as e:
            print(f"⚠️ Finishing failed: {e}")
            # Return without finishing
        
        meta = {
            "background_src": background_url,
            "subject_a_processed": subject_a_url,
            "subject_b_processed": subject_b_url,
            "composite_url": composite_url,
            "aspect_ratio": req.aspect_ratio,
            "steps": ["remove_bg", "composite", "blend", "finish"]
        }
        return JobResult(output_url=final_url, meta=meta)
