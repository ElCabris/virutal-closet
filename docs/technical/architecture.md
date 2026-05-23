# Crayoli Closet — Technical Architecture
**Version:** 1.0 | **Classification:** Engineering — Internal
**Architecture Type:** Modular Monolith → Microservices migration path

---

## 1. Architecture Overview

### Design Philosophy

Crayoli Closet's architecture follows **product-first pragmatism**: start with a well-structured modular monolith that can evolve into microservices when scale demands it. Premature microservices introduce operational complexity without benefit at MVP/V1 stage.

**Core principles:**
- **Domain isolation** — bounded contexts, clear module boundaries from day 1
- **AI-first** — AI pipeline is a first-class infrastructure concern, not a bolted-on feature
- **Image-optimized** — garment images are the core data; infrastructure is optimized for image processing, storage, and delivery
- **Offline resilience** — client-side cache + optimistic UI + background sync
- **Observability** — every AI decision is traceable; every recommendation has an explainable reason

### High-Level System Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                           CLIENTS                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │  iOS App    │  │ Android App │  │  Web App    │                  │
│  │  (React     │  │  (React     │  │  (Next.js)  │                  │
│  │   Native)   │  │   Native)   │  │             │                  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │
└─────────┼────────────────┼────────────────┼────────────────────────────┘
          │                │                │
          └────────────────┴────────────────┘
                           │ HTTPS / WSS
                           │
┌──────────────────────────▼──────────────────────────────────────────────┐
│                        API GATEWAY / EDGE                               │
│   CloudFront + WAF + Rate Limiter + Auth Middleware                     │
│   Nginx Ingress → Load Balancer                                         │
└──────────────────────────┬──────────────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
┌─────────────┐  ┌─────────────────┐  ┌──────────────────┐
│  API Server │  │  AI Processing  │  │  WebSocket Server│
│  (FastAPI)  │  │  Service (Python│  │  (FastAPI/WS)    │
│             │  │  + PyTorch)     │  │                  │
│  REST APIs  │  │  Async workers  │  │  Real-time push  │
│  Auth       │  │  CV pipeline    │  │  Job updates     │
│  Business   │  │  Recommendations│  │  Notifications   │
│  logic      │  │  Embeddings     │  │                  │
└──────┬──────┘  └────────┬────────┘  └──────────────────┘
       │                  │
       ▼                  ▼
┌──────────────────────────────────────────────────────────┐
│                     DATA LAYER                           │
│                                                          │
│  ┌──────────────┐  ┌──────────┐  ┌─────────────────┐   │
│  │  PostgreSQL  │  │  Redis   │  │    Pinecone      │   │
│  │  (Primary DB)│  │  (Cache) │  │  (Vector Store)  │   │
│  │              │  │  (Queue) │  │                  │   │
│  │  pgvector    │  │  Session │  │  CLIP embeddings │   │
│  │  extension   │  │  Rate    │  │  Similarity      │   │
│  └──────────────┘  └──────────┘  └─────────────────┘   │
└──────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────────────┐
│                    STORAGE LAYER                                        │
│  ┌──────────────────────────┐   ┌──────────────────────────────────┐   │
│  │   AWS S3                 │   │   Cloudinary CDN                 │   │
│  │   - Raw uploads          │   │   - Processed images             │   │
│  │   - AI-processed images  │   │   - Transformations on demand    │   │
│  │   - Backup/archive       │   │   - WebP conversion              │   │
│  └──────────────────────────┘   └──────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Frontend Architecture

### Technology Stack

| Layer | Technology | Justification |
|-------|-----------|---------------|
| Framework | Next.js 14 (App Router) | SSR + SSG + RSC for performance; excellent DX |
| Language | TypeScript 5.x | Type safety across the board |
| Styling | Tailwind CSS + CSS Modules | Utility-first + component-scoped overrides |
| Animation | Framer Motion | Best-in-class React animation library |
| State — Server | TanStack Query v5 | Server state, caching, background refresh |
| State — Client | Zustand | Lightweight, ergonomic, no boilerplate |
| Forms | React Hook Form + Zod | Performance + validation colocated |
| Images | Next.js Image + Cloudinary | Optimization, WebP, responsive srcsets |
| Icons | Phosphor Icons (thin) | Consistent, scalable icon system |
| Native | React Native + Expo | Shared logic, native performance |

