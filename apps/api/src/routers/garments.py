import uuid
import math
from datetime import date, datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, Query, Request, UploadFile
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy import func, select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.core.redis import invalidate_user_recs
from src.core.storage import ALLOWED_MIME_TYPES, MAX_UPLOAD_BYTES, extract_colors, upload_garment_image
from src.dependencies import get_current_user
from src.models.garment import Garment
from src.models.user import User
from src.schemas.garment import GarmentCreate, GarmentOut, GarmentUpdate, PaginatedGarments, UploadResponse
from src.services.ai_pipeline import process_garment

router = APIRouter(prefix="/garments", tags=["garments"])
limiter = Limiter(key_func=get_remote_address)


@router.post("/upload", response_model=UploadResponse, status_code=201)
@limiter.limit("20/hour")
async def upload_garment_image_endpoint(
    request: Request,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    content_type = file.content_type or ""
    if content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=415, detail="Unsupported image format. Use JPEG, PNG, or WEBP.")

    raw_bytes = await file.read()
    if len(raw_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Image too large. Max 20 MB.")

    garment_id = str(uuid.uuid4())

    # Create garment stub immediately so UI can show it
    color_data = await extract_colors(raw_bytes)
    garment = Garment(
        id=garment_id,
        user_id=current_user.id,
        ai_status="queued",
        dominant_color=color_data["dominant_color"],
        color_palette=color_data["color_palette"],
    )
    db.add(garment)
    await db.commit()
    await db.refresh(garment)

    # Fire-and-forget AI pipeline (uploads to S3, runs Claude, updates record)
    background_tasks.add_task(process_garment, garment_id, raw_bytes)

    # Return stub URLs for immediate preview (will be replaced by pipeline)
    return UploadResponse(
        garment_id=garment_id,
        image_url_raw="",
        image_url_card="",
        image_url_thumb="",
        image_url_processed="",
        dominant_color=color_data["dominant_color"],
        color_palette=color_data["color_palette"],
    )


@router.get("", response_model=PaginatedGarments)
async def list_garments(
    category: str | None = Query(None),
    favorite: bool | None = Query(None),
    sort: str = Query("recent", pattern="^(recent|most_worn|least_worn|az)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conditions = [
        Garment.user_id == current_user.id,
        Garment.status == "active",
        Garment.deleted_at.is_(None),
    ]
    if category:
        conditions.append(Garment.category == category)
    if favorite is not None:
        conditions.append(Garment.is_favorite == favorite)

    count_stmt = select(func.count()).where(and_(*conditions))
    total = (await db.execute(count_stmt)).scalar_one()

    stmt = select(Garment).where(and_(*conditions))
    if sort == "most_worn":
        stmt = stmt.order_by(Garment.wear_count.desc())
    elif sort == "least_worn":
        stmt = stmt.order_by(Garment.wear_count.asc(), Garment.last_worn_at.asc().nullsfirst())
    elif sort == "az":
        stmt = stmt.order_by(Garment.name.asc().nullslast())
    else:
        stmt = stmt.order_by(Garment.created_at.desc())

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    items = (await db.execute(stmt)).scalars().all()

    total_pages = max(1, math.ceil(total / page_size))
    return PaginatedGarments(
        items=list(items),
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1,
    )


@router.post("", response_model=GarmentOut, status_code=201)
async def create_garment(
    body: GarmentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    garment = Garment(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        ai_status="complete",
        **body.model_dump(exclude_none=True),
    )
    db.add(garment)
    await db.commit()
    await db.refresh(garment)
    await invalidate_user_recs(current_user.id)
    return garment


@router.get("/{garment_id}", response_model=GarmentOut)
async def get_garment(
    garment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Garment).where(
            Garment.id == garment_id,
            Garment.user_id == current_user.id,
            Garment.deleted_at.is_(None),
        )
    )
    garment = result.scalar_one_or_none()
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")
    return garment


@router.patch("/{garment_id}", response_model=GarmentOut)
async def update_garment(
    garment_id: str,
    body: GarmentUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Garment).where(
            Garment.id == garment_id,
            Garment.user_id == current_user.id,
            Garment.deleted_at.is_(None),
        )
    )
    garment = result.scalar_one_or_none()
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(garment, field, value)

    garment.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(garment)
    await invalidate_user_recs(current_user.id)
    return garment


@router.delete("/{garment_id}", status_code=204)
async def delete_garment(
    garment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Garment).where(
            Garment.id == garment_id,
            Garment.user_id == current_user.id,
        )
    )
    garment = result.scalar_one_or_none()
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")

    garment.deleted_at = datetime.now(timezone.utc)
    await db.commit()
    await invalidate_user_recs(current_user.id)


@router.post("/{garment_id}/wear", response_model=GarmentOut)
async def log_wear(
    garment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Garment).where(
            Garment.id == garment_id,
            Garment.user_id == current_user.id,
            Garment.deleted_at.is_(None),
        )
    )
    garment = result.scalar_one_or_none()
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")

    garment.wear_count += 1
    garment.last_worn_at = date.today()
    garment.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(garment)
    await invalidate_user_recs(current_user.id)
    return garment
