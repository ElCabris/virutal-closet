# Crayoli Closet — Complete Project Structure
**Version:** 1.0 | **Monorepo:** pnpm workspaces + Turborepo

---

## Repository Layout

```
crayoli-closet/
├── .github/
│   ├── workflows/
│   │   ├── pr.yml                       # PR validation
│   │   ├── deploy-staging.yml           # Auto-deploy on merge to main
│   │   └── deploy-production.yml        # Manual trigger + approval gate
│   └── CODEOWNERS
│
├── apps/
│   ├── web/                             # Next.js 14 web application
│   │   ├── app/
│   │   │   ├── (auth)/
│   │   │   │   ├── login/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── signup/
│   │   │   │   │   └── page.tsx
│   │   │   │   └── onboarding/
│   │   │   │       ├── page.tsx
│   │   │   │       └── layout.tsx
│   │   │   ├── (app)/
│   │   │   │   ├── layout.tsx           # App shell (nav, providers)
│   │   │   │   ├── home/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── closet/
│   │   │   │   │   ├── page.tsx         # Grid view
│   │   │   │   │   └── [id]/
│   │   │   │   │       └── page.tsx     # Garment detail
│   │   │   │   ├── builder/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── discover/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── calendar/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── analytics/
│   │   │   │   │   └── page.tsx
│   │   │   │   ├── wishlist/
│   │   │   │   │   └── page.tsx
│   │   │   │   └── profile/
│   │   │   │       ├── page.tsx
│   │   │   │       └── settings/
│   │   │   │           └── page.tsx
│   │   │   ├── api/
│   │   │   │   └── auth/
│   │   │   │       └── [...nextauth]/
│   │   │   │           └── route.ts
│   │   │   ├── layout.tsx               # Root layout (fonts, metadata, providers)
│   │   │   ├── not-found.tsx
│   │   │   └── error.tsx
│   │   │
│   │   ├── components/
│   │   │   ├── ui/                      # Primitive design system components
│   │   │   │   ├── Button/
│   │   │   │   │   ├── Button.tsx
│   │   │   │   │   ├── Button.stories.tsx
│   │   │   │   │   ├── Button.test.tsx
│   │   │   │   │   └── index.ts
│   │   │   │   ├── Input/
│   │   │   │   ├── Card/
│   │   │   │   ├── Badge/
│   │   │   │   ├── Avatar/
│   │   │   │   ├── Modal/
│   │   │   │   ├── Sheet/               # Bottom sheet
│   │   │   │   ├── Skeleton/
│   │   │   │   ├── Toast/
│   │   │   │   ├── Tooltip/
│   │   │   │   ├── ColorSwatch/
│   │   │   │   ├── MoodBadge/
│   │   │   │   ├── GarmentCard/
│   │   │   │   ├── OutfitCard/
│   │   │   │   └── index.ts             # Barrel export
│   │   │   │
│   │   │   ├── layout/
│   │   │   │   ├── AppShell/
│   │   │   │   ├── Sidebar/
│   │   │   │   ├── BottomNav/
│   │   │   │   ├── TopBar/
│   │   │   │   └── PageContainer/
│   │   │   │
│   │   │   └── features/
│   │   │       ├── closet/
│   │   │       │   ├── ClosetGrid/
│   │   │       │   ├── ClosetFilters/
│   │   │       │   ├── GarmentUploadFlow/
│   │   │       │   │   ├── UploadDropzone/
│   │   │       │   │   ├── CameraCapture/
│   │   │       │   │   └── UploadProgress/
│   │   │       │   ├── GarmentDetail/
│   │   │       │   └── SortDropdown/
│   │   │       ├── outfits/
│   │   │       │   ├── OutfitBuilder/
│   │   │       │   │   ├── BuilderCanvas/
│   │   │       │   │   ├── ItemBrowser/
│   │   │       │   │   └── HarmonyIndicator/
│   │   │       │   ├── OutfitCard/
│   │   │       │   └── MoodSelector/
│   │   │       ├── recommendations/
│   │   │       │   ├── DailyRecommendations/
│   │   │       │   ├── RecommendationCard/
│   │   │       │   ├── WeatherBanner/
│   │   │       │   └── ReasoningTooltip/
│   │   │       ├── analytics/
│   │   │       │   ├── WardrobeDonut/
│   │   │       │   ├── WearHeatmap/
│   │   │       │   ├── ColorDNA/
│   │   │       │   ├── MostWornList/
│   │   │       │   └── ForgottenGems/
│   │   │       ├── calendar/
│   │   │       │   ├── WeekView/
│   │   │       │   ├── MonthView/
│   │   │       │   ├── DayPlanner/
│   │   │       │   └── EventCard/
│   │   │       └── onboarding/
│   │   │           ├── AestheticQuiz/
│   │   │           ├── ColorPicker/
│   │   │           ├── LifestyleSelector/
│   │   │           └── ProgressDots/
│   │   │
│   │   ├── lib/
│   │   │   ├── api/
│   │   │   │   ├── client.ts            # Base typed fetch client
│   │   │   │   ├── garments.ts
│   │   │   │   ├── outfits.ts
│   │   │   │   ├── recommendations.ts
│   │   │   │   ├── analytics.ts
│   │   │   │   ├── calendar.ts
│   │   │   │   ├── profile.ts
│   │   │   │   └── uploads.ts
│   │   │   ├── hooks/
│   │   │   │   ├── useGarments.ts
│   │   │   │   ├── useOutfits.ts
│   │   │   │   ├── useRecommendations.ts
│   │   │   │   ├── useWeather.ts
│   │   │   │   ├── useOutfitBuilder.ts
│   │   │   │   ├── useWebSocket.ts
│   │   │   │   └── useUpload.ts
│   │   │   ├── stores/
│   │   │   │   ├── uiStore.ts
│   │   │   │   ├── closetStore.ts
│   │   │   │   ├── builderStore.ts
│   │   │   │   └── onboardingStore.ts
│   │   │   └── utils/
│   │   │       ├── colorUtils.ts
│   │   │       ├── imageUtils.ts
│   │   │       ├── dateUtils.ts
│   │   │       └── formatters.ts
│   │   │
│   │   ├── styles/
│   │   │   ├── globals.css
│   │   │   └── tokens.css
│   │   │
│   │   ├── public/
│   │   │   ├── icons/
│   │   │   ├── illustrations/
│   │   │   └── fonts/
│   │   │
│   │   ├── next.config.js
│   │   ├── tailwind.config.js
│   │   ├── tsconfig.json
│   │   ├── package.json
│   │   └── Dockerfile
│   │
│   ├── mobile/                          # React Native / Expo
│   │   ├── app/                         # Expo Router
│   │   │   ├── (tabs)/
│   │   │   │   ├── index.tsx            # Home
│   │   │   │   ├── closet.tsx
│   │   │   │   ├── discover.tsx
│   │   │   │   └── profile.tsx
│   │   │   ├── closet/[id].tsx
│   │   │   ├── builder.tsx
│   │   │   ├── calendar.tsx
│   │   │   └── _layout.tsx
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── assets/
│   │   ├── app.json
│   │   └── package.json
│   │
│   ├── api/                             # FastAPI backend
│   │   ├── src/
│   │   │   ├── main.py
│   │   │   ├── config.py
│   │   │   ├── dependencies.py
│   │   │   ├── middleware/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── auth.py
│   │   │   │   ├── cors.py
│   │   │   │   ├── rate_limit.py
│   │   │   │   └── logging.py
│   │   │   ├── routers/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── auth.py
│   │   │   │   ├── garments.py
│   │   │   │   ├── outfits.py
│   │   │   │   ├── recommendations.py
│   │   │   │   ├── analytics.py
│   │   │   │   ├── calendar.py
│   │   │   │   ├── profile.py
│   │   │   │   ├── search.py
│   │   │   │   ├── uploads.py
│   │   │   │   └── ws.py               # WebSocket
│   │   │   ├── services/
│   │   │   │   ├── auth_service.py
│   │   │   │   ├── garment_service.py
│   │   │   │   ├── outfit_service.py
│   │   │   │   ├── recommendation_service.py
│   │   │   │   ├── analytics_service.py
│   │   │   │   ├── upload_service.py
│   │   │   │   ├── notification_service.py
│   │   │   │   └── weather_service.py
│   │   │   ├── repositories/
│   │   │   │   ├── base.py
│   │   │   │   ├── garment_repo.py
│   │   │   │   ├── outfit_repo.py
│   │   │   │   ├── user_repo.py
│   │   │   │   └── style_profile_repo.py
│   │   │   ├── models/                  # SQLAlchemy ORM models
│   │   │   │   ├── base.py
│   │   │   │   ├── user.py
│   │   │   │   ├── garment.py
│   │   │   │   ├── outfit.py
│   │   │   │   ├── style_profile.py
│   │   │   │   ├── event.py
│   │   │   │   └── wear_log.py
│   │   │   ├── schemas/                 # Pydantic schemas
│   │   │   │   ├── auth.py
│   │   │   │   ├── garment.py
│   │   │   │   ├── outfit.py
│   │   │   │   ├── recommendation.py
│   │   │   │   ├── analytics.py
│   │   │   │   └── common.py
│   │   │   ├── core/
│   │   │   │   ├── security.py
│   │   │   │   ├── exceptions.py
│   │   │   │   ├── responses.py
│   │   │   │   └── database.py
│   │   │   ├── workers/                 # Celery tasks
│   │   │   │   ├── celery_app.py
│   │   │   │   ├── image_processor.py
│   │   │   │   ├── ai_classifier.py
│   │   │   │   ├── recommendation_worker.py
│   │   │   │   └── notification_worker.py
│   │   │   └── integrations/
│   │   │       ├── s3.py
│   │   │       ├── cloudinary.py
│   │   │       ├── openweather.py
│   │   │       ├── pinecone_client.py
│   │   │       └── anthropic_client.py
│   │   ├── tests/
│   │   │   ├── conftest.py
│   │   │   ├── unit/
│   │   │   ├── integration/
│   │   │   └── e2e/
│   │   ├── alembic/
│   │   │   ├── versions/
│   │   │   ├── env.py
│   │   │   └── script.py.mako
│   │   ├── pyproject.toml
│   │   ├── uv.lock
│   │   └── Dockerfile
│   │
│   └── ai/                              # AI processing service
│       ├── src/
│       │   ├── main.py                  # Internal FastAPI for health/debug
│       │   ├── config.py
│       │   ├── pipeline/
│       │   │   ├── orchestrator.py      # Full pipeline coordinator
│       │   │   ├── validator.py         # Image quality validation
│       │   │   ├── background_removal.py
│       │   │   ├── classification.py
│       │   │   ├── embedding.py
│       │   │   ├── color_extraction.py
│       │   │   └── tag_generator.py     # Claude Haiku integration
│       │   ├── models/
│       │   │   ├── registry.py          # Singleton model loader
│       │   │   ├── clip_model.py
│       │   │   ├── sam_model.py
│       │   │   ├── fashion_classifier.py
│       │   │   └── pattern_detector.py
│       │   ├── recommender/
│       │   │   ├── engine.py
│       │   │   ├── scoring.py
│       │   │   ├── context_builder.py
│       │   │   ├── color_harmony.py
│       │   │   └── style_dna.py
│       │   └── workers/
│       │       ├── celery_app.py
│       │       └── tasks.py
│       ├── models/                      # Model weights (gitignored, mounted from EFS)
│       │   └── .gitkeep
│       ├── tests/
│       ├── pyproject.toml
│       └── Dockerfile
│
├── packages/
│   └── shared/                          # Shared types + utils
│       ├── src/
│       │   ├── types/
│       │   │   ├── api.ts
│       │   │   ├── domain.ts
│       │   │   └── index.ts
│       │   ├── utils/
│       │   │   ├── color.ts
│       │   │   ├── date.ts
│       │   │   └── format.ts
│       │   ├── validators/              # Zod schemas
│       │   │   ├── garment.ts
│       │   │   ├── outfit.ts
│       │   │   └── auth.ts
│       │   └── constants/
│       │       ├── categories.ts
│       │       ├── moods.ts
│       │       └── occasions.ts
│       ├── tsconfig.json
│       └── package.json
│
├── helm/
│   └── crayoli/                         # Helm chart for k8s deployment
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values.staging.yaml
│       ├── values.production.yaml
│       └── templates/
│           ├── api-deployment.yaml
│           ├── ai-deployment.yaml
│           ├── web-deployment.yaml
│           ├── ingress.yaml
│           ├── hpa.yaml
│           └── secrets.yaml
│
├── docs/                                # This documentation
│   ├── brand/
│   │   └── identity.md
│   ├── product/
│   │   ├── prd.md
│   │   ├── screens.md
│   │   └── ux-flows.md
│   ├── technical/
│   │   ├── architecture.md
│   │   ├── database.md
│   │   ├── api-design.md
│   │   └── project-structure.md
│   ├── infrastructure/
│   │   └── devops.md
│   └── roadmap/
│       └── roadmap.md
│
├── scripts/
│   ├── dev-setup.sh                     # One-command dev environment setup
│   ├── db-seed.py                       # Development data seeding
│   └── model-download.sh               # Download AI model weights
│
├── .env.example
├── .gitignore
├── .dockerignore
├── turbo.json                           # Turborepo config
├── pnpm-workspace.yaml
├── package.json
└── README.md
```

---

## Environment Variables

### API Service

```bash
# .env.example — API
DATABASE_URL=postgresql://user:pass@localhost:5432/crayoli
REDIS_URL=redis://localhost:6379/0

# Auth
JWT_SECRET=<32-char-random-string>
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=15
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
APPLE_CLIENT_ID=

# Storage
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=us-east-1
S3_BUCKET_NAME=crayoli-images
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# External APIs
OPENWEATHER_API_KEY=
ANTHROPIC_API_KEY=

# AI Service (internal)
AI_SERVICE_URL=http://ai:8001
PINECONE_API_KEY=
PINECONE_INDEX_NAME=crayoli-garments

# App
ENVIRONMENT=development
CORS_ORIGINS=["http://localhost:3000"]
LOG_LEVEL=INFO
```

### Web App

```bash
# .env.local — Next.js web
NEXT_PUBLIC_API_URL=http://localhost:8000/v1
NEXT_PUBLIC_WS_URL=ws://localhost:8000/v1/ws
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=

# Server-only
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

---

*Project Structure v1.0 — Crayoli Engineering*
