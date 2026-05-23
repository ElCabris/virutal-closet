# Crayoli Closet — Screen Specifications
**Version:** 1.0 | **Scope:** All primary screens | **Design Standard:** Premium Editorial

---

## Screen Inventory

| Screen | Route | Auth Required |
|--------|-------|--------------|
| Splash | / | No |
| Onboarding | /onboarding | No |
| Login | /login | No |
| Signup | /signup | No |
| Home | /home | Yes |
| Closet | /closet | Yes |
| Garment Detail | /closet/:id | Yes |
| Outfit Builder | /builder | Yes |
| Outfit Detail | /outfits/:id | Yes |
| AI Recommendations | /discover | Yes |
| Calendar | /calendar | Yes |
| Analytics | /analytics | Yes |
| Profile | /profile | Yes |
| Settings | /settings | Yes |
| Wishlist | /wishlist | Yes |
| Style Explorer | /explore | Yes |

---

## Screen 1: Splash Screen

### Purpose
Brand first impression. Creates emotional tone for entire experience.

### Layout
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│          ┌─────────┐           │
│          │  LOGO   │           │
│          └─────────┘           │
│                                 │
│         C R A Y O L I          │
│                                 │
│      Your closet, curated.      │
│                                 │
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

### Specifications
- **Background:** Full bleed `Ivory Silk #FAF8F5` — no image, pure warmth
- **Logo:** Crayoli monogram centered, 64px, `Warm Black #1C1A18`
- **Wordmark:** "CRAYOLI" in serif light, letter-spacing +60, 28px, centered — staggered letter fade-in (25ms per character)
- **Tagline:** "Your closet, curated." — Inter 400, 14px, `Stone Gray #8A857F`, fades in after wordmark complete
- **Duration:** 2.2s → cross-fade to next screen
- **Haptic:** Subtle impact on iOS at brand reveal (style: `UIImpactFeedbackGenerator.light`)
- **No skip button** — experience is only 2.2s, interruption breaks ritual

### Animation Sequence
```
t=0ms:    Background renders (instant)
t=200ms:  Logo fades in (300ms, ease-out-soft)
t=600ms:  "C" fades in
t=625ms:  "R" fades in
t=650ms:  "A" fades in  [continues per character]
t=800ms:  All letters present
t=1100ms: Tagline fades in (400ms)
t=1800ms: Hold
t=2000ms: Full screen fades out (300ms)
```

---

## Screen 2: Onboarding

### Purpose
Style profiling ritual. Establishes Style DNA foundation. Creates emotional investment.

### Flow Structure
5 steps with progress indicator (minimal: 5 dots, not numbered labels)

### Step 2.1 — Welcome
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│      Welcome to Crayoli,        │
│       Ana María.                │ ← Serif, 32px, 2-line break
│                                 │
│   This is your closet,          │
│   reimagined. Let's build       │ ← Inter 400, 16px, Stone Gray
│   something beautiful           │
│   together.                     │
│                                 │
│                                 │
│                                 │
│    ┌─────────────────────┐      │
│    │       Begin         │      │ ← Full-width CTA, champagne gold
│    └─────────────────────┘      │
│                                 │
│       ○ ○ ○ ○ ○               │ ← Progress dots
└─────────────────────────────────┘
```

**Background:** subtle radial gradient from `#FAF8F5` center to `#F5F0E8` edges

### Step 2.2 — Aesthetic Selection
```
┌─────────────────────────────────┐
│                                 │
│   Which aesthetic feels         │
│   most like you right now?      │ ← Serif 26px
│                                 │
│   Select 1 to 3.                │ ← Inter 13px, Stone Gray
│                                 │
│  ┌──────────┐ ┌──────────┐    │
│  │ Mood Img │ │ Mood Img │    │ ← 2-col grid, 1:1.3 cards
│  │          │ │          │    │
│  │ Minimal  │ │ Soft     │    │
│  │ Chic     │ │ Feminine │    │
│  └──────────┘ └──────────┘    │
│                                 │
│  ┌──────────┐ ┌──────────┐    │
│  │ Mood Img │ │ Mood Img │    │
│  │          │ │          │    │
│  │ Editorial│ │ Classic  │    │
│  │ Avant-g. │ │ Tailored │    │
│  └──────────┘ └──────────┘    │
│                                 │
│  ┌──────────┐ ┌──────────┐    │
│  │ Mood Img │ │ Mood Img │    │
│  │          │ │          │    │
│  │ Casual   │ │ Eclectic │    │
│  │ Elevated │ │ Maximali.│    │
│  └──────────┘ └──────────┘    │
│                                 │
│    ┌─────────────────────┐     │
│    │    Continue →       │     │
│    └─────────────────────┘     │
└─────────────────────────────────┘
```