### Project Structure — Frontend

```
apps/
  web/                              ← Next.js web application
    app/
      (auth)/                       ← Auth route group (no shell layout)
        login/page.tsx
        signup/page.tsx
        onboarding/page.tsx
      (app)/                        ← Authenticated app shell
        layout.tsx                  ← Shell: nav + providers
        home/page.tsx
        closet/
          page.tsx                  ← Closet grid
          [id]/page.tsx             ← Garment detail
        builder/page.tsx
        discover/page.tsx
        calendar/page.tsx
        analytics/page.tsx
        profile/page.tsx
        settings/page.tsx
      api/                          ← Next.js API routes (BFF layer only)
        auth/[...nextauth]/route.ts
    components/
      ui/                           ← Primitive components (design system)
        Button/
          Button.tsx
          Button.stories.tsx
          Button.test.tsx
          index.ts
        Input/
        Card/
        Modal/
        Sheet/                      ← Bottom sheet (mobile)
        Skeleton/
        Badge/
        Avatar/
        ColorSwatch/
        GarmentCard/
        OutfitCard/
        MoodBadge/
      layout/
        AppShell/
        Sidebar/
        BottomNav/
        TopBar/
      features/                     ← Feature-level composed components
        closet/
          ClosetGrid/
          GarmentUploadFlow/
          GarmentDetail/
          FilterBar/
          SortDropdown/
        outfits/
          OutfitBuilder/
          OutfitCard/
          MoodSelector/
        recommendations/
          DailyCard/
          RecommendationFeed/
          WeatherBanner/
        analytics/
          WardrobeDonut/
          WearHeatmap/
          ColorDNA/
          MostWornList/
        calendar/
          WeekView/
          MonthView/
          DayPlanner/
        onboarding/
          AestheticQuiz/
          ColorPicker/
          LifestyleSliders/
    lib/
      api/                          ← API client (typed fetch wrappers)
        client.ts                   ← Base fetch with auth injection
        garments.ts
        outfits.ts
        recommendations.ts
        analytics.ts
        uploads.ts
      hooks/                        ← Custom React hooks
        useGarments.ts
        useOutfits.ts
        useRecommendations.ts
        useWeather.ts
        useOutfitBuilder.ts
      stores/                       ← Zustand stores
        uiStore.ts                  ← Global UI state (modals, sheets)
        closetStore.ts              ← Optimistic closet updates
        builderStore.ts             ← Outfit builder canvas state
        onboardingStore.ts
      utils/
        colorUtils.ts               ← Color harmony, palette analysis
        imageUtils.ts               ← Client-side image processing
        dateUtils.ts
        formatters.ts
      types/
        api.ts                      ← API response types
        domain.ts                   ← Domain entity types
        ui.ts                       ← UI-specific types
    config/
      site.ts
      navigation.ts
    styles/
      globals.css                   ← CSS custom properties, resets
      tokens.css                    ← Design tokens
  mobile/                           ← React Native / Expo
    app/                            ← Expo Router
    components/
    screens/
    hooks/
packages/
  shared/                           ← Shared between web + mobile
    types/
    utils/
    constants/
    validators/                     ← Zod schemas shared
```

### State Management Strategy

**Server State (TanStack Query):**
```typescript
// Example: garments query with smart invalidation
const useGarments = (filters?: GarmentFilters) => {
  return useQuery({
    queryKey: ['garments', filters],
    queryFn: () => api.garments.list(filters),
    staleTime: 5 * 60 * 1000,       // 5min — closet doesn't change often
    gcTime: 30 * 60 * 1000,         // 30min cache
    placeholderData: keepPreviousData,
  });
};

// Optimistic upload mutation
const useUploadGarment = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: api.garments.upload,
    onMutate: async (newGarment) => {
      await queryClient.cancelQueries({ queryKey: ['garments'] });
      const previous = queryClient.getQueryData(['garments']);
      // Insert optimistic placeholder
      queryClient.setQueryData(['garments'], (old) => [
        { id: 'temp-' + Date.now(), status: 'processing', ...newGarment },
        ...old,
      ]);
      return { previous };
    },
    onError: (err, _, context) => {
      queryClient.setQueryData(['garments'], context?.previous);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['garments'] });
    },
  });
};
```

