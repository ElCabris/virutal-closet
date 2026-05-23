import uuid
from datetime import datetime, date
from decimal import Decimal
from sqlalchemy import (
    String, Boolean, Integer, SmallInteger, Date, DateTime,
    Numeric, ForeignKey, func, Text, JSON
)
from sqlalchemy.orm import Mapped, mapped_column
from src.core.database import Base


class Garment(Base):
    __tablename__ = "clothing_items"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    # Identity
    name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    brand: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Status
    status: Mapped[str] = mapped_column(String(20), default="active")
    ai_status: Mapped[str] = mapped_column(String(20), default="pending")

    # Images
    image_url_raw: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url_processed: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url_thumb: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url_card: Mapped[str | None] = mapped_column(Text, nullable=True)
    blur_hash: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # AI Classification
    category: Mapped[str | None] = mapped_column(String(50), nullable=True)
    subcategory: Mapped[str | None] = mapped_column(String(100), nullable=True)
    formality: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    seasons: Mapped[list] = mapped_column(JSON, default=list)
    occasions: Mapped[list] = mapped_column(JSON, default=list)
    style_tags: Mapped[list] = mapped_column(JSON, default=list)
    ai_style_label: Mapped[str | None] = mapped_column(String(200), nullable=True)

    # Color
    dominant_color: Mapped[str | None] = mapped_column(String(7), nullable=True)
    color_palette: Mapped[list] = mapped_column(JSON, default=list)

    # Material & Pattern
    pattern: Mapped[str | None] = mapped_column(String(50), nullable=True)
    texture: Mapped[str | None] = mapped_column(String(50), nullable=True)
    materials: Mapped[list] = mapped_column(JSON, default=list)

    # User metadata
    purchase_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    purchase_price: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    condition: Mapped[str] = mapped_column(String(20), default="good")
    size: Mapped[str | None] = mapped_column(String(20), nullable=True)
    user_tags: Mapped[list] = mapped_column(JSON, default=list)

    # Usage tracking
    wear_count: Mapped[int] = mapped_column(Integer, default=0)
    last_worn_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_favorite: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