**Card selection state:** champagne gold border (2px) + `shadow-glow-gold` + checkmark badge top-right

### Step 2.3 — Color Palette
```
┌─────────────────────────────────┐
│                                 │
│   Which colors feel             │
│   most *you*?                   │ ← "you" in italic
│                                 │
│   NEUTRALS                      │ ← Label 11px, +0.12em tracking
│   ○ ○ ○ ○ ○                    │ ← Color circle row, 44px each
│                                 │
│   EARTH TONES                   │
│   ○ ○ ○ ○ ○                    │
│                                 │
│   MONOCHROMES                   │
│   ○ ○ ○ ○ ○                    │
│                                 │
│   PASTELS                       │
│   ○ ○ ○ ○ ○                    │
│                                 │
│   JEWEL TONES                   │
│   ○ ○ ○ ○ ○                    │
│                                 │
│    ┌─────────────────────┐     │
│    │    Continue →       │     │
│    └─────────────────────┘     │
└─────────────────────────────────┘
```

**Color circle:** 44px circle, selected state = 3px gold ring + scale 1.0→1.15 spring animation

### Step 2.4 — Lifestyle Context
Simple, not clinical:

```
┌─────────────────────────────────┐
│                                 │
│   How does life look for        │
│   Ana María, typically?         │
│                                 │
│   I spend most of my time:      │
│                                 │
│   ┌──────────────────────────┐  │
│   │ [☐] At the office        │  │
│   │ [☐] Working from home    │  │
│   │ [☐] In creative spaces   │  │
│   │ [☐] At social events     │  │
│   │ [☐] Outdoors / travel    │  │
│   │ [☐] A bit of everything  │  │
│   └──────────────────────────┘  │
│                                 │
│    ┌─────────────────────┐     │
│    │    Continue →       │     │
│    └─────────────────────┘     │
└─────────────────────────────────┘
```

### Step 2.5 — First Upload Invitation
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│      ┌────────────────────┐    │
│      │                    │    │ ← Illustration: open wardrobe
│      │   [Illustration]   │    │   with single glowing hanger
│      │                    │    │
│      └────────────────────┘    │
│                                 │
│    Now let's meet your          │
│    wardrobe.                    │
│                                 │
│    Add your favorite piece      │
│    first — the one that makes   │
│    you feel most like you.      │
│                                 │
│    ┌─────────────────────┐     │
│    │   Add a Garment     │     │ ← Primary CTA
│    └─────────────────────┘     │
│                                 │
│    ─────── or ──────────       │
│                                 │
│    Import from my photos        │ ← Secondary text link
│                                 │
└─────────────────────────────────┘
```

---

## Screen 3: Login / Signup

### Design Philosophy
One unified flow. Clean, minimal, focused. No clutter.

```
┌─────────────────────────────────┐
│                                 │
│  ← Back                        │
│                                 │
│                                 │
│      C R A Y O L I             │ ← Small wordmark, 20px
│                                 │
│                                 │
│   Welcome back.                 │ ← Serif 32px (Login)
│   — or —                       │
│   Create your closet.           │ ← Serif 32px (Signup)
│                                 │
│   ┌──────────────────────────┐  │
│   │ Email address            │  │ ← Inter 15px, rounded-lg
│   └──────────────────────────┘  │
│                                 │
│   ┌──────────────────────────┐  │
│   │ Password          [eye]  │  │
│   └──────────────────────────┘  │
│                                 │
│   Forgot password?              │ ← Right-aligned, 13px, Taupe
│                                 │
│   ┌──────────────────────────┐  │
│   │      Continue            │  │ ← Full-width, Champagne Gold bg
│   └──────────────────────────┘  │
│                                 │
│   ──────── or ──────────       │
│                                 │
│   ┌──────────────────────────┐  │
│   │  [G]  Continue with      │  │
│   │       Google             │  │
│   └──────────────────────────┘  │
│                                 │
│   ┌──────────────────────────┐  │
│   │  [A]  Continue with      │  │
│   │       Apple              │  │
│   └──────────────────────────┘  │
│                                 │
│   Don't have an account?        │
│   Sign up.                      │ ← Inline link
└─────────────────────────────────┘
```

**Input field specs:**
- Height: 52px
- Border: 1px `#E8E2DA` at rest / 2px `#D4AF82` focused / 2px `#C47A7A` error
- Background: `#FFFFFF` light / `#1F1D17` dark
- Padding: 16px horizontal
- Border radius: 12px
- Focus animation: border color transition 200ms + subtle shadow appear

