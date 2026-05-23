# Crayoli Closet — UX Flows & Microinteractions
**Version:** 1.0 | **Standard:** Premium Digital Experience

---

## 1. UX Philosophy

Every interaction in Crayoli Closet is an opportunity to reinforce the brand's emotional promise: **intelligence that feels human, technology that feels warm.**

### Five UX Principles

**1. Delight in the mundane**
Uploading a garment should feel like unwrapping something beautiful. Logging a wear should feel like journaling. Even a loading state should have intention.

**2. Intelligence without intrusion**
The AI shows up when it adds value, disappears when it doesn't. Recommendations are suggestions, never demands. Learning happens silently.

**3. Texture over flatness**
Layers, depth, shadows, transitions — the interface has physical weight. Interactions have tactile feedback. Nothing feels like tapping a piece of glass.

**4. Every empty state earns its place**
An empty closet is not a failure. It's an invitation. Every empty state should make the user want to fill it.

**5. Shame-free fashion**
Zero judgment. No "you have too many items." No "you haven't worn this in 60 days — why?" All nudges are warm, curious, never accusatory.

---

## 2. Microinteraction Library

### 2.1 Garment Card — Hover State (Web)

```
Default → Hover:
  - transform: translateY(-4px) — 250ms ease-out-soft
  - box-shadow: shadow-sm → shadow-lg — 250ms
  - image scale: 1.0 → 1.02 (inner) — 300ms ease-silky

Hover → Active (pressed):
  - transform: translateY(-2px) — 100ms
  - box-shadow: shadow-lg → shadow-md — 100ms

Active → Release:
  - spring back: translateY(0) — 200ms ease-spring
```

### 2.2 Garment Card — Long Press (Mobile)

```
0ms:     Finger down
150ms:   Haptic (light impact)
300ms:   Card begins to scale: 1.0 → 1.05 with shadow-xl
300ms:   Multi-select mode enters: checkboxes fade in on all cards
400ms:   Haptic (medium impact) — multi-select confirmed

Cancel (finger up < 300ms): no effect
```

### 2.3 Favorite Toggle

```
Off → On:
  1. Heart icon: scale 1.0 → 1.4 (100ms, ease-spring)
  2. Color: Stone Gray → Dusty Mauve (150ms)
  3. Scale: 1.4 → 1.0 (150ms, ease-out-soft)
  4. Haptic: UIImpactFeedbackGenerator.medium
  5. Optional: burst of 4 small heart particles from icon (50ms appear, 400ms float+fade)

On → Off:
  1. Scale: 1.0 → 0.85 → 1.0 (200ms, ease-spring)
  2. Color: Dusty Mauve → Stone Gray (150ms)
  3. No haptic
```

### 2.4 Garment Upload — Drop Zone

```
Idle state:
  - Dashed border (1px, Stone Gray, opacity 0.3)
  - Icon: cloud upload, 32px, Stone Gray
  - Label: "Drag your garment here" / "or browse files"

File dragged over:
  - Border: dashed → solid (2px, Champagne Gold) — 150ms
  - Background: transparent → rgba(212, 175, 130, 0.04) — 150ms
  - Icon: scale 1.0 → 1.2 — 200ms ease-spring
  - Label changes: "Drop to add"

File dropped:
  - Green pulse ring (1 ring, expands out, fades — 400ms)
  - Immediately transition to upload preview state
  - Haptic: UINotificationFeedbackGenerator.success
```

### 2.5 AI Processing Animation — Garment Card (Skeleton → Ready)

