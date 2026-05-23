# Crayoli Closet — Product Requirements Document
**Version:** 1.1 | **Author:** Crayoli Product Team | **Date:** 2026-05-20
**Status:** Approved for Development | **Classification:** Internal — Confidential

> **Principio de acceso:** Ana María tiene acceso completo e irrestricto a **todas** las funcionalidades de Crayoli Closet — presentes y futuras — sin límites, sin tiers, sin restricciones de ningún tipo. El sistema entero está diseñado y calibrado para su experiencia al 100%.

---

## 1. Executive Summary

Crayoli Closet is a hyper-personalized AI-powered virtual wardrobe platform designed exclusively for Ana María Mosquera ("Crayoli"). It functions as an intelligent stylist, closet organizer, outfit generator, and fashion intelligence system — all wrapped in a premium editorial experience.

The product is positioned at the convergence of fashion, AI, and personal identity. It does not compete with generic wardrobe apps (Stylebook, Smart Closet, Combyne). It defines its own category: **intimate fashion intelligence.**

### Problem Statement

High-fashion consumers with large, curated wardrobes face three persistent problems:

1. **Decision fatigue** — too many options, no intelligent curation. The question "what to wear?" takes cognitive energy that should flow elsewhere.
2. **Invisible garments** — 80% of most wardrobes go unworn. Items are forgotten, duplicated, or underutilized. Emotional and financial value goes unrealized.
3. **Identity drift** — personal style is a living thing, but most tools treat the wardrobe as a static inventory. There is no system that learns who you are becoming.

### Vision

*"A closet that knows you better than you know yourself — and dresses you accordingly."*

Crayoli Closet becomes the single source of truth for personal style. Over time it builds a **Style DNA** — a living model of taste, preference, color affinity, occasion patterns, and aesthetic evolution. It is not an app you use. It is a relationship you develop.

### Target User (Persona: Ana María)

- **Age:** Late 20s — 30s
- **Fashion sophistication:** High — curated taste, awareness of trends, personal aesthetic already formed
- **Tech comfort:** High — uses premium apps, appreciates polish and craft
- **Wardrobe size:** 100 — 400+ items
- **Shopping behavior:** Quality over quantity, intentional purchases
- **Pain point:** Knowing she has beautiful pieces but not always seeing them; wanting AI that understands *her*, not generic fashion
- **Emotional need:** To feel seen, understood, and effortlessly stylish

---

## 2. Product Goals & Success Metrics

### North Star Metric
**Weekly Active Rate of AI Outfit Suggestions Used** — the percentage of weekly sessions where the user adopts or saves an AI-generated outfit. Target: >40% by Month 3.

### Primary Goals

| Goal | Metric | Target (6mo) |
|------|--------|-------------|
| Closet digitization | % of wardrobe uploaded | >60% of known wardrobe |
| Engagement | DAU/MAU ratio | >35% |
| AI adoption | Outfits generated per week | >5 per user |
| Retention | 30-day retention | >70% |
| Satisfaction | NPS score | >72 |

### Secondary Goals
- Build Style DNA model with sufficient signal within first 30 interactions
- Reduce "decision time" for morning outfit selection to < 2 minutes
- Surface forgotten garments — those not worn in 30+ days — at least once per week

---

## 3. Features — Master Specification

### Feature Priority Matrix

> Todas las funcionalidades están disponibles para Ana María desde el momento en que se implementan. La columna de fase indica cuándo se desarrolla, no cuándo se activa para ella.

| Feature | Priority | Complexity | Fase de desarrollo |
|---------|----------|------------|--------------------|
| Garment Upload (photo) | P0 | Medium | MVP |
| Background Removal | P0 | High | MVP |
| Auto-classification (CV) | P0 | High | MVP |
| Closet Grid View | P0 | Low | MVP |
| AI Outfit Recommendation | P0 | Very High | MVP |
| Garment Detail View | P0 | Low | MVP |
| Style Profile Onboarding | P0 | Medium | MVP |
| Weather Integration | P0 | Low | MVP |
| Mood-based Filtering | P0 | High | MVP |
| Filter & Search | P1 | Medium | V1 |
| Outfit Builder (canvas) | P1 | Medium | V1 |
| Outfit Calendar | P1 | Medium | V1 |
| Analytics Dashboard | P1 | Medium | V1 |
| Wishlist | P1 | Medium | V1 |
| AI Chat Stylist (Claude) | P2 | Very High | V2 |
| Style DNA Report completo | P2 | High | V1.5 |
| Packing Assistant | P2 | Medium | V1.5 |
| Virtual Try-On | P2 | Very High | V2 |
| Pinterest Integration | P2 | Medium | V2 |
| Moodboard Studio | P2 | Medium | V2 |
| Sustainability Score | P3 | Medium | V2 |
| Fashion AI Report anual | P3 | High | V2 |

