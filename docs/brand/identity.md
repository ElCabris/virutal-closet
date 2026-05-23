# Crayoli — Brand Identity System
**Version:** 1.0 | **Status:** Definitive | **Classification:** Internal Design System

---

## 1. Brand Philosophy

Crayoli exists at the intersection of personal identity and fashion intelligence. It is not merely a wardrobe organizer — it is a mirror of self, a companion that understands how clothes make people feel, not just how they look. Every design decision must honor this emotional contract.

The brand operates on a core tension: **technology that feels human**. Algorithms that whisper, not shout. Intelligence that serves without intruding. Luxury that doesn't exclude.

### Brand Pillars

| Pillar | Expression | Anti-Pattern |
|--------|-----------|--------------|
| **Intimacy** | Speaks directly to one person — Ana María | Never generic, never mass-market |
| **Intelligence** | Learns, adapts, anticipates — never feels robotic | No cold AI outputs, no tech-bro aesthetics |
| **Elegance** | Every pixel earns its place | No clutter, no noise, no decoration for decoration's sake |
| **Warmth** | Emotional resonance in every interaction | No clinical UX, no transactional tone |
| **Exclusivity** | Feels handcrafted for her specifically | Nothing that feels like a template |

### Brand Voice

- **Tone:** Warm, editorial, intimate. Like a fashion-forward best friend who also happens to be a genius.
- **Language register:** Sophisticated but never cold. Smart but never arrogant. Personal but never intrusive.
- **Copy style:** Short, intentional, often poetic. Every micro-copy is a small editorial moment.

**Examples of voice:**
- ✓ *"Your closet, curated by instinct and intelligence."*
- ✓ *"Seven looks for seven moods. Which Ana María shows up today?"*
- ✓ *"We noticed you haven't worn this in 47 days. Ready to rediscover it?"*
- ✗ *"Upload your clothes to get AI-powered recommendations."*
- ✗ *"87% match detected."*

---

## 2. Visual Identity

### 2.1 Logotype

**Primary wordmark:** `Crayoli`

- **Typeface base:** Custom adaptation of a high-contrast serif — inspired by Canela (Commercial Type) with subtle modifications
- **Character:** The `C` carries a gentle ink-trap at the counter. The `y` descender curves with intention. The `i` dot is replaced by a delicate filled ellipse — subtle femininity encoded in form.
- **Weight:** Light to Regular — never bold in primary lockup
- **Tracking:** +40 to +60 units for headline use; +80 for all-caps sub-uses

**Product wordmark:** `Crayoli Closet`
- "Crayoli" in serif, "Closet" in a geometric sans — weight contrast creates editorial hierarchy
- Stacked lockup for vertical use; horizontal lockup for header use

**Minimum size:** 80px width digital / 20mm print

### 2.2 Logo Symbol (Monogram Icon)

A minimal graphic mark: the letter `C` — reimagined as a partial circle with a subtle gap that suggests an open wardrobe hanger silhouette. The negative space within the `C` creates a hanger hook at the top. This icon works at 16px (favicon) and scales to full mural use.

**Do not:** rotate, stretch, add drop shadows, place on busy backgrounds without protective space

### 2.3 Color System

#### Primary Palette

```
Ivory Silk      #FAF8F5    RGB(250, 248, 245)    — Primary background
Warm Cream      #F5F0E8    RGB(245, 240, 232)    — Secondary background / cards
Blush Rose      #E8D5C4    RGB(232, 213, 196)    — Accent warm / hover states
Dusty Mauve     #C9A99A    RGB(201, 169, 154)    — Secondary accent
Nude Taupe      #B8A99A    RGB(184, 169, 154)    — Tertiary accent / dividers
```

#### Accent Palette

```
Champagne Gold  #D4AF82    RGB(212, 175, 130)    — Premium accent / CTAs
Antique Bronze  #9E7B5A    RGB(158, 123, 90)     — Active states / selected
Warm Black      #1C1A18    RGB(28, 26, 24)       — Primary text
Charcoal Soft   #3D3935    RGB(61, 57, 53)       — Secondary text
Stone Gray      #8A857F    RGB(138, 133, 127)    — Tertiary text / placeholders
```