---

## Screen 4: Home

### Purpose
Command center. Daily ritual. First screen after login. Personalized, warm, purposeful.

### Layout — Mobile
```
┌─────────────────────────────────┐
│ [Avatar] Good morning,     [🔔] │ ← Greeting bar, 64px height
│          Ana María.             │
│          Tuesday, 14°C 🌥       │
├─────────────────────────────────┤
│                                 │
│  TODAY'S SUGGESTION             │ ← Section label 11px tracking
│                                 │
│  ┌───────────────────────────┐  │
│  │  [Outfit visual collage]  │  │
│  │                           │  │ ← Large card, 16:9
│  │  Effortless Tuesday       │  │
│  │  For light work + lunch   │  │
│  │                           │  │
│  │  [Wear Today] [Save]      │  │
│  └───────────────────────────┘  │
│                                 │
│  ● ○ ○  (swipe for more)       │
│                                 │
├─────────────────────────────────┤
│                                 │
│  YOUR CLOSET AT A GLANCE        │
│                                 │
│  [Top] [Bottom] [Shoes] [All]  │ ← Category pills
│                                 │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ [+]     │ ← 4-item recent grid + add
│  └──┘ └──┘ └──┘ └──┘         │
│                                 │
├─────────────────────────────────┤
│                                 │
│  HAVEN'T WORN IN A WHILE        │
│                                 │
│  ┌──────────────────────────┐  │
│  │ [Item image]             │  │
│  │ Linen blazer · 62 days   │  │ ← Rediscovery card
│  │ Pair it with →           │  │
│  └──────────────────────────┘  │
│                                 │
├─────────────────────────────────┤
│                                 │
│  UPCOMING                       │
│                                 │
│  Thu  Dinner at Laurel   →     │ ← Calendar event card
│  Sat  Weekend in Medellin →    │
│                                 │
└─────────────────────────────────┘
```

**Bottom Navigation:**
```
┌────────────────────────────────────────────────────┐
│  [Home]   [Closet]   [+]   [Discover]  [Profile]  │
│   ●          ○       ○        ○           ○        │
└────────────────────────────────────────────────────┘
```
- Active tab: filled icon + label + `Champagne Gold` dot indicator
- Center `+` button: elevated (shadow-lg) + `Warm Black` background
- Tap `+`: bottom sheet with: "Add Garment" / "Build Outfit" / "Plan Week"

### Layout — Desktop (Web)
Sidebar navigation (260px) + main content area:
```
┌──────────────┬─────────────────────────────────────────┐
│              │                                         │
│  CRAYOLI     │  Good morning, Ana María.               │
│              │  Tuesday · 14°C · Partly Cloudy         │
│  [Avatar]    │                                         │
│  Ana María   ├──────────────────────────────────────── │
│              │                                         │
│  ─────────   │  TODAY'S SUGGESTIONS          [Refresh] │
│  Home    ●   │                                         │
│  Closet      │  ┌───────────┐ ┌───────────┐ ┌───────┐ │
│  Discover    │  │  Outfit 1 │ │  Outfit 2 │ │ Out 3 │ │
│  Calendar    │  │           │ │           │ │       │ │
│  Analytics   │  │  Effortl. │ │  Polished │ │ Bold  │ │
│  ─────────   │  └───────────┘ └───────────┘ └───────┘ │
│  Settings    │                                         │
│              │  YOUR WARDROBE SNAPSHOT                 │
└──────────────┴─────────────────────────────────────────┘
```

---

## Screen 5: Closet

### Layout — Mobile Grid (default)
```
┌─────────────────────────────────┐
│  ← My Closet         [⚙][+]   │ ← Header
│                                 │
│  [All] [Tops] [Bottoms] [Shoes]│ ← Category filter pills (scroll)
│  [Bags] [Outerwear] [Acc]      │
│                                 │
│  ┌────────────┐ ┌────────────┐ │ ← 2-col grid
│  │            │ │            │ │
│  │  [Garment] │ │  [Garment] │ │ ← 1:1.4 ratio
│  │            │ │            │ │
│  │  Silk top  │ │  Midi skirt│ │ ← Name below
│  │  ♡  💛💙  │ │  ♡  💛    │ │ ← Fav + colors
│  └────────────┘ └────────────┘ │
│                                 │
│  ┌────────────┐ ┌────────────┐ │
│  │  [Garment] │ │  [Garment] │ │
│  │            │ │            │ │
│  └────────────┘ └────────────┘ │
│                                 │
│  [Sort ▾]  [Filter]  [Search🔍]│ ← Bottom action bar
└─────────────────────────────────┘
```

