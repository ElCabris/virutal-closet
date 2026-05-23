# Crayoli Closet — Product Roadmap & Startup Strategy
**Version:** 1.0 | **Horizon:** 24 months | **Framework:** Lean Startup + OKR

---

## 1. Product Timeline Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CRAYOLI ROADMAP                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  MVP (0-3mo)    V1.0 (3-6mo)    V1.5 (6-9mo)    V2.0 (9-18mo)        │
│  ─────────────  ─────────────  ──────────────   ─────────────────      │
│  Core closet    Full feature    AI maturity      Platform phase         │
│  AI pipeline    polish          & engagement     Expansion              │
│  Basic recs     Calendar        Insights         Social features        │
│  Onboarding     Analytics       Style DNA        AI stylist chat        │
│                 Search          Mood engine      Virtual try-on         │
│                 Wishlist        Packing asst     Marketplace int.       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. MVP — Months 0 to 3

**Goal:** Validate core loop — upload → classify → recommend. Prove AI value.

**Success criteria:**
- Ana María has >30 garments digitized
- AI recommendations accepted or saved >40% of the time
- Daily active use ≥ 5 days/week

### MVP Feature Set

#### Must-Have (M)
- [M] User authentication (email + Google OAuth)
- [M] Style onboarding quiz (aesthetic + color + lifestyle)
- [M] Garment upload via camera + gallery
- [M] Client-side image quality validation
- [M] Direct S3 upload (presigned URL)
- [M] Background removal pipeline (SAM + U²-Net)
- [M] Fashion classification (ViT-B/16 — category + subcategory)
- [M] CLIP embedding generation + Pinecone indexing
- [M] Color palette extraction (K-means, 5 colors)
- [M] AI style label generation (Claude Haiku)
- [M] Closet grid view (2-col mobile, filters by category)
- [M] Garment detail view (full metadata, wear logging)
- [M] Daily outfit recommendations (3 per day)
- [M] Weather integration (OpenWeatherMap)
- [M] Basic mood selector (5 moods)
- [M] Save outfit
- [M] Wear logging
- [M] WebSocket real-time updates (processing complete)
- [M] Push notifications (daily recommendation + processing complete)

#### Won't Have in MVP (W)
- [W] Outfit builder canvas (manual builder)
- [W] Analytics dashboard
- [W] Calendar
- [W] Wishlist
- [W] Style DNA report
- [W] AI chat stylist
- [W] Virtual try-on

### MVP Tech Stack (simplified)
- Frontend: Next.js 14 + React Native (Expo) + Tailwind
- Backend: FastAPI (Python) — modular monolith
- AI: Python service, CLIP + SAM + ViT + Claude Haiku
- DB: PostgreSQL 16 + pgvector + Redis
- Infra: Docker Compose (dev) + single EKS cluster (prod)
- Images: S3 + Cloudinary

### MVP Engineering Timeline

```
Week 1-2:  Infrastructure setup (Docker, DB schema, CI/CD skeleton)
Week 3-4:  Auth system + onboarding flow
Week 5-6:  Upload pipeline + S3 integration
Week 7-8:  AI pipeline (background removal + classification)
Week 9-10: Closet view + garment detail
Week 11:   Recommendation engine + weather
Week 12:   Polish + bug fixes + internal testing
```

---

## 3. V1.0 — Months 3 to 6

**Goal:** Full product experience. Daily ritual. Habit formation.

**Success criteria:**
- 7-day streak usage rate > 60%
- Average garments per user: 80+
- Outfit calendar weekly planning adoption: >35%

### V1.0 Features

| Feature | Details |
|---------|---------|
| **Outfit Builder** | Canvas-based manual outfit creation + color harmony indicator |
| **Outfit Calendar** | Week + month view, outfit planning, weather overlays |
| **Event creation** | Add events with occasion/formality context |
| **Analytics Dashboard** | Wardrobe overview, most worn, forgotten gems, color DNA |
| **Advanced filters** | Color picker, brand, price range, material, pattern |
| **Global Search** | FTS + visual similarity search |
| **Wishlist** | Save items to buy, price tracking |
| **Multi-image upload** | Multiple angles per garment |
| **Outfit sharing** | Share outfit image to Instagram/Stories |
| **Dark mode** | Full dark theme implementation |
| **Offline mode** | Browse cached closet offline |
| **Batch upload** | Upload 20 items simultaneously |
| **Garment swipe actions** | Swipe to archive, favorite, add to outfit |
| **AI reasoning** | Show *why* Crayoli recommended an outfit |
| **Style DNA v1** | Basic persona card + color distribution |