#### Semantic Palette

```
Success Sage    #7A9E7E    RGB(122, 158, 126)    — Confirmations, saved states
Alert Amber     #C4924A    RGB(196, 146, 74)     — Warnings (never harsh orange)
Error Blush     #C47A7A    RGB(196, 122, 122)    — Errors (never harsh red)
Info Lavender   #9A9EC4    RGB(154, 158, 196)    — Informational states
```

#### Dark Mode Adaptation

```
Deep Charcoal   #16140F    — Background primary
Dark Warm       #1F1D17    — Background secondary
Warm Zinc       #2A2720    — Card surfaces
Muted Cream     #E8E0D0    — Primary text in dark
Faded Gold      #C4A070    — Accents in dark
```

### 2.4 Typography System

#### Type Hierarchy

**Display / Brand (Serif)**
- Family: `Canela` (preferred) or `Cormorant Garamond` (open-source fallback)
- Use: Hero headlines, splash screen, section titles
- Weights available: Light (300), Regular (400), Medium (500)
- Sizes: 48px / 56px / 64px / 96px
- Line height: 1.1 — 1.2
- Letter spacing: -0.5px to -1px at large sizes

**Heading / Interface (Sans)**
- Family: `Inter` (variable) — primary interface font
- Weights: 300 / 400 / 500 / 600
- Sizes: 32px H1 / 24px H2 / 20px H3 / 18px H4 / 16px H5
- Line height: 1.3 — 1.4

**Body / Reading**
- Family: `Inter` 400
- Size: 15px — 16px
- Line height: 1.6 — 1.7
- Max line length: 65ch

**Label / UI**
- Family: `Inter` 500
- Size: 11px — 13px
- Letter spacing: +0.04em — +0.08em (all-caps labels at +0.12em)

**Editorial Accent**
- Family: `Cormorant Garamond` Italic
- Use: Quotes, mood descriptors, AI-generated style personas
- Sizes: 18px — 24px

#### Type Scale (Base 16px, ratio 1.25)

```
xs:  11px
sm:  13px
md:  16px  ← base
lg:  20px
xl:  25px
2xl: 31px
3xl: 39px
4xl: 49px
5xl: 61px
6xl: 76px
```

### 2.5 Spacing & Layout

**Base unit:** 4px
**Grid:** 8px base grid — all spacing in multiples of 4px or 8px

```
Spacing scale:
  1  →  4px
  2  →  8px
  3  →  12px
  4  →  16px
  5  →  20px
  6  →  24px
  8  →  32px
 10  →  40px
 12  →  48px
 16  →  64px
 20  →  80px
 24  →  96px
```

**Content max-width:** 1440px  
**Content column max-width:** 1200px  
**Reading column max-width:** 680px  

**Container padding:**
- Mobile: 16px — 20px
- Tablet: 32px — 40px
- Desktop: 64px — 80px

### 2.6 Border Radius System

```
none:  0px       — strict tables, dividers
xs:    4px       — tags, small chips
sm:    8px       — buttons secondary
md:    12px      — input fields, small cards
lg:    16px      — standard cards
xl:    20px      — large cards
2xl:   24px      — modal containers
3xl:   32px      — hero cards
full:  9999px    — pills, avatars, toggles
```

### 2.7 Shadow System

All shadows use warm-toned base (not pure black):

```
shadow-xs:  0 1px 2px rgba(28, 26, 24, 0.04)
shadow-sm:  0 2px 8px rgba(28, 26, 24, 0.06), 0 1px 2px rgba(28, 26, 24, 0.04)
shadow-md:  0 4px 16px rgba(28, 26, 24, 0.08), 0 2px 4px rgba(28, 26, 24, 0.04)
shadow-lg:  0 8px 32px rgba(28, 26, 24, 0.10), 0 4px 8px rgba(28, 26, 24, 0.06)
shadow-xl:  0 16px 48px rgba(28, 26, 24, 0.12), 0 8px 16px rgba(28, 26, 24, 0.08)
shadow-2xl: 0 24px 64px rgba(28, 26, 24, 0.16), 0 12px 24px rgba(28, 26, 24, 0.10)

shadow-glow-gold: 0 0 24px rgba(212, 175, 130, 0.20)   — premium highlight
shadow-inner-soft: inset 0 2px 8px rgba(28, 26, 24, 0.04) — input fields
```