```
Phase 1 — Skeleton (while AI processes):
  - Card appears immediately with shimmer placeholder
  - Shimmer: warm gradient #F0EBE4 → #FAF8F5 → #F0EBE4
  - Direction: 135° (diagonal)
  - Duration: 1.4s, infinite

Phase 2 — Processing indicator (after upload, waiting for AI):
  - Small circular progress ring at top-right corner of card
  - Color: Champagne Gold, 1.5px stroke, animated rotation
  - Tooltip on hover: "Crayoli is analyzing this piece..."

Phase 3 — Ready reveal:
  - Image cross-fades in: placeholder → processed garment image
  - Duration: 500ms, ease-silky
  - Simultaneous: category tag fades in (200ms delay + 300ms fade)
  - Color palette dots: stagger in left-to-right (50ms per dot, 200ms fade each)
  - Haptic (mobile): UINotificationFeedbackGenerator.success
  - Toast: "Your [category] is ready" — 2s auto-dismiss
```

### 2.6 Outfit Card — Save Action

```
Tap "Save":
  1. Button: scale 0.95 → 1.0 — 100ms ease-spring
  2. Button background: Ivory → Champagne Gold — 200ms
  3. Button text: "Save" → "Saved ✓" — cross-fade 200ms
  4. Haptic: UIImpactFeedbackGenerator.medium
  5. After 1.5s: text fades back to "Save" (state persists in DB)
```

### 2.7 Color Swatch Selection (Onboarding)

```
Tap swatch:
  1. Scale: 1.0 → 1.2 — 150ms ease-spring
  2. Ring appears: 2px Champagne Gold ring (3px offset) — 150ms
  3. Checkmark badge: fade in top-right (100ms)
  4. Haptic: UIImpactFeedbackGenerator.light

Tap again (deselect):
  1. Scale: 1.2 → 1.0 — 150ms
  2. Ring: fade out — 150ms
  3. Checkmark: fade out — 100ms
```

### 2.8 Recommendation Outfit — Shuffle Item

```
Tap "Shuffle" on an outfit item:
  1. Item card: flip Y axis 180° (200ms, ease-premium) — disappears
  2. New item: flip Y axis from 180° → 0° (200ms delay, 200ms duration)
  3. If items are incompatible: color harmony badge updates live
  4. "Why this?" tooltip: slides in from bottom (300ms, ease-out-soft)
```

### 2.9 Navigation — Bottom Tab Switch (Mobile)

```
Tab tap:
  1. Icon: scale 1.0 → 0.85 → 1.0 — 200ms ease-spring
  2. Label: fades in if not active / out if leaving
  3. Active dot: slides to new tab — 300ms ease-premium
  4. Content: crossfade + translateY(10px → 0) — 250ms ease-out-soft

Middle "+" button:
  1. Button scale: 1.0 → 0.9 → 1.1 → 1.0 — 350ms ease-spring
  2. Background: dark → Champagne Gold (200ms) if sheet opens
```

### 2.10 Toast / Snackbar Notifications

```
Enter:
  - translateY(100% → 0) + fade in — 300ms ease-out-soft
  - Appears above bottom navigation

Exit (auto after 3s or manual dismiss):
  - translateY(0 → 100%) + fade out — 200ms ease-in-soft

Types:
  - Success: left border 3px #7A9E7E, icon: checkmark
  - Error: left border 3px #C47A7A, icon: X
  - Info: left border 3px #9A9EC4, icon: info
  - Processing: left border 3px #D4AF82, icon: spinner

Example:
  "White Silk Blouse added to your closet." [Undo]
  Background: #FFFFFF, shadow-lg, radius-lg
```

---

## 3. Loading & Empty States

### 3.1 Skeleton Screens

**Rule:** Show skeleton immediately. Never show a spinner for content that has a defined shape.

**Closet Grid Skeleton:**
```
12 placeholder cards in 2-col grid
Each card: warm shimmer, same dimensions as real card
Corner radius: radius-lg (matches real card)
Image area: 75% of card height
2 text lines below: 60% width + 40% width
```

**Garment Detail Skeleton:**
```
Full-width image area (height: 60vw)
Below: 3 text lines (80%, 60%, 40%)
Color dot row: 5 circles × 16px
Section headers: 3 at staggered widths
```

### 3.2 Empty States

