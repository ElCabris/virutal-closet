# Crayoli Closet

> *Your closet, curated.*

Crayoli Closet is a premium AI-powered virtual wardrobe platform — a hyper-personalized fashion intelligence system that functions as an intelligent stylist, closet organizer, and outfit recommender built exclusively for Ana María Mosquera.

---

## Documentation Index

### Brand & Design
- [Brand Identity System](docs/brand/identity.md) — Color system, typography, design tokens, motion principles

### Product
- [Product Requirements Document](docs/product/prd.md) — Full feature specs, user flows, success metrics
- [Screen Specifications](docs/product/screens.md) — Detailed layout specs for all 16 screens
- [UX Flows & Microinteractions](docs/product/ux-flows.md) — Interaction patterns, animation library, empty states

### Technical Architecture
- [System Architecture](docs/technical/architecture.md) — Full stack, AI pipeline, recommendation engine
- [Database Design](docs/technical/database.md) — Schema, indexes, key queries, performance strategy
- [API Design](docs/technical/api-design.md) — REST endpoints, WebSocket, request/response examples
- [Project Structure](docs/technical/project-structure.md) — Monorepo layout, environment variables

### Infrastructure
- [DevOps & Infrastructure](docs/infrastructure/devops.md) — Docker, CI/CD, Kubernetes, observability, cost estimates

### Strategy
- [Product Roadmap](docs/roadmap/roadmap.md) — MVP → V2, monetization, go-to-market strategy

---

## Technology Stack

```
Frontend:      Next.js 14 + React Native (Expo) + TypeScript + Tailwind + Framer Motion
Backend:       FastAPI (Python 3.12) + PostgreSQL 16 + Redis 7
AI/ML:         CLIP + SAM + YOLOv8 + ViT (fashion fine-tuned) + Claude Haiku
Vector Store:  Pinecone (cloud) / pgvector (embedded)
Storage:       AWS S3 + Cloudinary CDN
Infra:         AWS EKS + Docker + Helm + GitHub Actions
State:         Zustand (client) + TanStack Query (server)
```

## Quick Start (Development)

```bash
# Prerequisites: Docker, pnpm, Python 3.12

# Clone and setup
git clone https://github.com/crayoli/crayoli-closet.git
cd crayoli-closet
cp .env.example .env.local

# Start all services
docker compose up -d

# Install frontend dependencies
pnpm install

# Run migrations
cd apps/api && uv run alembic upgrade head

# Start development servers
pnpm dev         # Web: http://localhost:3000
                 # API: http://localhost:8000
                 # Docs: http://localhost:8000/docs
```

---

## Core Features

| Feature | Description |
|---------|-------------|
| **AI Garment Classification** | Upload → background removal → CLIP embedding → category + style tags |
| **Smart Outfit Recommendations** | Weather + occasion + mood + style DNA → curated outfits |
| **Style DNA** | Continuously learning aesthetic profile — gets smarter with every interaction |
| **Outfit Builder** | Canvas-based manual outfit creation with color harmony analysis |
| **Calendar** | Weekly planning with weather overlays and event-based suggestions |
| **Analytics** | Wear frequency, cost-per-wear, color DNA, wardrobe insights |

---

*Crayoli Closet — Fashion Intelligence for Ana María*
*Version 0.1.0 — Blueprint*