**Client State (Zustand):**
```typescript
// Outfit builder store — complex canvas state
interface BuilderStore {
  canvas: CanvasItem[];
  selectedItemId: string | null;
  activeCategory: Category;
  colorHarmony: 'harmonious' | 'complementary' | 'bold' | 'clash';

  addItem: (item: GarmentItem) => void;
  removeItem: (id: string) => void;
  selectItem: (id: string | null) => void;
  swapItem: (id: string, replacement: GarmentItem) => void;
  computeHarmony: () => void;
  saveOutfit: (name: string) => Promise<void>;
  clear: () => void;
}
```

### Performance Architecture

**1. Image Optimization**
```typescript
// All garment images use Next/Image with Cloudinary
<Image
  src={garment.imageUrl}
  alt={garment.name}
  fill
  sizes="(max-width: 768px) 50vw, (max-width: 1200px) 33vw, 25vw"
  quality={85}
  placeholder="blur"
  blurDataURL={garment.blurHash}
  className="object-cover object-top"
/>
```

**2. React Server Components**
- Static shells (layout, navigation) → RSC (no client bundle)
- Data-fetching components → RSC with streaming
- Interactive components (drag-drop, canvas, forms) → Client Components
- Closet grid: RSC shell + client pagination + Intersection Observer infinite scroll

**3. Code Splitting**
```typescript
// Heavy features loaded on demand
const OutfitBuilder = dynamic(() => import('@/features/outfits/OutfitBuilder'), {
  loading: () => <BuilderSkeleton />,
});

const AnalyticsDashboard = dynamic(
  () => import('@/features/analytics/AnalyticsDashboard'),
  { ssr: false } // Charts require browser environment
);
```

**4. Prefetching**
- Hover on nav item → prefetch route
- Scroll near bottom of closet → prefetch next page
- Open garment card → prefetch garment detail

---

## 3. Backend Architecture

### Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| API Framework | FastAPI | 0.111+ |
| Language | Python | 3.12 |
| ASGI Server | Uvicorn + Gunicorn | — |
| Task Queue | Celery + Redis | — |
| Database ORM | SQLAlchemy 2.0 + Alembic | — |
| Validation | Pydantic v2 | — |
| Auth | python-jose (JWT) + Authlib (OAuth) | — |
| Testing | pytest + httpx | — |

### Project Structure — Backend

```
apps/api/
  src/
    main.py                         ← FastAPI app factory
    config.py                       ← Settings (pydantic-settings)
    dependencies.py                 ← Shared FastAPI dependencies
    middleware/
      auth.py                       ← JWT middleware
      cors.py
      rate_limit.py                 ← Redis-backed rate limiter
      logging.py                    ← Structured logging
    routers/
      auth.py                       ← /auth/login, /signup, /refresh
      garments.py                   ← /garments CRUD + upload
      outfits.py                    ← /outfits CRUD
      recommendations.py            ← /recommendations
      analytics.py                  ← /analytics
      calendar.py                   ← /calendar + /events
      profile.py                    ← /profile + /style-profile
      search.py                     ← /search
      uploads.py                    ← /uploads (presigned URLs)
      webhooks.py                   ← AI worker callbacks
    services/
      auth_service.py
      garment_service.py
      outfit_service.py
      recommendation_service.py
      analytics_service.py
      upload_service.py
      notification_service.py
      weather_service.py
    repositories/
      base_repository.py            ← Generic CRUD
      garment_repository.py
      outfit_repository.py
      user_repository.py
      style_profile_repository.py
    models/
      user.py
      garment.py
      outfit.py
      style_profile.py
      event.py
      wear_log.py
    schemas/                        ← Pydantic request/response schemas
      garment.py
      outfit.py
      recommendation.py
      analytics.py
      auth.py
    core/
      security.py                   ← JWT creation/validation
      exceptions.py                 ← Custom exception classes
      responses.py                  ← Standard response wrappers
    workers/                        ← Celery tasks
      image_processor.py            ← Background removal, resizing
      ai_classifier.py              ← Fashion classification
      recommendation_worker.py      ← Batch recommendation pre-computation
      notification_worker.py
    integrations/
      s3_client.py
      cloudinary_client.py
      openweather_client.py
      pinecone_client.py
  tests/
    conftest.py
    unit/
    integration/
    e2e/
  alembic/                          ← Database migrations
    versions/
    env.py

apps/ai/                            ← AI service (separate process)
  src/
    main.py                         ← FastAPI internal API
    pipeline/
      background_removal.py
      classification.py
      embedding.py
      color_extraction.py
      pattern_detection.py
    models/
      clip_model.py
      sam_model.py
      yolo_model.py
    recommender/
      engine.py
      scoring.py
      context.py
      color_harmony.py
    config.py
```

