"""
AI processing pipeline for garments.

States: pending_upload → queued → processing → analyzing → complete | failed

Runs as a FastAPI BackgroundTask. No Celery required for MVP; swap entrypoint
for a Celery task later by wrapping `process_garment` in a @celery_app.task.
"""
import base64
import json
import logging
import traceback
from datetime import datetime, timezone

import anthropic
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.config import get_settings
from src.core.database import AsyncSessionLocal
from src.core.storage import extract_colors, upload_garment_image
from src.models.garment import Garment

log = logging.getLogger(__name__)
settings = get_settings()

_CLAUDE_MODEL = "claude-haiku-4-5"

_SYSTEM_PROMPT = """You are a professional fashion AI assistant for Crayoli, a premium wardrobe platform.
Analyze the clothing item in the image and respond ONLY with valid JSON matching the schema below.
Be precise and use the fashion vocabulary that matches a premium editorial aesthetic.

Schema:
{
  "category": "<tops|bottoms|dresses|outerwear|shoes|bags|accessories>",
  "subcategory": "<e.g. blusa, pantalón de vestir, vestido midi, blazer, sneakers, bolso tote>",
  "ai_style_label": "<editorial one-liner, e.g. 'Relaxed linen ease'>",
  "style_tags": ["<tag1>", "<tag2>", "<tag3>"],
  "formality": <1-5 integer, 1=muy casual, 5=muy formal>,
  "seasons": ["<spring|summer|fall|winter>"],
  "occasions": ["<casual|office|formal|sport|travel|evening>"],
  "pattern": "<solid|stripes|plaid|floral|abstract|animal|geometric|null>",
  "texture": "<smooth|textured|knit|denim|leather|silk|linen|wool|null>"
}"""

_USER_PROMPT = "Analyze this clothing item."


async def process_garment(garment_id: str, raw_bytes: bytes) -> None:
    """Entry point for background AI processing."""
    async with AsyncSessionLocal() as db:
        try:
            await _set_status(db, garment_id, "processing")

            # Step 1: Upload all image variants to S3
            urls = await upload_garment_image(raw_bytes, garment_id)

            # Step 2: Extract colors with Pillow
            color_data = await extract_colors(raw_bytes)

            # Step 3: AI analysis with Claude
            await _set_status(db, garment_id, "analyzing")
            ai_data = await _analyze_with_claude(raw_bytes)

            # Step 4: Persist everything
            result = await db.execute(select(Garment).where(Garment.id == garment_id))
            garment = result.scalar_one_or_none()
            if not garment:
                return

            for k, v in urls.items():
                setattr(garment, k, v)
            garment.dominant_color = color_data["dominant_color"]
            garment.color_palette = color_data["color_palette"]

            if ai_data:
                garment.category = ai_data.get("category") or garment.category
                garment.subcategory = ai_data.get("subcategory")
                garment.ai_style_label = ai_data.get("ai_style_label")
                garment.style_tags = ai_data.get("style_tags", [])
                garment.formality = ai_data.get("formality")
                garment.seasons = ai_data.get("seasons", [])
                garment.occasions = ai_data.get("occasions", [])
                garment.pattern = ai_data.get("pattern")
                garment.texture = ai_data.get("texture")

            garment.ai_status = "complete"
            garment.updated_at = datetime.now(timezone.utc)
            await db.commit()

        except Exception:
            log.error("AI pipeline failed for garment %s:\n%s", garment_id, traceback.format_exc())
            await db.rollback()
            await _set_status(db, garment_id, "failed")


async def _set_status(db: AsyncSession, garment_id: str, status: str) -> None:
    result = await db.execute(select(Garment).where(Garment.id == garment_id))
    garment = result.scalar_one_or_none()
    if garment:
        garment.ai_status = status
        garment.updated_at = datetime.now(timezone.utc)
        await db.commit()


async def _analyze_with_claude(raw_bytes: bytes) -> dict | None:
    if not settings.anthropic_api_key or not settings.ai_enabled:
        return None

    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    b64 = base64.standard_b64encode(raw_bytes).decode("utf-8")

    try:
        message = await client.messages.create(
            model=_CLAUDE_MODEL,
            max_tokens=512,
            system=_SYSTEM_PROMPT,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": b64,
                            },
                        },
                        {"type": "text", "text": _USER_PROMPT},
                    ],
                }
            ],
        )
        text = message.content[0].text.strip()
        # Strip markdown code fences if present
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        return json.loads(text)
    except (json.JSONDecodeError, anthropic.APIError) as e:
        log.warning("Claude analysis failed: %s", e)
        return None