---

### 3.1 Feature: Garment Upload & Digitization

#### Overview
The primary data-entry point. Must be frictionless, beautiful, and intelligent. Every moment of the upload flow is an editorial experience.

#### Upload Methods
1. **Camera Capture** — in-app camera with smart framing guides
2. **Photo Library** — multi-select from device gallery
3. **Drag & Drop** (web) — with visual drop zone
4. **Batch Import** — up to 20 items simultaneously

#### Capture Experience
- **Smart framing guide:** Animated border adjusts to suggest optimal positioning (ghost outline of garment type)
- **Auto-detect garment:** YOLO model detects when garment fills 60-80% of frame and auto-triggers capture
- **Multi-angle mode:** Prompts for front / back / detail shots with smooth transition
- **Quality validation:** Client-side blur detection rejects low-quality images before upload

#### Processing Pipeline
1. Image upload → S3 (raw)
2. Queue → AI worker (background removal via SAM/U2Net)
3. → CLIP embedding extraction
4. → Color palette extraction (K-means clustering)
5. → Fashion classification (category, subcategory, style)
6. → Texture / pattern detection
7. → Material estimation
8. → Tag generation
9. → Similarity indexing (Pinecone/Weaviate)
10. → Notification to client → garment appears in closet

#### Garment Data Model Fields

```
id:               uuid
user_id:          uuid
created_at:       timestamp
updated_at:       timestamp

# Visual
image_url_raw:    string      — original upload
image_url_processed: string  — background removed
image_url_thumb:  string     — 200x200 thumbnail
image_url_card:   string     — 400x600 card view
color_palette:    jsonb       — [{hex, name, percentage}]
dominant_color:   string     — hex
pattern:          enum        — solid / striped / plaid / floral / geometric / animal / abstract / graphic
texture:          enum        — smooth / ribbed / knit / denim / leather / silk / lace / velvet / tweed / other

# Classification
category:         enum        — tops / bottoms / dresses / outerwear / shoes / bags / jewelry / accessories / activewear / intimates / swimwear
subcategory:      string      — (shirt / blouse / crop top / turtleneck / etc.)
style_tags:       string[]    — auto-generated + user-editable
formality:        int         — 1-5 (1=casual, 5=black tie)
season:           string[]    — spring / summer / fall / winter / all

# AI-generated
ai_style_label:   string      — "minimalist blazer", "feminine midi", "structured office"
ai_confidence:    float       — 0.0-1.0
embedding:        vector(512) — CLIP embedding for similarity search
material_estimate: string[]   — ['cotton', 'polyester'] (estimated)
care_symbols:     string[]    — extracted from label if detected

# User-provided
name:             string      — optional custom name
brand:            string
purchase_date:    date
purchase_price:   decimal
currency:         string
condition:        enum        — excellent / good / fair / worn
notes:            text
occasions:        string[]    — user-tagged occasions

# Usage tracking
wear_count:       int         — incremented on outfit wear
last_worn:        date
favorite:         bool
archived:         bool
```

#### Empty State
When closet is empty:
- Editorial illustration: an elegant open wardrobe door, watercolor style
- Headline (serif): *"Your story begins here."*
- Subline: *"Add your first piece and let Crayoli learn your language."*
- CTA button: *"Add a Garment"*
- Secondary: *"Import from photos"*

---

### 3.2 Feature: Closet View

#### Layout Options (user-selectable)