### API Service Design

**Module boundaries are strict:**
- `router` → receives HTTP request, calls `service`, returns response
- `service` → business logic only, calls `repository` and other `services`
- `repository` → database access only, returns domain models
- `service` never calls another `router`

```python
# Example: garment upload flow
# router/garments.py
@router.post("/garments/upload", response_model=GarmentResponse, status_code=201)
async def upload_garment(
    file: UploadFile,
    metadata: GarmentCreateSchema = Depends(),
    current_user: User = Depends(get_current_user),
    garment_service: GarmentService = Depends(),
):
    garment = await garment_service.create_from_upload(
        user_id=current_user.id,
        file=file,
        metadata=metadata,
    )
    return garment

# service/garment_service.py
class GarmentService:
    async def create_from_upload(
        self, user_id: UUID, file: UploadFile, metadata: GarmentCreateSchema
    ) -> Garment:
        # 1. Validate file
        validated = await self.upload_service.validate_image(file)
        # 2. Upload raw to S3
        raw_url = await self.upload_service.upload_raw(validated, user_id)
        # 3. Create garment record (status=processing)
        garment = await self.garment_repo.create(
            user_id=user_id,
            image_url_raw=raw_url,
            status="processing",
            **metadata.model_dump(),
        )
        # 4. Queue AI pipeline (async)
        await self.task_queue.enqueue(
            "process_garment",
            garment_id=str(garment.id),
            raw_url=raw_url,
        )
        return garment
```

### WebSocket Architecture

Real-time push for AI job completion:

```python
# WebSocket manager — Redis pub/sub backed
class ConnectionManager:
    def __init__(self):
        self._connections: dict[str, WebSocket] = {}
        self._redis = get_redis_client()

    async def connect(self, user_id: str, ws: WebSocket):
        await ws.accept()
        self._connections[user_id] = ws
        await self._redis.subscribe(f"user:{user_id}:events")

    async def send_to_user(self, user_id: str, event: dict):
        if ws := self._connections.get(user_id):
            await ws.send_json(event)

    # AI worker publishes to Redis channel on completion
    # WebSocket manager listens and forwards to connected client
```

### Caching Strategy

```
Redis Key Patterns:
  user:{id}:profile              TTL: 1h   — Style profile (changes rarely)
  user:{id}:recommendations:today TTL: 2h  — Daily recs (weather-dependent)
  weather:{city}:{date}          TTL: 30m  — Weather API responses
  garment:{id}:similar           TTL: 24h  — Similarity results (stable)
  outfit:{id}:detail             TTL: 12h  — Outfit data
  analytics:{id}:{period}        TTL: 1h   — Analytics computations
  session:{token}                TTL: 7d   — User sessions

Invalidation Strategy:
  - Garment added/updated → invalidate user:{id}:recommendations:today
  - Outfit worn → invalidate analytics:{id}:* 
  - Profile updated → invalidate user:{id}:profile + user:{id}:recommendations:today
```

---

## 4. AI Architecture

### Overview

The AI pipeline is the core differentiator of Crayoli Closet. It runs as a separate Python service, consuming jobs from Celery queues and publishing results via Redis pub/sub.

### Computer Vision Pipeline

