import uuid
from datetime import datetime, date
from sqlalchemy import String, Date, DateTime, ForeignKey, Text, func
from sqlalchemy.orm import Mapped, mapped_column
from src.core.database import Base


class WearLog(Base):
    __tablename__ = "wear_logs"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    garment_id: Mapped[str] = mapped_column(String, ForeignKey("clothing_items.id", ondelete="CASCADE"), nullable=False)
    outfit_id: Mapped[str | None] = mapped_column(String, ForeignKey("outfits.id", ondelete="SET NULL"), nullable=True)

    worn_on: Mapped[date] = mapped_column(Date, nullable=False)
    mood: Mapped[str | None] = mapped_column(String(50), nullable=True)
    occasion: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