**1. Grid View (default)**
- 2-column mobile / 3-column tablet / 4-column desktop
- Cards: 1:1.4 aspect ratio portrait images
- Card shows: processed garment image, subtle category label, wear count dot (appears on hover/press)
- On hover (web): smooth scale 1.0 → 1.03 + shadow elevation

**2. Mood Board View**
- Pinterest-style masonry layout
- Variable card heights based on garment type
- Categories float as soft labels above clusters

**3. List View**
- Compact horizontal: thumbnail (60x80) + metadata
- Best for management / editing tasks

**4. Rack View (premium future feature)**
- Horizontal scrollable rack simulation
- Garments displayed on white background as if hanging

#### Filter System

**Primary filters (pills, horizontally scrollable):**
Category / Color / Season / Occasion / Formality / Mood / Recently Added / Favorites / Unworn

**Advanced filters (bottom sheet on mobile, sidebar on desktop):**
- Color picker (palette-based, not text)
- Brand multi-select
- Price range (if entered)
- Last worn (date range)
- Wear count range
- Material
- Pattern

**Search:**
- Full-text across name, brand, tags, notes
- Visual search: "find similar to this" using embedding similarity
- Color search: pick a color → find garments in that palette

#### Sorting Options
- Recently added (default)
- Most worn
- Least worn (surfaces forgotten items)
- Alphabetical
- By color (palette-sorted, not alphabetical)
- By formality
- By purchase date

---

### 3.3 Feature: Garment Detail View

Full-screen immersive view of a single garment.

**Layout:**
- Hero: large processed image (background removed, on warm ivory canvas), pinch-to-zoom
- Swipeable image gallery if multiple angles uploaded
- Color palette strip below image — 4-5 dominant colors as circular swatches
- Scrollable content below

**Content sections:**
1. **Name & brand** — editable inline
2. **Category & tags** — chips, editable
3. **Style analysis** — AI-generated label + style notes ("This piece reads as structured minimalism with a contemporary edge.")
4. **Wear history** — visual timeline: dots on calendar, total count, last worn date
5. **Cost per wear** — computed: purchase_price / wear_count — shown elegantly as "You've worn this 12 times. Each wear costs $8.25."
6. **Compatible with** — horizontal scroll of garments that pair well (similarity-based)
7. **Outfits featuring this** — grid of past/saved outfits using this piece
8. **Care instructions** — icons + text
9. **Notes** — freeform text field

**Action buttons:**
- Wear Today (triggers outfit builder pre-seeded with this item)
- Edit Details
- Add to Outfit
- Mark as Favorite
- Archive (soft delete — moves to archive section)

---

### 3.4 Feature: AI Outfit Recommendation Engine

The crown jewel of Crayoli Closet. Must feel intelligent, personal, and surprising in the best way.

#### Recommendation Entry Points

1. **Daily Morning Card** — first thing on Home screen: "Good morning, Ana María. Here's what Crayoli suggests for today." + 3 outfits
2. **On-demand Generate** — explicit "Suggest an Outfit" action
3. **Event-driven** — "You have dinner on Thursday. Starting to think about what to wear?" 
4. **Mood selector** — choose a mood (soft girl / office / dinner / cozy) → get curated outfits
5. **Weather-triggered** — auto-surfaces weather-appropriate suggestions
6. **Forgotten item** — "We noticed this hasn't left the hanger in 45 days. Here's how to wear it today."

#### Recommendation Input Signals

| Signal | Weight | Source |
|--------|--------|--------|
| Weather (temperature, precipitation) | 0.20 | OpenWeatherMap API |
| Occasion / Event | 0.18 | Calendar + user input |
| User's explicit mood | 0.15 | Mood selector |
| Outfit history (avoid repetition) | 0.12 | wear_history table |
| Color harmony rules | 0.10 | Color theory engine |
| Formality match | 0.08 | Occasion formality mapping |
| Style DNA preferences | 0.08 | Learned profile |
| Item freshness (time since last worn) | 0.05 | Wear tracking |
| Season appropriateness | 0.04 | Season tags + date |

#### Output: Outfit Card