```
Input: Raw garment image (JPEG/PNG/HEIC)
       ↓
[Stage 1] Image Validation & Preprocessing
  - Format conversion → JPEG
  - EXIF orientation normalization
  - Resolution check (min 400x400)
  - Blur score (Laplacian variance < threshold → reject)
  ↓
[Stage 2] Garment Segmentation & Background Removal
  - Model: SAM (Segment Anything Model) — Meta
  - Prompt: automatic mask generation on full image
  - Select largest confident segment as garment
  - Fallback: U²-Net (BiRefNet) for lighter processing
  - Output: binary mask + RGBA image (transparent background)
  ↓
[Stage 3] Garment Detection & Bounding Box
  - Model: YOLO-Fashion (fine-tuned YOLOv8 on DeepFashion2)
  - Detects: garment presence, bounding box, rough category
  - Confidence threshold: 0.70
  ↓
[Stage 4] Fashion Classification
  - Model: Fine-tuned ViT-B/16 (Vision Transformer) on DeepFashion2 + iMaterialist
  - Categories: 15 main + 120 subcategories
  - Attributes: color, pattern, neckline, sleeve, length, fit, etc.
  - Output: top-3 category predictions with confidence scores
  ↓
[Stage 5] CLIP Embedding Extraction
  - Model: OpenAI CLIP ViT-L/14 (frozen encoder)
  - Input: processed image (336x336)
  - Output: 768-dim normalized embedding
  - Stored in: Pinecone index (cosine similarity)
  ↓
[Stage 6] Color Palette Extraction
  - Algorithm: K-means clustering (k=5) on HSV color space
  - Exclude: near-white/black background remnants
  - Map to: named color vocabulary (using delta-E distance to color corpus)
  - Output: [{hex, name, percentage}] sorted by dominance
  ↓
[Stage 7] Pattern Detection
  - Model: Custom CNN trained on pattern dataset
  - Classes: solid / striped / plaid / floral / geometric / animal / abstract / graphic
  - Input: texture region crops (center + 4 quadrants)
  ↓
[Stage 8] Material Estimation
  - Model: ResNet50 fine-tuned on Fabric26 dataset
  - Classes: cotton / silk / denim / leather / linen / knit / velvet / synthetic / blend
  - Note: estimation only — label detection added in V2 (OCR on care tag)
  ↓
[Stage 9] Style Tag Generation
  - Combines: classification + color + pattern + material
  - Rule-based + LLM (Claude claude-haiku-4-5 for editorial label generation)
  - Output: 5-10 tags + 1 editorial label ("structured ivory blazer")
  ↓
[Stage 10] Thumbnail Generation
  - Sizes: 200x280 (thumb) / 400x560 (card) / 800x1120 (detail)
  - Format: WebP (85 quality) + JPEG fallback
  - Upload to Cloudinary with signed URLs
  ↓
Output: Enriched garment data → PostgreSQL + Pinecone index
```

### Model Infrastructure

```python
# AI Service startup — model loading (singleton pattern)
class ModelRegistry:
    _instance: Optional['ModelRegistry'] = None
    _models: dict = {}

    @classmethod
    def get_instance(cls) -> 'ModelRegistry':
        if cls._instance is None:
            cls._instance = cls()
            cls._instance._load_models()
        return cls._instance

    def _load_models(self):
        device = 'cuda' if torch.cuda.is_available() else 'cpu'

        # CLIP — loaded once, heavy (1.7GB VRAM for ViT-L/14)
        self._models['clip'] = CLIPModel.from_pretrained(
            "openai/clip-vit-large-patch14"
        ).to(device).eval()

        # SAM — Segment Anything
        self._models['sam'] = sam_model_registry["vit_h"](
            checkpoint="sam_vit_h_4b8939.pth"
        ).to(device)

        # Fashion classifier — fine-tuned ViT
        self._models['fashion_clf'] = load_fashion_classifier(
            "models/fashion_vit_b16.pt"
        ).to(device).eval()

        # Pattern detector
        self._models['pattern'] = load_pattern_model(
            "models/pattern_resnet50.pt"
        ).to(device).eval()
```

### Recommendation Engine

