import uuid
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.core.database import get_db
from src.dependencies import get_current_user
from src.models.garment import Garment
from src.models.outfit import Outfit, OutfitItem
from src.models.user import User
from src.schemas.outfit import OutfitCreate, OutfitOut, OutfitSaveFromRec

router = APIRouter(prefix="/outfits", tags=["outfits"])


@router.get("", response_model=list[OutfitOut])
async def list_outfits(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Outfit)
        .where(Outfit.user_id == current_user.id, Outfit.deleted_at.is_(None))
        .options(selectinload(Outfit.items))
        .order_by(Outfit.created_at.desc())
        .limit(50)
    )
    return list(result.scalars().all())


@router.post("", response_model=OutfitOut, status_code=201)
async def create_outfit(
    body: OutfitCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Validate garments belong to user
    result = await db.execute(
        select(Garment).where(
            Garment.id.in_(body.garment_ids),
            Garment.user_id == current_user.id,
            Garment.deleted_at.is_(None),
        )
    )
    garments = {g.id: g for g in result.scalars().all()}
    if len(garments) != len(body.garment_ids):
        raise HTTPException(status_code=400, detail="One or more garments not found")

    outfit = Outfit(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        name=body.name,
        mood=body.mood,
        occasion=body.occasion,
        notes=body.notes,
        is_saved=True,
    )
    db.add(outfit)
    await db.flush()

    for i, gid in enumerate(body.garment_ids):
        db.add(OutfitItem(
            id=str(uuid.uuid4()),
            outfit_id=outfit.id,
            garment_id=gid,
            role=body.roles.get(gid),
            sort_order=i,
        ))

    await db.commit()
    result2 = await db.execute(
        select(Outfit).where(Outfit.id == outfit.id).options(selectinload(Outfit.items))
    )
    return result2.scalar_one()


@router.post("/save-recommendation", response_model=OutfitOut, status_code=201)
async def save_recommendation(
    body: OutfitSaveFromRec,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    outfit = Outfit(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        name=body.name or body.recommendation_id,
        mood=body.mood,
        ai_score=body.ai_score,
        ai_rationale=body.ai_rationale,
        palette_match=body.palette_match,
        is_saved=True,
    )
    db.add(outfit)
    await db.flush()

    for i, gid in enumerate(body.garment_ids):
        db.add(OutfitItem(
            id=str(uuid.uuid4()),
            outfit_id=outfit.id,
            garment_id=gid,
            role=body.roles.get(gid),
            sort_order=i,
        ))

    await db.commit()
    result = await db.execute(
        select(Outfit).where(Outfit.id == outfit.id).options(selectinload(Outfit.items))
    )
    return result.scalar_one()


@router.post("/{outfit_id}/wear", response_model=OutfitOut)
async def log_outfit_wear(
    outfit_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Outfit)
        .where(Outfit.id == outfit_id, Outfit.user_id == current_user.id, Outfit.deleted_at.is_(None))
        .options(selectinload(Outfit.items))
    )
    outfit = result.scalar_one_or_none()
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found")

    outfit.wear_count += 1
    outfit.last_worn_at = date.today()
    outfit.updated_at = datetime.now(timezone.utc)

    # Batch-fetch all garments in this outfit in one query
    garment_ids = [item.garment_id for item in outfit.items]
    g_result = await db.execute(select(Garment).where(Garment.id.in_(garment_ids)))
    for g in g_result.scalars().all():
        g.wear_count += 1
        g.last_worn_at = date.today()

    await db.commit()
    await db.refresh(outfit)
    return outfit


@router.delete("/{outfit_id}", status_code=204)
async def delete_outfit(
    outfit_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Outfit).where(Outfit.id == outfit_id, Outfit.user_id == current_user.id)
    )
    outfit = result.scalar_one_or_none()
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found")

    outfit.deleted_at = datetime.now(timezone.utc)
    await db.commit()
