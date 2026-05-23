from pydantic import BaseModel
from decimal import Decimal


class CategoryStat(BaseModel):
    category: str
    count: int
    percentage: float


class GarmentStat(BaseModel):
    id: str
    name: str | None
    category: str | None
    image_url_thumb: str | None
    dominant_color: str | None
    wear_count: int
    last_worn_at: str | None
    purchase_price: Decimal | None
    cost_per_wear: Decimal | None


class AnalyticsSummary(BaseModel):
    total_garments: int
    total_value: Decimal
    avg_cost_per_wear: Decimal | None
    most_worn: list[GarmentStat]
    least_worn: list[GarmentStat]
    never_worn: list[GarmentStat]
    by_category: list[CategoryStat]
    wear_logs_last_30d: int
    favorite_count: int
