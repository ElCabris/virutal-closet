"""
Hybrid recommendation engine.

Scoring model (0.0–1.0):
  - Category balance     40% — outfit must cover key roles
  - Color harmony        25% — palette compatibility
  - Mood / formality     20% — context alignment
  - Novelty              15% — prefer less-worn garments

No ML required. Pure Python arithmetic on existing garment metadata.
"""
import json
import math
import random
from datetime import date, datetime, timezone
from typing import NamedTuple

from src.models.garment import Garment

MOOD_FORMALITY: dict[str, tuple[int, int]] = {
    "office":    (3, 5),
    "casual":    (1, 3),
    "dinner":    (3, 5),
    "elegant":   (4, 5),
    "soft_girl": (1, 3),
    "cozy":      (1, 2),
    "travel":    (1, 3),
    "academia":  (2, 4),
}

MOOD_OCCASIONS: dict[str, list[str]] = {
    "office":    ["office"],
    "casual":    ["casual"],
    "dinner":    ["formal", "evening"],
    "elegant":   ["formal", "evening"],
    "soft_girl": ["casual"],
    "cozy":      ["casual"],
    "travel":    ["travel", "casual"],
    "academia":  ["casual", "office"],
}

MOOD_LABELS: dict[str, list[str]] = {
    "office":    ["Polished Morning", "Structured Day", "Clean Lines"],
    "casual":    ["Easy Sunday", "Effortless Edit", "Soft Afternoon"],
    "dinner":    ["Golden Hour", "Dinner Glow", "Evening Edit"],
    "soft_girl": ["Soft Moment", "Petal Morning", "Quiet Feminine"],
    "cozy":      ["Indoor Day", "Cashmere Mood", "Slow Morning"],
    "travel":    ["Departure Ready", "Light Carry", "Transit Edit"],
    "elegant":   ["Quiet Luxury", "Editorial Evening", "Refined Moment"],
    "academia":  ["Library Hours", "Intellectual Ease", "Autumn Study"],
}

CURRENT_SEASON_MAP = {
    (12, 1, 2): "winter",
    (3, 4, 5):  "spring",
    (6, 7, 8):  "summer",
    (9, 10, 11): "fall",
}

ROLE_CATEGORIES: dict[str, list[str]] = {
    "top":       ["tops"],
    "bottom":    ["bottoms"],
    "dress":     ["dresses"],
    "outerwear": ["outerwear"],
    "shoes":     ["shoes"],
    "bag":       ["bags"],
    "accessory": ["accessories"],
}


def _current_season() -> str:
    m = datetime.now(timezone.utc).month
    for months, season in CURRENT_SEASON_MAP.items():
        if m in months:
            return season
    return "fall"