### V1.0 Performance Targets

| Metric | Target |
|--------|--------|
| AI classification time | < 60 seconds |
| Recommendation generation | < 1.5 seconds |
| Image load (card) | < 400ms (CDN cached) |
| App startup (cold) | < 2.5 seconds |
| API p95 latency | < 300ms |

---

## 4. V1.5 — Months 6 to 9

**Goal:** Intelligence maturity. Style DNA fully formed. Deep personalization.

**Success criteria:**
- Style DNA cold start complete for all users with >30 interactions
- Outfit acceptance rate: >55%
- Monthly streak: >25 active days

### V1.5 Features

| Feature | Details |
|---------|---------|
| **Style DNA Report** | Full visual report: persona, color DNA, evolution over time, insights |
| **Packing Assistant** | Trip planning — generate packing list from closet for given days/activities |
| **Forgotten item surfacing** | Weekly "rediscovery" push: items not worn in 30+ days with outfit suggestion |
| **Cost-per-wear insights** | Full CPW analytics with "your best investment" and "consider retiring" |
| **Seasonal wardrobe** | Seasonal mode: surface/hide items by season, season transition alerts |
| **Outfit collection** | Group saved outfits into named collections (Work Week / Summer Vacation) |
| **Repeat detection** | Alert when planning to wear outfit repeated within 14 days |
| **AI confidence improvement** | Model v2 — fine-tuned on user feedback data |
| **Widget** | iOS/Android homescreen widget: "Today's Crayoli pick" |
| **Apple Watch** | Basic complication: today's outfit summary |
| **Mood journaling** | Optional: log mood when logging outfit — correlate mood to style patterns |
| **Style insights** | Monthly style report: "Your May in numbers" — editorial design |

---

## 5. V2.0 — Months 9 to 18

**Goal:** Platform expansion. AI frontier features. Community seeds.

**Success criteria:**
- AI stylist chat active for >30% of DAU
- Revenue generating (if monetization introduced)
- NPS > 75

### V2.0 Feature Set

#### AI Stylist Chat
A conversational AI assistant powered by Claude, with full access to Ana María's wardrobe data:

```
User: "I have a rooftop dinner next Friday, it might be 18°C. What should I wear?"

Crayoli AI: "For a rooftop dinner at 18°C — perfect for that champagne gold moment.
I'd go with your ivory midi dress (you haven't worn it in 3 weeks, perfect timing),
layered with the camel blazer for warmth. Your strappy sandals and the small black
clutch complete it. Want me to show you alternatives?"
```

**Implementation:**
- Claude claude-sonnet-4-6 (context: style profile + closet summary + recent history)
- Structured tool calls for garment queries
- Rendered outfit cards inline in chat
- Context window: last 10 messages + style profile + top 20 garments by relevance

#### Virtual Mirror / Try-On
- Integration with TryOn-Diffusion or commercial API (Fashn.ai, Revery.ai)
- Upload photo of self → digitally dress in garments
- Works as "preview before you commit" for outfit builder

#### Pinterest Integration
- Import saved pins as wishlist items
- AI extracts garment attributes from Pinterest images
- "Find this in your closet" — similarity search against closet

#### Moodboard Studio
- Create editorial moodboards mixing closet items + inspiration images
- Export as shareable image (Instagram-ready)
- Aesthetic coherence scoring per moodboard

#### Similar Item Detection
- "You already have something like this" alert when adding new items
- Reduce wardrobe duplication
- "Would you like to compare?" side-by-side view

#### Sustainability Score
- Per-garment sustainability estimate (material, brand reputation, CPW)
- Wardrobe sustainability score
- "Your most sustainable choice today" as optional context in recommendations

#### Social / Community (Opt-in)
- Follow friends who also use Crayoli
- See their style personas (no garments shared — privacy first)
- "Inspiration" tab: curated looks from community (opt-in to share)

