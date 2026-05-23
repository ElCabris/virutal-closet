"""add outfits, wear_logs, style_profiles, wishlist_items

Revision ID: 002
Revises: 001
Create Date: 2026-05-21
"""
from alembic import op
import sqlalchemy as sa

revision = "002"
down_revision = "001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "outfits",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("user_id", sa.String, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(200), nullable=True),
        sa.Column("mood", sa.String(50), nullable=True),
        sa.Column("occasion", sa.String(100), nullable=True),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("ai_score", sa.Float, nullable=True),
        sa.Column("ai_rationale", sa.Text, nullable=True),
        sa.Column("palette_match", sa.String(50), nullable=True),
        sa.Column("novelty_score", sa.Float, nullable=True),
        sa.Column("wear_count", sa.Integer, server_default="0", nullable=False),
        sa.Column("last_worn_at", sa.Date, nullable=True),
        sa.Column("is_saved", sa.Boolean, server_default="true", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("idx_outfits_user", "outfits", ["user_id"])

    op.create_table(
        "outfit_items",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("outfit_id", sa.String, sa.ForeignKey("outfits.id", ondelete="CASCADE"), nullable=False),
        sa.Column("garment_id", sa.String, sa.ForeignKey("clothing_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role", sa.String(50), nullable=True),
        sa.Column("sort_order", sa.Integer, server_default="0", nullable=False),
    )
    op.create_index("idx_outfit_items_outfit", "outfit_items", ["outfit_id"])

    op.create_table(
        "wear_logs",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("user_id", sa.String, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("garment_id", sa.String, sa.ForeignKey("clothing_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("outfit_id", sa.String, sa.ForeignKey("outfits.id", ondelete="SET NULL"), nullable=True),
        sa.Column("worn_on", sa.Date, nullable=False),
        sa.Column("mood", sa.String(50), nullable=True),
        sa.Column("occasion", sa.String(100), nullable=True),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("idx_wear_logs_user_date", "wear_logs", ["user_id", "worn_on"])
    op.create_index("idx_wear_logs_garment", "wear_logs", ["garment_id"])

    op.create_table(
        "style_profiles",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("user_id", sa.String, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("style_vibes", sa.JSON, server_default="[]", nullable=False),
        sa.Column("color_palette_pref", sa.JSON, server_default="[]", nullable=False),
        sa.Column("occasions", sa.JSON, server_default="[]", nullable=False),
        sa.Column("climate", sa.String(50), nullable=True),
        sa.Column("goals", sa.JSON, server_default="[]", nullable=False),
        sa.Column("onboarding_completed", sa.Boolean, server_default="false", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "wishlist_items",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("user_id", sa.String, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("brand", sa.String(100), nullable=True),
        sa.Column("category", sa.String(50), nullable=True),
        sa.Column("image_url", sa.Text, nullable=True),
        sa.Column("product_url", sa.Text, nullable=True),
        sa.Column("target_price", sa.Numeric(10, 2), nullable=True),
        sa.Column("current_price", sa.Numeric(10, 2), nullable=True),
        sa.Column("currency", sa.String(3), server_default="USD", nullable=False),
        sa.Column("priority", sa.String(20), server_default="medium", nullable=False),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("is_purchased", sa.Boolean, server_default="false", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("idx_wishlist_user", "wishlist_items", ["user_id"])


def downgrade() -> None:
    op.drop_table("wishlist_items")
    op.drop_table("style_profiles")
    op.drop_table("wear_logs")
    op.drop_table("outfit_items")
    op.drop_table("outfits")