**Empty Closet:**
```
Illustration: Open wardrobe, one empty hanger centered, soft watercolor
Headline: "Your story begins here." [Serif 22px]
Subtext: "Add your first piece and let Crayoli learn your language."
CTA: "Add a Garment" [Primary button]
Secondary: "Import from photos" [Text link]
```

**Empty Search Results:**
```
Illustration: Small magnifying glass with question mark, delicate line art
Headline: "Nothing matches quite yet." [Serif 20px]
Subtext: "Try different terms, or check if the item has been archived."
CTA: "Search again" [Text link]
```

**Empty Calendar Day:**
```
No illustration — just elegant empty state
Day cell: lighter bg + thin dashed border
On tap: "Plan this day" bottom sheet with 3 AI suggestions for that date
```

**Empty Wishlist:**
```
Illustration: Small gift box with bow, minimal line art
Headline: "Nothing on your wish list yet." [Serif 20px]
Subtext: "Add pieces you're dreaming about — Crayoli will tell you if they'd work with your closet."
```

**Zero Recommendations (no wardrobe data):**
```
This shouldn't happen after onboarding, but if triggered:
Headline: "Building your first looks..."
Subtext: "Add at least 5 pieces and Crayoli will start recommending outfits."
Progress: "3 of 5 minimum pieces added." [Subtle progress bar]
```

---

## 4. Error States

### Form Validation

**Inline, immediate:**
- Error appears below field on blur (not on submit)
- Border: 1px default → 2px `#C47A7A` error
- Error message: 12px, `#C47A7A`, icon: small X circle
- Never red banner — too alarming for a fashion app

**Examples:**
```
Email: "This doesn't look like a valid email address."
Password: "Password must be at least 8 characters."
Upload: "This file is too large. Try a photo under 20MB."
Upload: "We couldn't read this file. Try a JPEG or PNG."
```

### Network / Server Errors

**API error toast:**
```
"Something went wrong. We're on it." [Retry]
```

**Upload failure:**
```
Placeholder card turns to error state:
  - Warm red tint on card background
  - Icon: small warning triangle
  - Text: "Upload failed. Tap to retry."
  - Tap → immediate retry
```

**AI classification failure:**
```
Card appears without AI data:
  - Label: "Add details manually"
  - Tag: "Unclassified" in subtle chip
  - Edit tray: prompt user to set category manually
  - Background: AI retries once automatically after 30s
```

### Offline State

**Global offline banner:**
```
Position: below header, full-width
Height: 32px
Background: Stone Gray #8A857F
Text: "You're offline. Browsing your cached closet." [Inter 12px, white]
Icon: small cloud-off icon left-aligned
Auto-dismisses on reconnect + shows "Back online. Syncing..." for 2s
```

---

## 5. Haptic Feedback Map (iOS)

| Interaction | Haptic Type | Feedback Style |
|-------------|-------------|---------------|
| Button primary tap | UIImpactFeedbackGenerator | .medium |
| Button secondary tap | UIImpactFeedbackGenerator | .light |
| Toggle / checkbox | UIImpactFeedbackGenerator | .rigid |
| Favorite | UIImpactFeedbackGenerator | .medium |
| Swipe action confirmed | UIImpactFeedbackGenerator | .heavy |
| Upload success | UINotificationFeedbackGenerator | .success |
| AI complete notification | UINotificationFeedbackGenerator | .success |
| Error | UINotificationFeedbackGenerator | .error |
| Multi-select enter | UIImpactFeedbackGenerator | .medium (then .heavy at confirm) |
| Drag start | UIImpactFeedbackGenerator | .light |
| Drag drop | UIImpactFeedbackGenerator | .rigid |
| Pull-to-refresh | UIImpactFeedbackGenerator | .light (on trigger) |

---

## 6. Navigation Architecture

### Mobile — Bottom Navigation

```
Tab 1: Home      — house icon (filled when active)
Tab 2: Closet    — hanger icon
Tab 3: [+] FAB   — always elevated, no label
Tab 4: Discover  — sparkle/star icon
Tab 5: Profile   — circle avatar (user photo if set)
```

