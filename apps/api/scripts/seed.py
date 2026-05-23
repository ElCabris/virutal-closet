"""
Seed script — crea la cuenta de Ana María con founder_access
y carga prendas de ejemplo para que el closet no esté vacío.
"""
import asyncio
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from sqlalchemy import select
from src.core.database import AsyncSessionLocal
from src.core.security import hash_password
from src.models.user import User
from src.models.garment import Garment
from src.config import get_settings
import uuid

settings = get_settings()

SEED_GARMENTS = [
    {
        "name": "Blusa de Seda Ivory", "brand": "COS",
        "category": "tops", "subcategory": "blusa",
        "ai_style_label": "blusa ivory estructurada",
        "dominant_color": "#FAF8F5",
        "color_palette": [{"hex": "#FAF8F5", "name": "Ivory", "percentage": 0.85}],
        "style_tags": ["minimalista", "estructurado", "oficina", "seda"],
        "formality": 3, "seasons": ["primavera", "otoño"],
        "occasions": ["trabajo", "almuerzo", "eventos"],
        "pattern": "solid", "texture": "smooth", "materials": ["seda"],
        "condition": "excellent", "wear_count": 12,
        "purchase_price": 89.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/FAF8F5/1C1A18?text=Blusa+Seda",
        "image_url_thumb": "https://placehold.co/200x280/FAF8F5/1C1A18?text=Blusa",
        "ai_status": "complete",
    },
    {
        "name": "Pantalón Negro Sastre", "brand": "Zara",
        "category": "bottoms", "subcategory": "pantalón",
        "ai_style_label": "pantalón sastre de corte alto",
        "dominant_color": "#1C1A18",
        "color_palette": [{"hex": "#1C1A18", "name": "Warm Black", "percentage": 0.95}],
        "style_tags": ["clásico", "sastre", "versátil", "formal"],
        "formality": 3, "seasons": ["primavera", "otoño", "invierno"],
        "occasions": ["trabajo", "eventos", "cena"],
        "pattern": "solid", "texture": "smooth", "materials": ["lana", "poliéster"],
        "condition": "good", "wear_count": 28,
        "purchase_price": 55.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/1C1A18/FAF8F5?text=Pantalon+Negro",
        "image_url_thumb": "https://placehold.co/200x280/1C1A18/FAF8F5?text=Pantalon",
        "ai_status": "complete",
    },
    {
        "name": "Blazer Camel Oversize", "brand": "Massimo Dutti",
        "category": "outerwear", "subcategory": "blazer",
        "ai_style_label": "blazer camel de corte oversize",
        "dominant_color": "#C9A99A",
        "color_palette": [{"hex": "#C9A99A", "name": "Dusty Mauve", "percentage": 0.88}],
        "style_tags": ["editorial", "oversize", "camel", "estructurado"],
        "formality": 3, "seasons": ["otoño", "invierno", "primavera"],
        "occasions": ["trabajo", "casual", "eventos"],
        "pattern": "solid", "texture": "smooth", "materials": ["lana"],
        "condition": "excellent", "wear_count": 8,
        "purchase_price": 180.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/C9A99A/1C1A18?text=Blazer+Camel",
        "image_url_thumb": "https://placehold.co/200x280/C9A99A/1C1A18?text=Blazer",
        "ai_status": "complete",
    },
    {
        "name": "Vestido Midi Ivory", "brand": "& Other Stories",
        "category": "dresses", "subcategory": "midi",
        "ai_style_label": "vestido midi romántico ivory",
        "dominant_color": "#F5F0E8",
        "color_palette": [{"hex": "#F5F0E8", "name": "Warm Cream", "percentage": 0.90}],
        "style_tags": ["femenino", "romántico", "midi", "elegante"],
        "formality": 3, "seasons": ["primavera", "verano"],
        "occasions": ["cena", "eventos", "casual"],
        "pattern": "solid", "texture": "smooth", "materials": ["viscosa"],
        "condition": "excellent", "wear_count": 5,
        "purchase_price": 120.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/F5F0E8/1C1A18?text=Vestido+Midi",
        "image_url_thumb": "https://placehold.co/200x280/F5F0E8/1C1A18?text=Vestido",
        "ai_status": "complete",
    },
    {
        "name": "Jeans Azul Oscuro", "brand": "Agolde",
        "category": "bottoms", "subcategory": "jeans",
        "ai_style_label": "jeans de corte recto azul oscuro",
        "dominant_color": "#3D5A80",
        "color_palette": [{"hex": "#3D5A80", "name": "Deep Blue", "percentage": 0.85}],
        "style_tags": ["casual", "denim", "versátil", "recto"],
        "formality": 2, "seasons": ["primavera", "otoño", "invierno"],
        "occasions": ["casual", "trabajo casual", "travel"],
        "pattern": "solid", "texture": "denim", "materials": ["denim"],
        "condition": "good", "wear_count": 35,
        "purchase_price": 200.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/3D5A80/FAF8F5?text=Jeans+Azul",
        "image_url_thumb": "https://placehold.co/200x280/3D5A80/FAF8F5?text=Jeans",
        "ai_status": "complete",
    },
    {
        "name": "Bolso de Cuero Marrón", "brand": "Mango",
        "category": "bags", "subcategory": "tote",
        "ai_style_label": "tote de cuero marrón estructurado",
        "dominant_color": "#9E7B5A",
        "color_palette": [{"hex": "#9E7B5A", "name": "Antique Bronze", "percentage": 0.92}],
        "style_tags": ["cuero", "tote", "diario", "estructurado"],
        "formality": 2, "seasons": ["primavera", "otoño", "invierno"],
        "occasions": ["trabajo", "casual", "travel"],
        "pattern": "solid", "texture": "leather", "materials": ["cuero"],
        "condition": "good", "wear_count": 62,
        "purchase_price": 95.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/9E7B5A/FAF8F5?text=Bolso+Cuero",
        "image_url_thumb": "https://placehold.co/200x280/9E7B5A/FAF8F5?text=Bolso",
        "ai_status": "complete",
    },
    {
        "name": "Suéter de Cachemir Beige", "brand": "Uniqlo",
        "category": "tops", "subcategory": "suéter",
        "ai_style_label": "suéter de cachemir beige suave",
        "dominant_color": "#E8D5C4",
        "color_palette": [{"hex": "#E8D5C4", "name": "Blush Rose", "percentage": 0.88}],
        "style_tags": ["cachemir", "suave", "cozy", "premium"],
        "formality": 2, "seasons": ["otoño", "invierno"],
        "occasions": ["casual", "trabajo casual", "cozy"],
        "pattern": "solid", "texture": "knit", "materials": ["cachemir"],
        "condition": "excellent", "wear_count": 18,
        "purchase_price": 130.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/E8D5C4/1C1A18?text=Suéter+Cachemir",
        "image_url_thumb": "https://placehold.co/200x280/E8D5C4/1C1A18?text=Suéter",
        "ai_status": "complete",
    },
    {
        "name": "Falda Mini Plisada", "brand": "Reformation",
        "category": "bottoms", "subcategory": "falda",
        "ai_style_label": "minifalda plisada floral romántica",
        "dominant_color": "#D4AF82",
        "color_palette": [
            {"hex": "#D4AF82", "name": "Champagne Gold", "percentage": 0.60},
            {"hex": "#FAF8F5", "name": "Ivory", "percentage": 0.30},
        ],
        "style_tags": ["femenino", "plisado", "floral", "romántico"],
        "formality": 2, "seasons": ["primavera", "verano"],
        "occasions": ["casual", "cena", "eventos"],
        "pattern": "floral", "texture": "smooth", "materials": ["viscosa"],
        "condition": "excellent", "wear_count": 4,
        "purchase_price": 148.00, "currency": "USD",
        "image_url_card": "https://placehold.co/400x560/D4AF82/1C1A18?text=Falda+Mini",
        "image_url_thumb": "https://placehold.co/200x280/D4AF82/1C1A18?text=Falda",
        "ai_status": "complete",
    },
]


