"""initial schema

Revision ID: 001
Revises:
Create Date: 2026-05-20
"""
from alembic import op
import sqlalchemy as sa

revision = "001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    op.create_table(
        "users",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("email", sa.String(320), nullable=False, unique=True),
        sa.Column("email_verified", sa.Boolean, default=False),
        sa.Column("password_hash", sa.String(255), nullable=True),
        sa.Column("display_name", sa.String(100), nullable=False),
        sa.Column("avatar_url", sa.Text, nullable=True),
        sa.Column("provider", sa.String(20), default="email"),
        sa.Column("provider_id", sa.String(255), nullable=True),
        sa.Column("timezone", sa.String(50), default="UTC"),
        sa.Column("locale", sa.String(10), default="es"),
        sa.Column("is_active", sa.Boolean, default=True),
        sa.Column("founder_access", sa.Boolean, default=False),
        sa.Column("tier", sa.String(20), default="essentials"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("idx_users_email", "users", ["email"])

    op.create_table(
        "clothing_items",
        sa.Column("id", sa.String, primary_key=True),
        sa.Column("user_id", sa.String, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(200), nullable=True),
        sa.Column("brand", sa.String(100), nullable=True),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("status", sa.String(20), default="active"),
        sa.Column("ai_status", sa.String(20), default="pending"),
        sa.Column("image_url_raw", sa.Text, nullable=True),
        sa.Column("image_url_processed", sa.Text, nullable=True),
        sa.Column("image_url_thumb", sa.Text, nullable=True),
        sa.Column("image_url_card", sa.Text, nullable=True),
        sa.Column("blur_hash", sa.String(100), nullable=True),
        sa.Column("category", sa.String(50), nullable=True),
        sa.Column("subcategory", sa.String(100), nullable=True),
        sa.Column("formality", sa.SmallInteger, nullable=True),
        sa.Column("seasons", sa.JSON, default=list),
        sa.Column("occasions", sa.JSON, default=list),
        sa.Column("style_tags", sa.JSON, default=list),
        sa.Column("ai_style_label", sa.String(200), nullable=True),
        sa.Column("dominant_color", sa.String(7), nullable=True),
        sa.Column("color_palette", sa.JSON, default=list),
        sa.Column("pattern", sa.String(50), nullable=True),
        sa.Column("texture", sa.String(50), nullable=True),
        sa.Column("materials", sa.JSON, default=list),
        sa.Column("purchase_date", sa.Date, nullable=True),
        sa.Column("purchase_price", sa.Numeric(10, 2), nullable=True),
        sa.Column("currency", sa.String(3), default="USD"),
        sa.Column("condition", sa.String(20), default="good"),
        sa.Column("size", sa.String(20), nullable=True),
        sa.Column("user_tags", sa.JSON, default=list),
        sa.Column("wear_count", sa.Integer, default=0),
        sa.Column("last_worn_at", sa.Date, nullable=True),
        sa.Column("is_favorite", sa.Boolean, default=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("idx_clothing_user_active", "clothing_items", ["user_id", "status"])
    op.create_index("idx_clothing_category", "clothing_items", ["user_id", "category"])


def downgrade() -> None:
    op.drop_table("clothing_items")
    op.drop_table("users")