**Card anatomy:**
- Background: `#FFFFFF` with `shadow-sm`
- Image: processed (no background) on `Ivory Silk` canvas, top 75% of card
- Name: Inter 500, 12px, `Charcoal Soft`, truncated 1 line
- Color dots: 3 circular swatches (8px), dominant colors
- Favorite heart: top-right corner, filled = `Dusty Mauve`
- Wear count badge: bottom-left, appears only if > 0: "worn 5x" in 10px chip

**Swipe actions on card (mobile):**
- Swipe left: archive action (with confirmation)
- Swipe right: add to today's outfit

**Long press:** multi-select mode activates

---

## Screen 6: Garment Detail

### Layout
```
┌─────────────────────────────────┐
│  ←            [Edit] [•••]     │ ← Back + actions
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │    [Garment Image]      │   │ ← 1:1.2 hero, pinch-to-zoom
│  │    on ivory canvas      │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  ● ○ ○  (image gallery)        │
│                                 │
│  ─────────────────────────── │
│  ████ ████ ██ ██             │ ← Color palette strip
│  ─────────────────────────── │
│                                 │
│  White Silk Blouse              │ ← Name, serif 22px
│  COS · Added March 2025         │ ← Brand + date, 12px stone gray
│                                 │
│  ┌──────────┬──────────┐       │
│  │ Worn     │ Cost/Wear│       │
│  │ 12 times │  $8.25   │       │
│  └──────────┴──────────┘       │
│                                 │
│  STYLE ANALYSIS                 │
│  "Structured minimalism with    │
│  a contemporary edge —          │ ← AI description, italic serif
│  versatile from AM to PM."      │
│                                 │
│  PAIRS WELL WITH                │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ →       │ ← Horizontal scroll, 72px cards
│  └──┘ └──┘ └──┘ └──┘         │
│                                 │
│  WEAR HISTORY                   │
│  [Calendar heatmap mini]        │
│  Last worn: 12 days ago         │
│                                 │
│  ┌─────────────────────────┐   │
│  │     Wear Today          │   │ ← Primary CTA
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## Screen 7: AI Recommendations (Discover)

### Layout — "For You" Feed
```
┌─────────────────────────────────┐
│  Discover                  [⚙] │
│                                 │
│  [For You] [Trending] [Moods]   │ ← Tab row
│  ─────────                      │
│                                 │
│  Outfits for today              │
│  Tuesday · 14°C · Partly cloudy │
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │   [Outfit Collage]      │   │ ← Large card, 4:5 ratio
│  │                         │   │
│  │   ┌──┐ ┌──┐ ┌──┐ ┌──┐ │   │ ← Item thumbnails
│  │   └──┘ └──┘ └──┘ └──┘ │   │
│  │   Polished Morning      │   │ ← Outfit name, serif
│  │   For light office      │   │ ← Context
│  │   ♡ Save   ▶ Wear      │   │ ← Actions
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │   [Outfit Collage 2]    │   │
│  │   ...                   │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

### Layout — Mood Selector
```
┌─────────────────────────────────┐
│  What's the vibe today?         │ ← Serif 24px
│                                 │
│  ┌────────────┐ ┌────────────┐ │
│  │ [Image]    │ │ [Image]    │ │ ← Mood cards 2x2 grid
│  │            │ │            │ │
│  │ Soft Girl  │ │ Office     │ │
│  └────────────┘ └────────────┘ │
│                                 │
│  ┌────────────┐ ┌────────────┐ │
│  │ [Image]    │ │ [Image]    │ │
│  │            │ │            │ │
│  │ Dinner     │ │ Cozy       │ │
│  └────────────┘ └────────────┘ │
│                                 │
│  ┌────────────┐ ┌────────────┐ │
│  │ [Image]    │ │ [Image]    │ │
│  │            │ │            │ │
│  │ Academia   │ │ Travel     │ │
│  └────────────┘ └────────────┘ │
│                                 │
│  ┌────────────┐ ┌────────────┐ │
│  │ [Image]    │ │ [Image]    │ │
│  │            │ │            │ │
│  │ Streetwear │ │ Elegant    │ │
│  └────────────┘ └────────────┘ │
└─────────────────────────────────┘
```

