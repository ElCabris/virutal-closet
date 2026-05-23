import uuid
from datetime import datetime, date
from sqlalchemy import String, Boolean, Integer, Date, DateTime, ForeignKey, Text, JSON, func, Float
from sqlalchemy.orm import Mapped, mapped_column, relationship
from src.core.database import Base


class Outfit(Base):
    __tablename__ = "outfits"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    mood: Mapped[str | None] = mapped_column(String(50), nullable=True)
    occasion: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # AI-generated
    ai_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    ai_rationale: Mapped[str | None] = mapped_column(Text, nullable=True)
    palette_match: Mapped[str | None] = mapped_column(String(50), nullable=True)
    novelty_score: Mapped[float | None] = mapped_column(Float, nullable=True)

    wear_count: Mapped[int] = mapped_column(Integer, default=0)
    last_worn_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_saved: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    items: Mapped[list["OutfitItem"]] = relationship("OutfitItem", back_populates="outfit", cascade="all, delete-orphan")


class OutfitItem(Base):
    __tablename__ = "outfit_items"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    outfit_id: Mapped[str] = mapped_column(String, ForeignKey("outfits.id", ondelete="CASCADE"), nullable=False)
    garment_id: Mapped[str] = mapped_column(String, ForeignKey("clothing_items.id", ondelete="CASCADE"), nullable=False)
    role: Mapped[str | None] = mapped_column(String(50), nullable=True)  # top, bottom, shoes, bag, outerwear
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    outfit: Mapped["Outfit"] = relationship("Outfit", back_populates="items")
