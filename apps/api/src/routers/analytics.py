from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.dependencies import get_current_user
from src.models.garment import Garment
from src.models.wear_log import WearLog
from src.models.user import User
from src.schemas.analytics import AnalyticsSummary, CategoryStat, GarmentStat

router = APIRouter(prefix="/analytics", tags=["analytics"])


def _to_garment_stat(g: Garment) -> GarmentStat:
    cpw = None
    if g.purchase_price and g.wear_count and g.wear_count > 0:
        cpw = round(g.purchase_price / g.wear_count, 2)
    return GarmentStat(
        id=g.id,
        name=g.name,
        category=g.category,
        image_url_thumb=g.image_url_thumb,
        dominant_color=g.dominant_color,
        wear_count=g.wear_count,
        last_worn_at=g.last_worn_at.isoformat() if g.last_worn_at else None,
        purchase_price=g.purchase_price,
        cost_per_wear=cpw,
    )


@router.get("", response_model=AnalyticsSummary)
async def get_analytics(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Garment).where(
            Garment.user_id == current_user.id,
            Garment.status == "active",
            Garment.deleted_at.is_(None),
        )
    )
    garments = list(result.scalars().all())

    total_garments = len(garments)
    total_value = sum(
        (g.purchase_price or Decimal("0")) for g in garments
    )

    worn_garments = [g for g in garments if g.wear_count > 0 and g.purchase_price]
    avg_cpw: Decimal | None = None
    if worn_garments:
        cpws = [g.purchase_price / g.wear_count for g in worn_garments]
        avg_cpw = round(sum(cpws) / len(cpws), 2)

    sorted_by_wear = sorted(garments, key=lambda g: g.wear_count, reverse=True)
    most_worn = [_to_garment_stat(g) for g in sorted_by_wear[:5] if g.wear_count > 0]
    least_worn = [_to_garment_stat(g) for g in sorted_by_wear[-5:] if g.wear_count > 0]
    never_worn = [_to_garment_stat(g) for g in garments if g.wear_count == 0]

    # Category breakdown
    cat_counts: dict[str, int] = {}
    for g in garments:
        cat = g.category or "other"
        cat_counts[cat] = cat_counts.get(cat, 0) + 1

    by_category = [
        CategoryStat(
            category=cat,
            count=cnt,
            percentage=round(cnt / total_garments * 100, 1) if total_garments else 0.0,
        )
        for cat, cnt in sorted(cat_counts.items(), key=lambda x: x[1], reverse=True)
    ]

    # Wear logs last 30 days (worn_on is the actual wear date, not log creation date)
    cutoff_date = (datetime.now(timezone.utc) - timedelta(days=30)).date()
    logs_result = await db.execute(
        select(func.count()).where(
            WearLog.user_id == current_user.id,
            WearLog.worn_on >= cutoff_date,
        )
    )
    wear_logs_30d = logs_result.scalar_one() or 0

    favorite_count = sum(1 for g in garments if g.is_favorite)

    return AnalyticsSummary(
        total_garments=total_garments,
        total_value=total_value,
        avg_cost_per_wear=avg_cpw,
        most_worn=most_worn,
        least_worn=least_worn,
        never_worn=never_worn[:10],
        by_category=by_category,
        wear_logs_last_30d=wear_logs_30d,
        favorite_count=favorite_count,
    )