---

## Screen 8: Outfit Builder

### Layout
```
┌─────────────────────────────────┐
│  ← Builder      [Save] [Share]  │
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │   [CANVAS AREA]         │   │ ← 3:4 canvas, ivory bg
│  │                         │   │
│  │   Drag items here       │   │ ← Empty state text
│  │                         │   │
│  │   [Item 1] [Item 2]     │   │ ← Dropped items
│  │     [Item 3]            │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  Color: Harmonious ●           │ ← Live harmony indicator
│                                 │
│  ─────────────────────────     │
│                                 │
│  [Tops]  [Bottoms]  [Shoes]    │ ← Category tabs
│  [Bags]  [Outerwear]           │
│                                 │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐   │ ← Item grid (drag to canvas)
│  └──┘ └──┘ └──┘ └──┘ └──┘   │
│                                 │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐   │
│  └──┘ └──┘ └──┘ └──┘ └──┘   │
│                                 │
│  AI: Suggest missing piece →   │ ← AI suggestion strip
└─────────────────────────────────┘
```

---

## Screen 9: Analytics Dashboard

### Layout — Mobile
```
┌─────────────────────────────────┐
│  Style Analytics                │ ← Serif 24px
│                                 │
│  ┌─────────────────────────┐   │
│  │  WARDROBE OVERVIEW      │   │
│  │                         │   │
│  │  [Donut chart]          │   │ ← Category distribution
│  │                         │   │
│  │  142 pieces total       │   │
│  │  Est. value: $8,240     │   │
│  │  Avg CPW: $12.30        │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  MOST LOVED             │   │
│  │  ┌──┐  White blouse     │   │
│  │  └──┘  Worn 28 times    │   │
│  │        CPW: $3.57       │   │
│  │  ─────────────          │   │
│  │  ┌──┐  Black trousers   │   │
│  │  └──┘  Worn 22 times    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  FORGOTTEN GEMS         │   │
│  │  These deserve love:    │   │
│  │  ┌──┐ ┌──┐ ┌──┐ ┌──┐ │   │
│  │  └──┘ └──┘ └──┘ └──┘ │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  YOUR COLOR DNA         │   │
│  │  [Palette visualization]│   │
│  │  60% neutrals           │   │
│  │  20% earth tones        │   │
│  │  15% monochromes        │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## Screen 10: Calendar

```
┌─────────────────────────────────┐
│  ← May 2026              [+]   │
│                                 │
│  Mo Tu We Th Fr Sa Su          │ ← Week headers
│                                 │
│  ┌──────────────────────────┐  │
│  │ 18   19   20   21  22   │  │ ← Week row
│  │ [o]  [o]  [?]  [?] [+]  │  │ o=planned outfit, ?=suggest, +=add
│  └──────────────────────────┘  │
│                                 │
│  TODAY — Tuesday, May 20        │ ← Expanded day view below
│  14°C · Partly Cloudy           │
│                                 │
│  ┌─────────────────────────┐   │
│  │ [Outfit thumbnail]      │   │
│  │ Polished Tuesday        │   │ ← Planned outfit for today
│  │ Edit →                  │   │
│  └─────────────────────────┘   │
│                                 │
│  UPCOMING                       │
│  ─────────                      │
│  Thu 22 · Dinner at Laurel      │
│  [3 outfit suggestions] →       │
│                                 │
│  Sat 24 · Weekend trip          │
│  [Start packing list] →         │
│                                 │
└─────────────────────────────────┘
```

---

## Responsive Breakpoints

```
Mobile:       < 768px   — single column, bottom nav
Tablet:       768–1024px — 2-3 columns, adapted layouts
Desktop:      > 1024px  — sidebar nav, full multi-column layouts
Large:        > 1440px  — max-width container, editorial spacing
```

### Responsive Behavior per Screen

| Screen | Mobile | Tablet | Desktop |
|--------|--------|--------|---------|
| Closet | 2-col grid | 3-col grid | 4-5 col grid + sidebar filters |
| Home | Stacked cards | 2-col cards | 3-col + sidebar |
| Garment Detail | Full-screen | 2-panel (image + info) | 3-panel (image + info + related) |
| Outfit Builder | Bottom sheet items | Side panel items | Side panel + canvas |
| Analytics | Stacked sections | 2-col cards | Dashboard grid |
| Calendar | Week + day list | Month + week | Full month + detail panel |

---

*Screen Specifications v1.0 — Crayoli Product Design*