Each recommended outfit surfaces as a **Outfit Card** containing:
- 2–6 garment items (top / bottom / shoes / bag / accessory / outerwear)
- Layered visual composition: garments displayed as flat-lay collage
- Style name: AI-generated editorial label ("Effortless Monday", "Polished Afternoon", "Soft Evening")
- Context label: "For work / Cold morning / 12°C"
- Confidence badge (not shown as %, shown as: "Perfect Match" / "Great Match" / "Try Something New")
- Action: Save Outfit / Wear Today / Shuffle One Item / Regenerate

---

### 3.5 Feature: Outfit Builder (Manual)

Canvas-based outfit composition tool for creating and saving custom outfits.

**Interface:**
- Left sidebar: closet item browser (filtered by category)
- Center canvas: drop zone with snap-to-grid layout for outfit pieces
- Each item appears as processed image (no background) on a warm canvas
- Items can be layered, scaled, rotated slightly for editorial feel

**Behaviors:**
- Drag item from sidebar to canvas
- Tap item on canvas → inspect → swap (shows similar alternatives)
- Color harmony indicator: live badge (Harmonious / Complementary / Bold / Clash)
- Auto-suggest missing pieces: "Your outfit is missing shoes. Here are 3 options."
- Save as named outfit with cover photo option

---

### 3.6 Feature: Outfit Calendar

Weekly and monthly view planning system.

**Week View:**
- 7-column layout, each day shows planned outfit thumbnail or "+" to plan
- Today highlighted with champagne gold border
- Weather shown per day (temperature + icon)
- Swipe to next/previous week

**Outfit Assignment:**
- Tap a day → bottom sheet with 3 AI suggestions for that day's weather + occasion
- Or browse closet manually
- Or paste from saved outfits

**Alerts & Intelligence:**
- "You've worn this outfit 2 weeks ago. Still want to repeat?" (soft nudge, never shaming)
- "Rainy Tuesday ahead — your closet has these waterproof options."
- "Trip to Bogotá in 5 days — start planning your packing list?"

**Packing Assistant (V2):**
- Input: trip destination, dates, planned activities
- Output: packing list with specific garments from closet + suggestions for gaps

---

### 3.7 Feature: Analytics Dashboard

Premium fashion intelligence dashboard. Styled like a high-end magazine infographic.

**Sections:**

**1. Wardrobe Overview**
- Total items by category (donut chart, warm color palette)
- Wardrobe value (sum of purchase prices entered)
- Average cost per wear across all items

**2. Wear Heatmap**
- Calendar heatmap (GitHub-style but warm tones) — shows which days outfits were logged
- Top 5 most-worn pieces with photo + count + cost per wear
- Top 5 most-neglected pieces ("These deserve some love")

**3. Color DNA**
- Color palette visualization: which colors dominate your wardrobe vs. which you actually wear
- Gap analysis: "You own mostly neutral tones but you're wearing color more lately"

**4. Style Patterns**
- Formality distribution: what % of outfits are casual vs. formal
- Mood distribution: which moods appear most in outfit logs
- Season breakdown

**5. Shopping Intelligence (if prices entered)**
- Cost per wear ranking (most to least efficient)
- "Best investment" piece — lowest CPW
- "Consider retiring" — highest CPW + low recent use

---

### 3.8 Feature: Style Profile & Onboarding

The first 10 minutes of Crayoli are the most important. The onboarding is a ritual, not a form.

**Flow:**

**Step 1 — Welcome**
Serif headline: *"Welcome to Crayoli, Ana María."*
Subtext: *"This is your closet, reimagined. Let's build something beautiful together."*
Single CTA: *"Begin"*
[Duration: 3 seconds, then auto-advance or tap to continue]

**Step 2 — Style Identity (Aesthetic Quiz)**
"Which aesthetic feels most like you right now?"
Grid of 6 mood boards (3x2): each a curated collage of 4 images representing:
- Minimal Chic
- Soft Feminine
- Editorial Avant-garde
- Classic Tailored
- Casual Elevated
- Eclectic Maximalist

User selects 1-3. Multi-select with elegant toggle animation.

**Step 3 — Color Palette**
"Which colors feel most *you*?"
Circular color swatches in aesthetic groups:
- Neutrals (ivory / beige / camel / off-white)
- Earth (terracotta / olive / rust / mushroom)
- Monochromes (black / charcoal / white / gray)
- Pastels (blush / sage / lavender / powder blue)
- Jewel (emerald / sapphire / burgundy / deep plum)
- Bold (red / cobalt / saffron / electric)