#### Shopping Intelligence
- Price drop alerts for wishlist items
- "This would pair perfectly with 3 items you own" on product pages
- Browser extension for desktop

---

## 6. Future Features (V3+ / Exploratory)

### AI Fashion Advisor (Premium)
- Personalized shopping recommendations based on wardrobe gaps + style
- "You're missing a structured coat for your wardrobe. These 5 options fit your palette."
- Partner with premium retailers for curated shopping

### Smart Wardrobe Integration
- IoT hooks (smart wardrobe with RFID tags) — automatic wear tracking
- NFC tags on garments → tap phone to log wear

### Style Rental Integration
- Integrate with Rent the Runway / local rental services
- "Rent this for tonight" for occasions where ownership isn't worth it

### Fashion AI Report (Annual)
- End-of-year editorial report: "Your Year in Style"
- Data story: most memorable outfits, color evolution, style milestones
- Beautiful exportable PDF, shareable summary card

### Professional Stylist Marketplace
- Connect with human stylists for premium advice sessions
- Stylist sees your closet (with permission) and makes recommendations
- Video consultation booking

---

## 7. Technical Roadmap

### AI Model Improvements Timeline

| Phase | Model | Status |
|-------|-------|--------|
| MVP | CLIP ViT-L/14 (frozen) + ViT-B/16 (finetuned) | Production |
| V1 | Pattern detector v1 + material estimator v1 | Development |
| V1.5 | Style DNA embedding model (custom trained on interaction data) | Research |
| V2 | Diffusion-based outfit generation | Exploratory |
| V2 | Claude integration for chat stylist | Development |
| V3 | On-device inference for key features (CoreML / TFLite) | Exploratory |

### Infrastructure Evolution

```
MVP → V1:
  - Add read replica for analytics
  - Redis Cluster mode (was single node)
  - CDN optimization + WebP conversion pipeline
  - Celery workers horizontal scaling

V1 → V2:
  - Microservice extraction: AI service → standalone with dedicated GPU nodes
  - Multi-region consideration (LatAm expansion)
  - Event bus (AWS EventBridge) for async workflows
  - Enhanced observability (Datadog or Grafana stack)

V2 → V3:
  - Edge inference evaluation (on-device AI)
  - Multi-tenant architecture for B2B (if stylists get their own portals)
  - Data lake for analytics (AWS Redshift)
```

---

## 8. Modelo de Acceso y Monetización

### Principio fundamental

**Crayoli Closet está construido para Ana María. Ella tiene acceso completo e irrestricto a todas las funcionalidades, siempre — en todo tier, en todo momento, para siempre.**

No existe una versión "gratuita" con restricciones para Ana María. No hay límites de prendas, no hay límite de recomendaciones, no hay features bloqueadas. El sistema entero — incluyendo AI stylist chat, Style DNA completo, packing assistant, analíticas históricas, procesamiento prioritario — está disponible de forma nativa.

### Capa Fundadora — Ana María

```
┌─────────────────────────────────────────────────────┐
│              CRAYOLI FOUNDER ACCESS                 │
│                                                     │
│  Todas las funcionalidades. Sin límites.            │
│  Sin restricciones. Sin tiers. Sin fricción.        │
│                                                     │
│  ✓ Prendas ilimitadas                               │
│  ✓ Recomendaciones ilimitadas                       │
│  ✓ AI Stylist Chat completo (Claude)                │
│  ✓ Style DNA Report completo + evolución            │
│  ✓ Packing Assistant                                │
│  ✓ Analíticas históricas completas (all-time)       │
│  ✓ Outfit Builder canvas completo                   │
│  ✓ Calendario inteligente + eventos                 │
│  ✓ Procesamiento AI prioritario (< 30s)             │
│  ✓ Virtual try-on (V2)                              │
│  ✓ Moodboards Studio (V2)                           │
│  ✓ Pinterest integration (V2)                       │
│  ✓ Fashion AI Report anual                          │
│  ✓ Todas las funcionalidades futuras                │
└─────────────────────────────────────────────────────┘
```

Esta es la experiencia de referencia. Todo el diseño, el benchmark de calidad y las decisiones de producto se toman desde esta perspectiva: ¿cómo se siente para Ana María, con acceso total?

