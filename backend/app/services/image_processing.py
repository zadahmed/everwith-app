import os
import io
import uuid
import requests
from typing import Optional
from fastapi import HTTPException
from PIL import Image, ImageFilter, ImageOps, ImageEnhance
import numpy as np
from app.models.schemas import RestoreRequest, TogetherRequest, JobResult, LookControls

# Configuration
BFL_API_KEY = os.getenv("BFL_API_KEY", "YOUR_BFL_KEY")
BFL_API_BASE = os.getenv("BFL_API_BASE", "https://api.bfl.ai/v1")
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "./outputs")

# Ensure output directory exists
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
        """Save image to local storage and return file path"""
        fname = f"{uuid.uuid4().hex}.{ext}"
        fpath = os.path.join(OUTPUT_DIR, fname)
        save_params = {}
        if ext.lower() == "jpg":
            img = img.convert("RGB")
            save_params["quality"] = 92
        img.save(fpath, **save_params)
        # In production, upload to S3 or GCS and return a signed URL
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
            temp_path = ImageProcessingService._save_image(pil, "png")
            temp_url = temp_path  # in prod, upload to S3 and use https url
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
        """Process together photo creation request"""
        # 1) Background choice
        if req.background.mode == "gallery":
            if not req.background.scene_id:
                raise HTTPException(status_code=400, detail="scene_id required for gallery mode")
            # In production, resolve scene_id to a hosted background URL
            # For now, treat scene_id as a direct URL if you store gallery online
            background_url = req.background.scene_id
        else:
            prompt = req.background.prompt or "soft warm tribute background with gentle bokeh"
            background_url = ImageProcessingService.flux_ultra_background(prompt, seed=req.seed, aspect_ratio=req.aspect_ratio) if req.background.use_ultra else ImageProcessingService.flux_kontext_edit(
                image_url="https://picsum.photos/1024/1280",  # seed plate you control
                prompt=prompt,
                strength=0.9,
                seed=req.seed,
                out_format="png"
            )

        if not background_url:
            raise HTTPException(status_code=502, detail="Failed to prepare background")

        # 2) Place subjects with Fill. Strategy: two quick passes so Fill can harmonize each subject.
        # First pass: place A
        place_a_prompt = (
            "Place and blend subject A naturally into the scene. "
            "Match lighting and perspective. Add soft contact shadows. Keep clothing and identity."
        )
        out1_url = ImageProcessingService.flux_fill(
            image_url=background_url,
            prompt=place_a_prompt,
            mask_url=str(req.subject_a_mask_url) if req.subject_a_mask_url else None,
            seed=req.seed,
            out_format="png"
        )
        if not out1_url:
            raise HTTPException(status_code=502, detail="Fill failed for subject A")

        # Second pass: place B
        place_b_prompt = (
            "Place and blend subject B next to subject A naturally. "
            "Match lighting and perspective. Subtle film grain. Preserve identity."
        )
        out2_url = ImageProcessingService.flux_fill(
            image_url=out1_url,
            prompt=place_b_prompt,
            mask_url=str(req.subject_b_mask_url) if req.subject_b_mask_url else None,
            seed=req.seed,
            out_format="png"
        )
        if not out2_url:
            raise HTTPException(status_code=502, detail="Fill failed for subject B")

        # 3) Aspect and finishing
        try:
            img = ImageProcessingService._download_image(out2_url)
            img = ImageProcessingService._apply_aspect(img, req.aspect_ratio)
            img = ImageProcessingService._finish_look(img, req.look_controls or LookControls())
            final_url = ImageProcessingService._save_image(img, "png")
        except Exception:
            final_url = out2_url

        meta = {
            "background_src": background_url,
            "aspect_ratio": req.aspect_ratio,
            "steps": ["background", "fill_A", "fill_B", "finish"]
        }
        return JobResult(output_url=final_url, meta=meta)