async def seed():
    async with AsyncSessionLocal() as db:
        # 1. Create or get Ana María
        result = await db.execute(select(User).where(User.email == settings.founder_email))
        user = result.scalar_one_or_none()

        if not user:
            user = User(
                id=str(uuid.uuid4()),
                email=settings.founder_email,
                password_hash=hash_password("Crayoli2026!"),
                display_name=settings.founder_name,
                founder_access=True,
                tier="founder",
                is_active=True,
                email_verified=True,
            )
            db.add(user)
            await db.flush()
            print(f"✓ Usuario creado: {settings.founder_email} (password: Crayoli2026!)")
        else:
            # Ensure founder_access is always true
            user.founder_access = True
            user.tier = "founder"
            print(f"✓ Usuario existente: {settings.founder_email}")

        # 2. Check if garments already seeded
        from sqlalchemy import func
        count_result = await db.execute(
            select(func.count()).select_from(Garment).where(Garment.user_id == user.id)
        )
        count = count_result.scalar()

        if count == 0:
            for data in SEED_GARMENTS:
                garment = Garment(
                    id=str(uuid.uuid4()),
                    user_id=user.id,
                    status="active",
                    **data,
                )
                db.add(garment)
            print(f"✓ {len(SEED_GARMENTS)} prendas de ejemplo creadas")
        else:
            print(f"✓ Closet ya tiene {count} prendas — no se sobrescriben")

        await db.commit()
        print("✓ Seed completo")


if __name__ == "__main__":
    asyncio.run(seed())
