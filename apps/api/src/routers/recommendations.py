import json
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.redis import get_redis, invalidate_user_recs
from src.dependencies import get_current_user
from src.models.garment import Garment
from src.models.user import User
from src.services.recommendations import build_recommendations

router = APIRouter(prefix="/recommendations", tags=["recommendations"])

_CACHE_TTL = 60 * 60 * 6  # 6 hours


@router.get("")
async def get_recommendations(
    mood: str = Query("casual"),
    count: int = Query(3, ge=1, le=6),
    refresh: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    redis = await get_redis()
    cache_key = f"recs:{current_user.id}:{mood}:{count}"

    if not refresh:
        cached = await redis.get(cache_key)
        if cached:
            return json.loads(cached)

    result = await db.execute(
        select(Garment).where(
            Garment.user_id == current_user.id,
            Garment.status == "active",
            Garment.deleted_at.is_(None),
            Garment.ai_status == "complete",
        ).limit(100)
    )
    garments = list(result.scalars().all())

    if len(garments) < 2:
        return {
            "context": {"mood": mood},
            "outfits": [],
            "message": "Agrega más prendas para obtener sugerencias de outfits.",
            "cached": False,
        }

    outfits = build_recommendations(garments, mood, count)

    payload = {
        "context": {"mood": mood, "garment_count": len(garments)},
        "outfits": outfits,
        "cached": False,
    }

    await redis.set(cache_key, json.dumps(payload, default=str), ex=_CACHE_TTL)
    return payload


@router.post("/invalidate")
async def invalidate_recommendations(current_user: User = Depends(get_current_user)):
    """Manual cache bust endpoint — also called internally via invalidate_user_recs()."""
    await invalidate_user_recs(current_user.id)
    return {"ok": True}


@router.get("/moods")
async def get_moods():
    return {
        "moods": [
            {"id": "casual",    "label": "Casual",    "emoji": "☀️"},
            {"id": "office",    "label": "Office",    "emoji": "💼"},
            {"id": "dinner",    "label": "Dinner",    "emoji": "🍷"},
            {"id": "elegant",   "label": "Elegant",   "emoji": "✨"},
            {"id": "soft_girl", "label": "Soft Girl", "emoji": "🌸"},
            {"id": "cozy",      "label": "Cozy",      "emoji": "🧸"},
            {"id": "travel",    "label": "Travel",    "emoji": "✈️"},
            {"id": "academia",  "label": "Academia",  "emoji": "📚"},
        ]
    }