### 2.8 Glassmorphism Components

Applied selectively for premium depth:

```css
/* Navigation overlay / modal backdrops */
backdrop-filter: blur(24px) saturate(1.4);
background: rgba(250, 248, 245, 0.85);
border: 1px solid rgba(250, 248, 245, 0.6);
box-shadow: 0 8px 32px rgba(28, 26, 24, 0.08);

/* Dark mode glass */
backdrop-filter: blur(24px) saturate(1.2);
background: rgba(22, 20, 15, 0.80);
border: 1px solid rgba(255, 255, 255, 0.08);
```

### 2.9 Iconography

- **Primary set:** Custom Crayoli icon library — thin stroke (1.5px), rounded terminals, 24px base grid
- **Fallback:** Phosphor Icons (thin variant) — geometrically clean, feminine line quality
- **Icon sizes:** 16px / 20px / 24px / 32px / 48px
- **Color:** Never pure black — use `Warm Black #1C1A18` or `Stone Gray #8A857F`

### 2.10 Illustration & Imagery Style

**Photography:**
- Editorial quality — studio white or lifestyle neutral backgrounds
- Natural light, warm tones, never harsh contrast
- Models absent unless intentional (focus on garment, not body prescription)
- Garment on flat lay: textured backgrounds (linen, marble, soft wood)
- Garment floating: removed background with subtle shadow

**Illustration:**
- Minimal line art, single weight, warm ink color (`#3D3935`)
- Used for empty states, onboarding, error states
- Style: editorial fashion sketch — gestural, not cartoony

**Pattern / Texture:**
- Subtle grain overlay (3–8% opacity) on hero backgrounds
- Linen texture on certain card backgrounds
- Never busy — texture should whisper

### 2.11 Motion & Animation

**Animation philosophy:** Motion communicates state and hierarchy, never decoration.

**Duration tokens:**
```
instant:  0ms     — no transition needed
fast:     150ms   — hover states, toggle flips
normal:   250ms   — standard transitions
slow:     400ms   — modals, page transitions
slower:   600ms   — hero entrances
cinematic: 800ms+ — onboarding, splash
```

**Easing tokens:**
```
ease-out-soft:   cubic-bezier(0.0, 0.0, 0.2, 1.0)   — elements entering
ease-in-soft:    cubic-bezier(0.4, 0.0, 1.0, 1.0)   — elements leaving
ease-spring:     cubic-bezier(0.34, 1.56, 0.64, 1.0) — interactive feedback
ease-premium:    cubic-bezier(0.16, 1.0, 0.3, 1.0)  — hero animations
ease-silky:      cubic-bezier(0.25, 0.46, 0.45, 0.94) — content loads
```

**Motion principles:**
- Enter: fade + translate Y(-8px → 0) — content drifts in from above
- Exit: fade + scale(1 → 0.97) — content recedes
- Cards: on hover, translate Y(-4px) + shadow increase
- Garment reveal: clip-path wipe from bottom + blur clear
- Loading skeleton: shimmer right-to-left with warm gradient

---

## 3. Brand Applications

### 3.1 App Icon

- Background: `Ivory Silk #FAF8F5` with subtle radial gradient toward `Warm Cream`
- Foreground: Crayoli `C` monogram in `Warm Black #1C1A18`
- Corner radius: follows platform guidelines (iOS: ~22% of size, Android: 20%)
- No shadow within the icon — the icon surface itself suggests depth through the monogram

### 3.2 Splash Screen

- Full-bleed `Ivory Silk` background
- Centered `Crayoli` wordmark (serif, light weight, 40px)
- Beneath: subtle tagline in `Stone Gray` — "Your closet, curated."
- Animation: wordmark fades in with letter-by-letter stagger (25ms delay per character)
- Duration: 1.8s total, then cross-fade to onboarding

