import asyncio
import io
import uuid
from pathlib import Path

import boto3
from botocore.exceptions import ClientError
from PIL import Image

from src.config import get_settings

settings = get_settings()

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}
MAX_UPLOAD_BYTES = 20 * 1024 * 1024  # 20 MB

THUMB_SIZE = (400, 560)   # 5:7 card
CARD_SIZE = (600, 840)
PROCESSED_SIZE = (1200, 1680)


def _get_s3_client():
    return boto3.client(
        "s3",
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_region,
    )


def _resize_and_upload(
    raw_bytes: bytes,
    garment_id: str,
) -> dict[str, str]:
    img = Image.open(io.BytesIO(raw_bytes)).convert("RGB")
    s3 = _get_s3_client()
    bucket = settings.s3_bucket_name
    base = f"garments/{garment_id}"
    urls: dict[str, str] = {}

    variants = {
        "raw": None,
        "processed": PROCESSED_SIZE,
        "card": CARD_SIZE,
        "thumb": THUMB_SIZE,
    }

    for variant, size in variants.items():
        buf = io.BytesIO()
        if size:
            resized = img.copy()
            resized.thumbnail(size, Image.LANCZOS)
            resized.save(buf, format="JPEG", quality=85, optimize=True)
        else:
            img.save(buf, format="JPEG", quality=90, optimize=True)

        buf.seek(0)
        key = f"{base}/{variant}.jpg"

        s3.upload_fileobj(
            buf,
            bucket,
            key,
            ExtraArgs={"ContentType": "image/jpeg", "CacheControl": "max-age=31536000"},
        )

        region = settings.aws_region
        urls[f"image_url_{variant}"] = (
            f"https://{bucket}.s3.{region}.amazonaws.com/{key}"
        )

    return urls


async def upload_garment_image(raw_bytes: bytes, garment_id: str | None = None) -> dict[str, str]:
    gid = garment_id or str(uuid.uuid4())
    return await asyncio.to_thread(_resize_and_upload, raw_bytes, gid)


def _extract_colors_sync(raw_bytes: bytes) -> dict:
    """Extract dominant color and palette using Pillow quantization."""
    img = Image.open(io.BytesIO(raw_bytes)).convert("RGB")
    img.thumbnail((150, 150), Image.LANCZOS)

    try:
        quantized = img.quantize(colors=8, method=Image.Quantize.MEDIANCUT)
    except Exception:
        quantized = img.quantize(colors=8)
    palette_data = quantized.getpalette()
    if not palette_data:
        return {"dominant_color": "#F5F0E8", "color_palette": []}

    colors = []
    for i in range(min(8, len(palette_data) // 3)):
        r, g, b = palette_data[i * 3 : i * 3 + 3]
        hex_val = f"#{r:02x}{g:02x}{b:02x}"
        colors.append({"hex": hex_val, "name": _approximate_color_name(r, g, b)})

    dominant = colors[0]["hex"] if colors else "#F5F0E8"
    return {"dominant_color": dominant, "color_palette": colors[:5]}


def _approximate_color_name(r: int, g: int, b: int) -> str:
    """Map RGB to a fashion-grade color name."""
    h, s, v = _rgb_to_hsv(r, g, b)

    if v < 0.2:
        return "Negro"
    if v > 0.9 and s < 0.1:
        return "Blanco"
    if s < 0.15:
        if v < 0.4:
            return "Gris oscuro"
        if v < 0.7:
            return "Gris"
        return "Gris claro"

    if 0 <= h < 15 or h >= 345:
        return "Rojo"
    if 15 <= h < 40:
        return "Naranja" if s > 0.5 else "Durazno"
    if 40 <= h < 65:
        return "Amarillo"
    if 65 <= h < 150:
        return "Verde" if s > 0.4 else "Verde salvia"
    if 150 <= h < 200:
        return "Aqua"
    if 200 <= h < 250:
        return "Azul"
    if 250 <= h < 290:
        return "Índigo"
    if 290 <= h < 345:
        return "Morado" if s > 0.4 else "Lavanda"
    return "Neutro"


def _rgb_to_hsv(r: int, g: int, b: int) -> tuple[float, float, float]:
    r, g, b = r / 255.0, g / 255.0, b / 255.0
    mx = max(r, g, b)
    mn = min(r, g, b)
    diff = mx - mn

    if diff == 0:
        h = 0.0
    elif mx == r:
        h = (60 * ((g - b) / diff) + 360) % 360
    elif mx == g:
        h = (60 * ((b - r) / diff) + 120) % 360
    else:
        h = (60 * ((r - g) / diff) + 240) % 360

    s = 0.0 if mx == 0 else diff / mx
    return h, s, mx


async def extract_colors(raw_bytes: bytes) -> dict:
    return await asyncio.to_thread(_extract_colors_sync, raw_bytes)
