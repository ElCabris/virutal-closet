from pydantic import BaseModel
from datetime import date, datetime


class OutfitItemOut(BaseModel):
    id: str
    garment_id: str
    role: str | None
    sort_order: int
    model_config = {"from_attributes": True}


class OutfitOut(BaseModel):
    id: str
    user_id: str
    name: str | None
    mood: str | None
    occasion: str | None
    notes: str | None
    ai_score: float | None
    ai_rationale: str | None
    palette_match: str | None
    novelty_score: float | None
    wear_count: int
    last_worn_at: date | None
    is_saved: bool
    items: list[OutfitItemOut]
    created_at: datetime
    updated_at: datetime
    model_config = {"from_attributes": True}


class OutfitCreate(BaseModel):
    name: str | None = None
    mood: str | None = None
    occasion: str | None = None
    notes: str | None = None
    garment_ids: list[str]
    roles: dict[str, str] = {}  # garment_id → role


class OutfitSaveFromRec(BaseModel):
    recommendation_id: str
    name: str | None = None
    mood: str | None = None
    garment_ids: list[str]
    roles: dict[str, str] = {}
    ai_score: float | None = None
    ai_rationale: str | None = None
    palette_match: str | None = None