### 3.3 Loading States

**Global skeleton loader:**
- Warm gray shimmer: from `#F0EBE4` to `#FAF8F5` to `#F0EBE4`
- Direction: left to right
- Duration: 1.4s infinite
- Shapes match content structure (card, image block, text lines)

**AI Processing state (garment analysis):**
- Animated gradient ring around garment thumbnail (champagne gold → blush rose → champagne gold)
- Small label: "Analyzing texture and style..." — cycles through analysis stages
- Do not show a percentage — suggests determinism; show elegance instead

---

## 4. Design Tokens (CSS Custom Properties)

```css
:root {
  /* Colors */
  --color-background-primary:   #FAF8F5;
  --color-background-secondary: #F5F0E8;
  --color-background-tertiary:  #EDE7DC;

  --color-surface-card:         #FFFFFF;
  --color-surface-overlay:      rgba(250, 248, 245, 0.92);

  --color-text-primary:         #1C1A18;
  --color-text-secondary:       #3D3935;
  --color-text-tertiary:        #8A857F;
  --color-text-disabled:        #B8B3AD;
  --color-text-inverse:         #FAF8F5;

  --color-accent-primary:       #D4AF82;
  --color-accent-secondary:     #9E7B5A;
  --color-accent-blush:         #E8D5C4;
  --color-accent-mauve:         #C9A99A;

  --color-border-subtle:        rgba(28, 26, 24, 0.06);
  --color-border-default:       rgba(28, 26, 24, 0.10);
  --color-border-strong:        rgba(28, 26, 24, 0.20);

  --color-success:              #7A9E7E;
  --color-warning:              #C4924A;
  --color-error:                #C47A7A;
  --color-info:                 #9A9EC4;

  /* Typography */
  --font-serif:    'Canela', 'Cormorant Garamond', Georgia, serif;
  --font-sans:     'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono:     'JetBrains Mono', 'Fira Code', monospace;

  /* Spacing */
  --space-1:  4px;
  --space-2:  8px;
  --space-3:  12px;
  --space-4:  16px;
  --space-5:  20px;
  --space-6:  24px;
  --space-8:  32px;
  --space-10: 40px;
  --space-12: 48px;
  --space-16: 64px;
  --space-20: 80px;
  --space-24: 96px;

  /* Border radius */
  --radius-xs:   4px;
  --radius-sm:   8px;
  --radius-md:   12px;
  --radius-lg:   16px;
  --radius-xl:   20px;
  --radius-2xl:  24px;
  --radius-3xl:  32px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-xs:  0 1px 2px rgba(28, 26, 24, 0.04);
  --shadow-sm:  0 2px 8px rgba(28, 26, 24, 0.06), 0 1px 2px rgba(28, 26, 24, 0.04);
  --shadow-md:  0 4px 16px rgba(28, 26, 24, 0.08), 0 2px 4px rgba(28, 26, 24, 0.04);
  --shadow-lg:  0 8px 32px rgba(28, 26, 24, 0.10), 0 4px 8px rgba(28, 26, 24, 0.06);
  --shadow-xl:  0 16px 48px rgba(28, 26, 24, 0.12), 0 8px 16px rgba(28, 26, 24, 0.08);

  /* Animation */
  --duration-fast:   150ms;
  --duration-normal: 250ms;
  --duration-slow:   400ms;
  --duration-slower: 600ms;

  --ease-out-soft:  cubic-bezier(0.0, 0.0, 0.2, 1.0);
  --ease-spring:    cubic-bezier(0.34, 1.56, 0.64, 1.0);
  --ease-premium:   cubic-bezier(0.16, 1.0, 0.3, 1.0);
  --ease-silky:     cubic-bezier(0.25, 0.46, 0.45, 0.94);

  /* Z-index */
  --z-base:     0;
  --z-raised:   10;
  --z-dropdown: 100;
  --z-sticky:   200;
  --z-overlay:  300;
  --z-modal:    400;
  --z-toast:    500;
  --z-tooltip:  600;
}
```

---

*Identity System v1.0 — Crayoli Brand Studio — 2026*
