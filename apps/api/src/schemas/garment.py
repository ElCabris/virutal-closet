from pydantic import BaseModel
from datetime import date, datetime
from decimal import Decimal


class ColorSwatch(BaseModel):
    hex: str
    name: str

    model_config = {"from_attributes": True}


class GarmentOut(BaseModel):
    id: str
    user_id: str
    name: str | None
    brand: str | None
    notes: str | None
    category: str | None
    subcategory: str | None
    image_url_raw: str | None
    image_url_card: str | None
    image_url_thumb: str | None
    image_url_processed: str | None
    blur_hash: str | None
    dominant_color: str | None
    color_palette: list[ColorSwatch]
    style_tags: list[str]
    ai_style_label: str | None
    formality: int | None
    seasons: list[str]
    occasions: list[str]
    pattern: str | None
    texture: str | None
    materials: list[str]
    purchase_price: Decimal | None
    currency: str
    condition: str
    size: str | None
    user_tags: list[str]
    wear_count: int
    last_worn_at: date | None
    is_favorite: bool
    status: str
    ai_status: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class PaginatedGarments(BaseModel):
    items: list[GarmentOut]
    total: int
    page: int
    page_size: int
    total_pages: int
    has_next: bool
    has_prev: bool


class GarmentCreate(BaseModel):
    name: str | None = None
    brand: str | None = None
    category: str | None = None
    subcategory: str | None = None
    purchase_price: Decimal | None = None
    currency: str = "USD"
    size: str | None = None
    condition: str = "good"
    notes: str | None = None
    user_tags: list[str] = []
    occasions: list[str] = []
    seasons: list[str] = []
    # Image URLs set after upload step
    image_url_raw: str | None = None


class GarmentUpdate(BaseModel):
    name: str | None = None
    brand: str | None = None
    category: str | None = None
    subcategory: str | None = None
    notes: str | None = None
    is_favorite: bool | None = None
    user_tags: list[str] | None = None
    occasions: list[str] | None = None
    seasons: list[str] | None = None
    style_tags: list[str] | None = None
    condition: str | None = None
    size: str | None = None
    purchase_price: Decimal | None = None
    currency: str | None = None
    formality: int | None = None
    pattern: str | None = None
    texture: str | None = None
    materials: list[str] | None = None


class UploadResponse(BaseModel):
    garment_id: str
    image_url_raw: str
    image_url_card: str
    image_url_thumb: str
    image_url_processed: str
    dominant_color: str | None
    color_palette: list[ColorSwatch]