**Step 4 — Lifestyle Context**
"What does a typical week look like for Ana María?"
Slider-based or multi-select:
- Work from office _% / Work from home _% / Creative field _% / Social/events _% / Casual lifestyle _%

**Step 5 — First Upload Prompt**
*"Now let's meet your wardrobe."*
Immediate upload prompt with enthusiasm:
- "Add your favorite piece first."
- OR: "Let me suggest a batch import to get started faster."

**Step 6 — Quick Win**
After first upload: AI immediately generates a 3-outfit suggestion using that single piece.
*"Look what we can do with just one piece. Imagine what's possible with your whole closet."*

**Data stored from onboarding:**
```
style_profile.aesthetic_tags[]
style_profile.color_preferences[]
style_profile.lifestyle_weights{}
style_profile.onboarding_completed_at
style_profile.initial_mood_board_selections[]
```

---

## 4. Non-Functional Requirements

### 4.1 Performance

| Metric | Target |
|--------|--------|
| App load time (cold start) | < 2.5s |
| Screen transition | < 200ms |
| Image upload → closet appearance | < 8s (background AI processing: < 60s) |
| Outfit recommendation generation | < 1.5s |
| Search response | < 300ms |
| Calendar render | < 500ms |

### 4.2 Reliability
- **Uptime SLA:** 99.9% (< 8.7h downtime/year)
- **Image storage durability:** 99.999999999% (S3 standard)
- **AI worker failure:** graceful degradation — garment appears unclassified, classification completes async

### 4.3 Security
- All data encrypted at rest (AES-256)
- All transit via TLS 1.3
- Images stored in private S3 with signed URL access (15-minute expiry)
- Zero third-party access to garment images
- GDPR-compliant data handling (right to deletion, export)

### 4.4 Accessibility
- WCAG 2.1 AA compliance
- Touch targets minimum 44x44px
- Color contrast ratio ≥ 4.5:1 for body text, ≥ 3:1 for large text
- Screen reader support (ARIA labels, semantic HTML)
- Reduced motion mode support

### 4.5 Offline Capability
- Closet browsable offline (cached grid)
- Outfit builder functional offline (no AI suggestions)
- Sync on reconnect
- Clear offline indicator in UI

---

## 5. User Flows

### 5.1 Core Flow: Upload → Classify → Closet

```
[Camera / Gallery]
       ↓
[Image capture / selection]
       ↓
[Client-side quality check] → [Reject: "Try a clearer photo"]
       ↓ (pass)
[Upload to S3 raw]
       ↓
[Optimistic UI: placeholder card appears in closet with shimmer]
       ↓ (async)
[AI Pipeline: remove bg → classify → embed → index]
       ↓
[WebSocket push: "Your item is ready!"]
       ↓
[Garment card refreshes with processed image + tags]
       ↓
[User can edit tags, add details]
```

### 5.2 Core Flow: Morning Outfit Recommendation

```
[App open / push notification 7:30am]
       ↓
[Home screen: "Good morning, Ana María. It's 14°C and partly cloudy."]
       ↓
[3 outfit cards presented: Primary / Alternative / Bold Pick]
       ↓
[User taps outfit card]
       ↓
[Full outfit view: each piece, style rationale, "Why Crayoli chose this"]
       ↓
[Actions: Wear Today / Save / Not feeling it (regenerate)]
       ↓
["Wear Today" → outfit logged → wear counts updated → calendar marked]
```

### 5.3 Core Flow: Mood-Based Outfit Selection

```
[User opens "Get dressed" / mood selector]
       ↓
[Mood selector: horizontal card scroll with aesthetic imagery]
       ↓
[User selects: "Dinner Date"]
       ↓
[System fetches: weather + calendar context + style profile]
       ↓
[AI generates 6 outfit options for "dinner + 20°C + Ana's aesthetic"]
       ↓
[Masonry grid of outfits with editorial labels]
       ↓
[Tap to expand → full outfit view → wear / save / modify]
```

---

*PRD v1.0 — Crayoli Product — Confidential*