### Estrategia de Expansión (si la plataforma escala a otros usuarios)

Si Crayoli Closet evoluciona hacia un producto multi-usuario en el futuro, la estructura de tiers sería:

**Crayoli Essentials — Gratis**
- Hasta 75 prendas
- 3 recomendaciones diarias
- Analíticas básicas (30 días)
- Sin AI chat, sin packing assistant

**Crayoli Premium — $9.99/mes o $79/año**
- Prendas ilimitadas
- Recomendaciones ilimitadas
- AI Stylist Chat (Claude)
- Style DNA Report completo
- Packing Assistant
- Analíticas históricas completas
- Seasonal mode
- Procesamiento prioritario (< 30s)
- Virtual try-on

**Crayoli Atelier — $24.99/mes** *(V3+)*
- Todo Premium incluido
- Acceso a estilistas humanos profesionales
- Shopping intelligence personalizado
- Fashion AI Report anual (edición especial)
- Acceso anticipado a todas las funcionalidades futuras

> **Nota crítica:** Este modelo de tiers aplica únicamente a futuros usuarios. Ana María tiene acceso Atelier completo de forma permanente e irrestricta como usuaria fundadora de la plataforma.

### Revenue Projections (si expansión multi-usuario)

| Mes | Usuarios | Tasa Premium | MRR |
|-----|----------|-------------|-----|
| 6   | 500      | 0% (lanzamiento) | $0 |
| 12  | 2,000    | 10% | $2,000 |
| 18  | 8,000    | 13% | $10,400 |
| 24  | 25,000   | 16% | $40,000 |

---

## 9. Go-to-Market Strategy

### Phase 1 — Seeding (Months 0-3)
- **Audience:** Ana María's network — fashion-forward, curated taste, digital-native
- **Channel:** Instagram / TikTok short-form — "I organized my whole closet with AI" content
- **Format:** Before/after closet transformations, outfit-of-the-day with Crayoli context
- **Goal:** 100 waitlist signups → 50 beta users

### Phase 2 — Community (Months 3-9)
- **Fashion creator partnerships:** micro-influencers in fashion/lifestyle space (10K-100K followers)
- **Content pillar:** "Wardrobe psychology" — how clothes affect mood, productivity, identity
- **PR:** fashion-tech publications (Vogue Business, Business of Fashion)
- **Referral program:** "Invite a friend, both get 1 month Premium"
- **Goal:** 2,000 users

### Phase 3 — Scale (Months 9-18)
- **Paid acquisition:** Instagram/TikTok with conversion-optimized creatives (UGC style)
- **SEO:** Content marketing around wardrobe organization, sustainable fashion, capsule wardrobes
- **Brand partnerships:** Premium fashion brands for co-marketing
- **B2C expansion:** LatAm market (Colombia, Mexico, Argentina — fashion-conscious, underserved)
- **Goal:** 10,000 users

### Brand Positioning

**Against competitors:**
- Stylebook: too utilitarian, no AI, outdated UX → Crayoli is premium, intelligent, emotional
- Smart Closet: basic inventory → Crayoli is a stylist, not a spreadsheet
- Whering: European, limited AI → Crayoli is AI-first, more personal

**Crayoli's unfair advantages:**
1. AI pipeline trained for fashion specifically — not generic classification
2. Style DNA — gets smarter over time, competitors are stateless
3. Emotional design — feels like a luxury product, not an app
4. Vertical focus — built for one person first, expansible

---

## 10. Team Structure

### Founding Team (MVP)
- **1× Full-Stack Engineer** — Next.js + FastAPI + infrastructure
- **1× AI/ML Engineer** — computer vision pipeline + recommendation engine
- **1× Product Designer** — UX/UI + brand

### V1 Team (additions)
- **1× Mobile Engineer** — React Native optimization
- **1× Backend Engineer** — API expansion + performance

### V2 Team (additions)
- **1× AI Researcher** — Style DNA model + LLM integration
- **1× Growth/Marketing** — content + community
- **1× Data Analyst** — analytics + model performance

---

*Roadmap v1.0 — Crayoli Product Strategy — Confidential*