```
Input: {
  user_id,
  context: {
    datetime,
    weather: { temp_c, condition, precipitation },
    occasion: string | null,
    mood: string | null,
  }
}

Step 1: Fetch user context
  - Style profile (aesthetic, color prefs, lifestyle weights)
  - Wear history (last 90 days)
  - Calendar events (next 48h)
  - Wardrobe embeddings

Step 2: Context vector construction
  ContextVector = weighted_concat([
    embed_weather(weather),          # weather2vec (custom)
    embed_occasion(occasion),        # fine-tuned sentence transformer
    embed_mood(mood),                # mood embedding space
    embed_time(datetime),            # cyclical time encoding
  ])

Step 3: Candidate generation
  For each garment category (top, bottom, shoes, bag, outerwear):
    - Query Pinecone: nearest neighbors to ContextVector (top-50 per category)
    - Filter: season appropriate + condition != 'worn out' + not archived

Step 4: Compatibility scoring
  For each candidate garment pair (top, bottom):
    score = Σ(weight_i × factor_i) where factors:

    weather_fit:       1.0 if appropriate, else 0.0 (hard constraint)
    color_harmony:     color_harmony_score(g1.palette, g2.palette)  [0,1]
    style_coherence:   cosine_sim(g1.embedding, g2.embedding)       [0,1]
    formality_match:   1 - abs(g1.formality - occasion_formality)/4  [0,1]
    recency_bonus:     1 - (days_since_worn / 90)                    [0,1]
    freshness_bonus:   days_since_worn > 30 ? 0.2 : 0              bonus
    preference_score:  dot(g.style_tags, user.preferred_tags)        [0,1]

Step 5: Outfit assembly
  - Greedy assembly: select highest-scoring top → find best-matching bottom
    → add shoes → optionally bag/outerwear
  - Constraint: avoid exact outfit worn in last 14 days
  - Diversity: ensure 3 returned outfits differ in at least 2 items

Step 6: Editorial labeling
  - LLM prompt (Claude claude-haiku-4-5): generate 3-word outfit name from
    garment tags + occasion + mood
  - Cache result 24h per (outfit_hash, occasion, mood)

Step 7: Rank + return top 3 outfits
```

#### Color Harmony Engine

```python
def color_harmony_score(palette_a: list[HexColor], palette_b: list[HexColor]) -> float:
    """
    Scores color compatibility between two garment palettes.
    Uses HSL-based harmony rules.
    """
    dom_a = palette_a[0]  # Dominant color of garment A
    dom_b = palette_b[0]  # Dominant color of garment B

    h_a, s_a, l_a = hex_to_hsl(dom_a)
    h_b, s_b, l_b = hex_to_hsl(dom_b)

    hue_diff = abs(h_a - h_b) % 360
    # Normalize to [0, 180]
    hue_diff = min(hue_diff, 360 - hue_diff)

    # Harmony rules
    if hue_diff < 15:           return 0.95  # Monochromatic — safe
    if 15 <= hue_diff < 30:     return 0.90  # Analogous — elegant
    if 170 <= hue_diff <= 180:  return 0.85  # Complementary — bold
    if 115 <= hue_diff <= 135:  return 0.80  # Triadic (approx) — playful
    if hue_diff < 5 and s_a < 0.15 and s_b < 0.15:
                                return 0.98  # Neutral-neutral — always works

    # Neutral bonus: one neutral + one colored always safe
    is_neutral = lambda s, l: s < 0.15 or l > 0.85 or l < 0.15
    if is_neutral(s_a, l_a) or is_neutral(s_b, l_b):
        return 0.88

    # Default: acceptable but not ideal
    return max(0.3, 1.0 - (hue_diff / 180) * 0.7)
```

### Style DNA Model

The Style DNA is a continuously updated profile that encodes Ana María's aesthetic identity:

```python
class StyleDNA(BaseModel):
    user_id: UUID

    # Aesthetic vector: 128-dim learned embedding
    # Updated via online learning after each outfit interaction
    aesthetic_embedding: list[float]

    # Explicit preferences (weighted by recency + frequency)
    color_preferences: dict[str, float]     # hex → affinity score
    pattern_preferences: dict[str, float]   # pattern → affinity score
    formality_distribution: dict[int, float] # formality → frequency

    # Computed statistics
    dominant_palette: list[str]              # top 5 colors
    dominant_styles: list[str]               # top 5 style tags
    avg_formality: float
    style_persona: str                       # editorial label

    # Temporal patterns
    weekday_formality: dict[int, float]      # day_of_week → avg formality
    seasonal_preferences: dict[str, list]    # season → preferred colors

    # Cold start (first 30 interactions)
    cold_start_complete: bool
    onboarding_priors_weight: float          # 1.0 → 0.1 as data accumulates
```

**Style DNA Update Algorithm:**
```
On each outfit interaction (wear/save/dismiss):
  1. Extract signals from interacted outfits
  2. Update color_preferences with exponential moving average (α=0.1)
  3. Update aesthetic_embedding via gradient step (mini-SGD)
  4. Recompute dominant_palette, dominant_styles
  5. If wear_count > 5: reduce onboarding_priors_weight by 0.1
  6. Persist to PostgreSQL + Redis cache
```

---