**FAB Sheet (tap +):**
```
┌────────────────────────┐
│    ╳ Close             │ ← X top right
│                        │
│  [+Garment icon]       │
│  Add a Garment         │
│                        │
│  [Outfit icon]         │
│  Build an Outfit       │
│                        │
│  [Calendar icon]       │
│  Plan My Week          │
└────────────────────────┘
```
Appears as bottom sheet with spring animation (translateY(100% → 0), 350ms ease-premium).

### Web — Sidebar Navigation

```
┌────────────────────────────────────────────────────────┐
│ Crayoli          [collapsed: just icon at 60px width]  │
│ ─────────────────────────────────────────────────────  │
│ [Avatar 32px] Ana María                               │
│ ───────────────────────                               │
│                                                        │
│ [Home icon]    Home                    ← Active: left  │
│ [Hanger]       Closet                    accent bar    │
│ [Star]         Discover                  (4px wide,    │
│ [Calendar]     Calendar                  Champagne     │
│ [Chart]        Analytics                 Gold)         │
│ ───────────────────────                               │
│ [Heart]        Wishlist                               │
│ [Compass]      Explore                               │
│                                                        │
│ ───────────────────────                               │
│ [Settings]     Settings                               │
│ ───────────────────────                               │
│ ← Collapse                                            │
└────────────────────────────────────────────────────────┘
```

**Sidebar behavior:**
- Desktop: always visible, 260px width
- Tablet: collapsible to 60px icon-only mode (toggle button)
- Mobile: drawer (slides from left, overlaid)

---

## 7. Gesture System (Mobile)

| Gesture | Surface | Action |
|---------|---------|--------|
| Swipe left on garment card | Closet list/grid | Archive (with confirmation sheet) |
| Swipe right on garment card | Closet list/grid | Quick-add to today's outfit |
| Long press garment card | Closet grid | Enter multi-select mode |
| Pinch-zoom on image | Garment detail hero | Zoom in |
| Swipe down | Full-screen image | Dismiss |
| Pull-to-refresh | Home, Closet, Discover | Refresh data |
| Swipe left on outfit card | Recommendations feed | Dismiss this suggestion |
| Swipe right on outfit card | Recommendations feed | Save outfit |
| Two-finger swipe | Outfit builder canvas | Scroll item browser |

---

## 8. Accessibility Implementation

### Focus Management
- All interactive elements: visible focus ring (2px Champagne Gold, 2px offset)
- Modal / sheet: focus trapped within until dismissed
- After modal close: focus returns to trigger element

### Screen Reader (ARIA)
```html
<!-- Garment card -->
<article
  role="article"
  aria-label="White Silk Blouse, COS, worn 12 times"
  aria-describedby="garment-123-detail"
>
  <img alt="White silk blouse on ivory background" />
  <span id="garment-123-detail" class="sr-only">
    Category: Tops. Last worn 12 days ago. Mark as favorite.
  </span>
</article>

<!-- AI recommendation card -->
<section aria-label="AI Outfit Recommendation: Polished Tuesday">
  <h3>Polished Tuesday</h3>
  <p>For light office work. 14 degrees, partly cloudy.</p>
  <ul aria-label="Outfit items">
    <li>White Silk Blouse — top</li>
    <li>Black High-Waist Trousers — bottom</li>
  </ul>
  <button aria-label="Wear this outfit today">Wear Today</button>
  <button aria-label="Save Polished Tuesday outfit">Save</button>
</section>
```

### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }

  /* Exception: state changes still need minimal feedback */
  .state-change {
    transition-duration: 150ms !important;
  }
}
```

### Color Contrast Compliance
- All text on primary backgrounds: minimum 4.5:1 ratio
- Interactive elements: minimum 3:1 ratio
- Icon-only actions: always paired with ARIA label

---

*UX Flows & Microinteractions v1.0 — Crayoli Design*
