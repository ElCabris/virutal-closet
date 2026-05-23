from pydantic import BaseModel, HttpUrl
from datetime import datetime
from decimal import Decimal


class WishlistItemOut(BaseModel):
    id: str
    user_id: str
    name: str
    brand: str | None
    category: str | None
    image_url: str | None
    product_url: str | None
    target_price: Decimal | None
    current_price: Decimal | None
    currency: str
    priority: str
    notes: str | None
    is_purchased: bool
    created_at: datetime
    updated_at: datetime
    model_config = {"from_attributes": True}


class WishlistItemCreate(BaseModel):
    name: str
    brand: str | None = None
    category: str | None = None
    image_url: str | None = None
    product_url: str | None = None
    target_price: Decimal | None = None
    current_price: Decimal | None = None
    currency: str = "USD"
    priority: str = "medium"
    notes: str | None = None


class WishlistItemUpdate(BaseModel):
    name: str | None = None
    brand: str | None = None
    target_price: Decimal | None = None
    current_price: Decimal | None = None
    priority: str | None = None
    notes: str | None = None
    is_purchased: bool | None = None
    product_url: str | None = None