def _hex_to_hsv(hex_color: str) -> tuple[float, float, float]:
    hex_color = hex_color.lstrip("#")
    if len(hex_color) != 6:
        return 0.0, 0.0, 0.5
    r, g, b = (int(hex_color[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    mx, mn = max(r, g, b), min(r, g, b)
    diff = mx - mn
    if diff == 0:
        h = 0.0
    elif mx == r:
        h = (60 * ((g - b) / diff) + 360) % 360
    elif mx == g:
        h = (60 * ((b - r) / diff) + 120) % 360
    else:
        h = (60 * ((r - g) / diff) + 240) % 360
    s = 0.0 if mx == 0 else diff / mx
    return h, s, mx


def _color_harmony_score(colors: list[str]) -> float:
    """Score a set of dominant hex colors for visual harmony."""
    if len(colors) < 2:
        return 0.5

    hsvs = [_hex_to_hsv(c) for c in colors if c and len(c) == 7]
    if not hsvs:
        return 0.5

    neutrals = [h for h, s, v in hsvs if s < 0.2 or v < 0.15]
    chromas = [(h, s, v) for h, s, v in hsvs if s >= 0.2 and v >= 0.15]

    neutral_ratio = len(neutrals) / len(hsvs)

    if neutral_ratio >= 0.7:
        return 0.85

    if not chromas:
        return 0.8

    hues = [h for h, _, _ in chromas]
    hue_diffs = []
    for i in range(len(hues)):
        for j in range(i + 1, len(hues)):
            diff = abs(hues[i] - hues[j])
            if diff > 180:
                diff = 360 - diff
            hue_diffs.append(diff)

    if not hue_diffs:
        return 0.75

    avg_diff = sum(hue_diffs) / len(hue_diffs)

    if 150 <= avg_diff <= 210:
        return 1.0
    if 110 <= avg_diff < 150 or 210 < avg_diff <= 250:
        return 0.85
    if 20 <= avg_diff < 60:
        return 0.75
    return 0.55


def _category_balance_score(garments: list[Garment]) -> float:
    """A complete outfit must cover top+bottom (or dress) + ideally shoes."""
    cats = {g.category for g in garments}
    has_top = "tops" in cats or "dresses" in cats
    has_bottom = "bottoms" in cats or "dresses" in cats
    has_shoes = "shoes" in cats

    score = 0.0
    if has_top and has_bottom:
        score += 0.5
    elif "dresses" in cats:
        score += 0.5
    if has_shoes:
        score += 0.3
    if "outerwear" in cats or "bags" in cats:
        score += 0.2
    return min(score, 1.0)


def _mood_score(garments: list[Garment], mood: str) -> float:
    formality_range = MOOD_FORMALITY.get(mood, (1, 5))
    occasions = set(MOOD_OCCASIONS.get(mood, []))
    season = _current_season()

    scores = []
    for g in garments:
        s = 0.0
        if g.formality is not None:
            lo, hi = formality_range
            if lo <= g.formality <= hi:
                s += 0.5
            else:
                gap = min(abs(g.formality - lo), abs(g.formality - hi))
                s += max(0, 0.5 - gap * 0.1)

        if g.occasions and occasions.intersection(g.occasions):
            s += 0.3

        if g.seasons and season in g.seasons:
            s += 0.2

        scores.append(min(s, 1.0))

    return sum(scores) / len(scores) if scores else 0.5


def _novelty_score(garments: list[Garment]) -> float:
    """Prefer garments that haven't been worn recently."""
    today = date.today()
    scores = []
    for g in garments:
        if g.wear_count == 0:
            scores.append(1.0)
        elif g.last_worn_at is None:
            scores.append(0.9)
        else:
            days_since = (today - g.last_worn_at).days
            scores.append(min(1.0, days_since / 30.0))
    return sum(scores) / len(scores) if scores else 0.5


class OutfitCandidate(NamedTuple):
    garments: list[Garment]
    score: float
    color_score: float
    balance_score: float
    mood_score: float
    novelty_score: float


def _build_outfit_candidate(garments: list[Garment], mood: str) -> OutfitCandidate:
    colors = [g.dominant_color for g in garments if g.dominant_color]
    c_score = _color_harmony_score(colors)
    b_score = _category_balance_score(garments)
    m_score = _mood_score(garments, mood)
    n_score = _novelty_score(garments)

    final = c_score * 0.25 + b_score * 0.40 + m_score * 0.20 + n_score * 0.15
    return OutfitCandidate(
        garments=garments,
        score=round(final, 3),
        color_score=round(c_score, 3),
        balance_score=round(b_score, 3),
        mood_score=round(m_score, 3),
        novelty_score=round(n_score, 3),
    )


def _serialize_garment(g: Garment) -> dict:
    return {
        "id": g.id,
        "name": g.name,
        "category": g.category,
        "image_url_card": g.image_url_card,
        "image_url_thumb": g.image_url_thumb,
        "dominant_color": g.dominant_color,
        "ai_style_label": g.ai_style_label,
        "wear_count": g.wear_count,
    }


def build_recommendations(
    garments: list[Garment],
    mood: str,
    count: int = 3,
) -> list[dict]:
    if len(garments) < 2:
        return []

    # Group by category
    by_category: dict[str, list[Garment]] = {}
    for g in garments:
        cat = g.category or "other"
        by_category.setdefault(cat, []).append(g)

    candidates: list[OutfitCandidate] = []

    # Generate diverse candidate outfits with targeted category selection
    for _ in range(max(count * 20, 60)):
        selected: list[Garment] = []

        # Always try to include a top or dress
        if "dresses" in by_category and random.random() < 0.35:
            selected.append(random.choice(by_category["dresses"]))
        else:
            top_pool = by_category.get("tops", [])
            bottom_pool = by_category.get("bottoms", [])
            if top_pool:
                selected.append(random.choice(top_pool))
            if bottom_pool:
                selected.append(random.choice(bottom_pool))

        # Add shoes
        if "shoes" in by_category:
            selected.append(random.choice(by_category["shoes"]))

        # Optionally add outerwear, bag, or accessory
        extras = ["outerwear", "bags", "accessories"]
        random.shuffle(extras)
        for extra in extras[:random.randint(0, 2)]:
            if extra in by_category:
                selected.append(random.choice(by_category[extra]))

        if len(selected) < 2:
            selected = random.sample(garments, min(len(garments), 3))

        # Deduplicate
        seen_ids = set()
        deduped = []
        for g in selected:
            if g.id not in seen_ids:
                seen_ids.add(g.id)
                deduped.append(g)

        candidates.append(_build_outfit_candidate(deduped, mood))

    # Sort by score and take top-N with diversity (avoid repeating same garments)
    candidates.sort(key=lambda c: c.score, reverse=True)

    chosen: list[OutfitCandidate] = []
    used_garment_ids: set[str] = set()

    for c in candidates:
        c_ids = {g.id for g in c.garments}
        overlap = c_ids & used_garment_ids
        # Allow max 1 shared garment across outfits
        if len(overlap) <= 1 or not chosen:
            chosen.append(c)
            used_garment_ids.update(c_ids)
        if len(chosen) >= count:
            break

    # If we couldn't get enough diverse outfits, pad from top candidates
    if len(chosen) < count:
        for c in candidates:
            if c not in chosen:
                chosen.append(c)
            if len(chosen) >= count:
                break

    labels = MOOD_LABELS.get(mood, ["Today's Look", "Your Edit", "Crayoli Pick"])
    result = []

    for i, c in enumerate(chosen):
        palette_label = (
            "Armonía perfecta" if c.color_score >= 0.9
            else "Paleta complementaria" if c.color_score >= 0.75
            else "Contraste editorial"
        )
        result.append({
            "id": f"rec_{mood}_{i}",
            "name": labels[i % len(labels)],
            "score": c.score,
            "mood": mood,
            "context_label": f"Para {mood} · curado por Crayoli",
            "palette_match": palette_label,
            "novelty_score": c.novelty_score,
            "rationale": {
                "color_harmony": palette_label,
                "balance": f"Balance de outfit: {c.balance_score:.0%}",
                "mood_fit": f"Alineación con {mood}: {c.mood_score:.0%}",
            },
            "items": [
                {"role": _infer_role(g), "garment": _serialize_garment(g)}
                for g in c.garments
            ],
        })

    return result


def _infer_role(g: Garment) -> str:
    cat_role = {
        "tops": "top", "bottoms": "bottom", "dresses": "dress",
        "outerwear": "outerwear", "shoes": "shoes",
        "bags": "bag", "accessories": "accessory",
    }
    return cat_role.get(g.category or "", "piece")
