import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime, ForeignKey, JSON, func
from sqlalchemy.orm import Mapped, mapped_column
from src.core.database import Base


class StyleProfile(Base):
    __tablename__ = "style_profiles"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)

    # Onboarding answers
    style_vibes: Mapped[list] = mapped_column(JSON, default=list)      # minimal, classic, streetwear, etc.
    color_palette_pref: Mapped[list] = mapped_column(JSON, default=list)  # neutrals, earth, bold, monochrome
    occasions: Mapped[list] = mapped_column(JSON, default=list)        # office, casual, events
    climate: Mapped[str | None] = mapped_column(String(50), nullable=True)  # tropical, temperate, cold
    goals: Mapped[list] = mapped_column(JSON, default=list)            # capsule, variety, cost_per_wear

    onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