## 5. Infrastructure & Cloud Architecture

### Environment Strategy

| Environment | Purpose | Infrastructure |
|-------------|---------|---------------|
| Development | Local dev | Docker Compose |
| Staging | Pre-production testing | AWS EKS (1 node) |
| Production | Live users | AWS EKS (auto-scaled) |

### AWS Services Used

```
Core Compute:
  EKS (Kubernetes) — container orchestration
  ECS (Fargate) — AI worker jobs (GPU when needed)
  EC2 (g4dn.xlarge) — GPU instances for AI inference

Storage:
  S3 — garment images (raw + processed)
  S3 Glacier — archival / long-term backup
  EFS — shared model weights across AI pods

Database:
  RDS PostgreSQL 16 (Multi-AZ) — primary database
  ElastiCache Redis 7 (Cluster mode) — cache + queues

CDN & Edge:
  CloudFront — CDN for processed images
  WAF — web application firewall
  Route 53 — DNS

Security:
  ACM — SSL certificates
  Secrets Manager — API keys, DB credentials
  IAM — fine-grained access control
  VPC — network isolation

Observability:
  CloudWatch — logs + metrics
  X-Ray — distributed tracing
  SNS/SQS — async event bus
```

### Kubernetes Architecture

```yaml
# Namespace strategy
namespaces:
  - crayoli-api        # FastAPI services
  - crayoli-ai         # AI processing workers
  - crayoli-data       # Redis, monitoring

# API Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crayoli-api
  namespace: crayoli-api
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: crayoli-api
  template:
    spec:
      containers:
        - name: api
          image: crayoli/api:latest
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 30

# AI Worker Deployment (CPU baseline, GPU for heavy tasks)
---
kind: Deployment
metadata:
  name: crayoli-ai-worker
  namespace: crayoli-ai
spec:
  replicas: 2  # Base; HPA scales to 10 based on queue depth
  template:
    spec:
      containers:
        - name: ai-worker
          image: crayoli/ai:latest
          resources:
            requests:
              memory: "4Gi"
              cpu: "2"
            limits:
              memory: "8Gi"
              cpu: "4"
              nvidia.com/gpu: "0"  # 0 for CPU, 1 for GPU nodes
```

### HPA — Auto Scaling

```yaml
# Scale API pods based on CPU
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: crayoli-api-hpa
spec:
  scaleTargetRef:
    kind: Deployment
    name: crayoli-api
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 65

# Scale AI workers based on queue depth (custom metric)
---
metadata:
  name: crayoli-ai-worker-hpa
spec:
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: External
      external:
        metric:
          name: redis_queue_depth
          selector:
            matchLabels:
              queue: garment_processing
        target:
          type: AverageValue
          averageValue: "5"  # Scale up when >5 jobs per worker
```

### CI/CD Pipeline

```
GitHub Push → GitHub Actions:

  PR Check:
    ├── Lint (ruff + eslint)
    ├── Type check (mypy + tsc)
    ├── Unit tests (pytest + vitest)
    └── Build check (docker build --no-cache)

  Merge to main → Staging Deploy:
    ├── Build Docker images (multi-arch)
    ├── Push to ECR
    ├── Run integration tests against staging DB
    ├── Helm upgrade (staging)
    ├── Smoke tests (k6)
    └── Notify Slack

  Manual approval → Production Deploy:
    ├── Helm upgrade (production) — rolling update
    ├── Verify readiness probes
    ├── Canary: 10% traffic for 5min
    ├── Monitor: error rate < 0.1%, p99 < 500ms
    └── Full rollout or automatic rollback
```

---

## 6. Security Architecture

### Authentication & Authorization

**JWT Strategy:**
```
Access Token:  15min expiry | HS256 signed | payload: {user_id, email, tier, founder_access}
Refresh Token: 7 days expiry | stored in httpOnly cookie | rotated on use
```

**Acceso irrestricto — regla central del sistema:**

Ana María (`founder_access = true`) tiene acceso garantizado a todas las funcionalidades sin ninguna verificación de tier. El sistema de autorización sigue esta lógica en todos los endpoints y guards:

```python
# core/permissions.py

def can_access_feature(user: User, feature: Feature) -> bool:
    """
    Ana María (founder_access=True) siempre puede acceder a todo.
    Para futuros usuarios, se evalúa el tier.
    """
    if user.founder_access:
        return True  # Acceso total — sin más verificaciones

    return feature in TIER_FEATURES[user.tier]

# Dependency de FastAPI — se aplica en cualquier endpoint que requiera feature check
async def require_feature(
    feature: Feature,
    current_user: User = Depends(get_current_user),
) -> User:
    if not can_access_feature(current_user, feature):
        raise HTTPException(
            status_code=403,
            detail={
                "code": "FEATURE_RESTRICTED",
                "message": "Upgrade to Premium to access this feature.",
                "upgrade_url": "https://crayoli.app/upgrade",
            }
        )
    return current_user

# Ejemplo de uso en un endpoint
@router.get("/analytics/full-history")
async def get_full_history(
    user: User = Depends(require_feature(Feature.ANALYTICS_FULL_HISTORY)),
):
    ...  # founder_access=True → siempre pasa, sin redirección a upgrade
```

```python
# constants/features.py

class Feature(str, Enum):
    GARMENTS_UNLIMITED       = "garments_unlimited"
    RECOMMENDATIONS_FULL     = "recommendations_full"
    AI_STYLIST_CHAT          = "ai_stylist_chat"
    STYLE_DNA_FULL           = "style_dna_full"
    PACKING_ASSISTANT        = "packing_assistant"
    ANALYTICS_FULL_HISTORY   = "analytics_full_history"
    SEASONAL_MODE            = "seasonal_mode"
    AI_PRIORITY_PROCESSING   = "ai_priority_processing"
    VIRTUAL_TRYON            = "virtual_tryon"
    PINTEREST_INTEGRATION    = "pinterest_integration"
    MOODBOARD_STUDIO         = "moodboard_studio"
    SUSTAINABILITY_SCORE     = "sustainability_score"

TIER_FEATURES: dict[str, set[Feature]] = {
    "founder": set(Feature),          # Todas las features — siempre
    "atelier": set(Feature),          # Todas las features
    "premium": {                       # La mayoría — sin algunas V3+
        Feature.GARMENTS_UNLIMITED,
        Feature.RECOMMENDATIONS_FULL,
        Feature.AI_STYLIST_CHAT,
        Feature.STYLE_DNA_FULL,
        Feature.PACKING_ASSISTANT,
        Feature.ANALYTICS_FULL_HISTORY,
        Feature.SEASONAL_MODE,
        Feature.AI_PRIORITY_PROCESSING,
    },
    "essentials": {                    # Features básicas
        # Sin AI chat, sin packing, sin full history
    },
}
```

**OAuth Providers:**
- Google OAuth 2.0 (`openid email profile`)
- Apple Sign In

**Token Rotation:**
```python
async def refresh_access_token(refresh_token: str) -> TokenPair:
    # Validate refresh token
    payload = decode_token(refresh_token, SECRET_KEY)

    # Check revocation list (Redis)
    if await redis.sismember("revoked_tokens", payload["jti"]):
        raise HTTPException(401, "Token revoked")

    # Rotate: revoke old, issue new pair
    await redis.sadd("revoked_tokens", payload["jti"])
    await redis.expireat("revoked_tokens", payload["exp"])

    return create_token_pair(user_id=payload["sub"])
```

### Image Security

- S3 bucket: **private** (no public access)
- Image access: CloudFront signed URLs with 15-minute expiry
- Upload: presigned S3 POST URL (30-second expiry) — client uploads directly, bypassing API server
- Images are tied to user_id at storage path: `s3://crayoli-images/{user_id}/{garment_id}/`

### Rate Limiting

```python
# Redis-backed sliding window rate limiter
RATE_LIMITS = {
    "/auth/login":            RateLimit(10, "15m"),
    "/garments/upload":       RateLimit(50, "1h"),
    "/recommendations":       RateLimit(100, "1h"),
    "/outfits":              RateLimit(200, "1h"),
    "default":               RateLimit(1000, "1h"),
}
```

### Data Privacy

- All garment images encrypted at rest (S3 SSE-KMS)
- Database encrypted at rest (RDS encryption)
- PII fields in DB: encrypted at application layer (Fernet symmetric)
- Full GDPR compliance:
  - `/api/user/export` → ZIP of all user data
  - `/api/user/delete` → cascading soft delete → hard delete after 30 days

---

*Architecture Specification v1.0 — Crayoli Engineering*
