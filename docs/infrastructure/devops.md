# Crayoli Closet — DevOps, Observability & Infrastructure
**Version:** 1.0 | **Cloud:** AWS | **Orchestration:** Kubernetes (EKS)

---

## 1. Docker Configuration

### API Dockerfile

```dockerfile
# apps/api/Dockerfile
FROM python:3.12-slim AS builder

WORKDIR /app

# Install uv (fast dependency resolver)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

FROM python:3.12-slim AS runtime

WORKDIR /app

# Non-root user
RUN groupadd -r crayoli && useradd -r -g crayoli crayoli

COPY --from=builder /app/.venv /app/.venv
COPY src/ ./src/

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

USER crayoli

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD python -c "import httpx; httpx.get('http://localhost:8000/health', timeout=5).raise_for_status()"

CMD ["gunicorn", "src.main:app",
     "--workers", "4",
     "--worker-class", "uvicorn.workers.UvicornWorker",
     "--bind", "0.0.0.0:8000",
     "--timeout", "120",
     "--keepalive", "5",
     "--access-logfile", "-",
     "--error-logfile", "-"]
```

### AI Service Dockerfile

```dockerfile
# apps/ai/Dockerfile — CPU variant
FROM python:3.12-slim AS runtime

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

COPY src/ ./src/
COPY models/ ./models/          # Bundled model weights (or mount from EFS)

ENV PYTHONPATH=/app
ENV TORCH_HOME=/app/models/torch_cache
ENV TRANSFORMERS_CACHE=/app/models/hf_cache

# Non-root
RUN useradd -r -u 1001 aiworker
USER aiworker

CMD ["python", "-m", "celery", "-A", "src.workers.celery_app", "worker",
     "--loglevel=info",
     "--concurrency=2",
     "--queues=garment_processing,recommendations"]
```

### Frontend Dockerfile

```dockerfile
# apps/web/Dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system crayoli && adduser --system --group crayoli

COPY --from=builder /app/public ./public
COPY --from=builder --chown=crayoli:crayoli /app/.next/standalone ./
COPY --from=builder --chown=crayoli:crayoli /app/.next/static ./.next/static

USER crayoli
EXPOSE 3000

CMD ["node", "server.js"]
```

### Docker Compose — Development

```yaml
# docker-compose.yml
version: '3.9'

services:
  api:
    build:
      context: ./apps/api
      target: runtime
    volumes:
      - ./apps/api/src:/app/src  # Hot reload in dev
    environment:
      - DATABASE_URL=postgresql://crayoli:crayoli@postgres:5432/crayoli_dev
      - REDIS_URL=redis://redis:6379/0
      - AI_SERVICE_URL=http://ai:8001
      - S3_BUCKET=crayoli-dev-local
      - ENVIRONMENT=development
      - JWT_SECRET=dev-secret-change-in-prod
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  ai:
    build:
      context: ./apps/ai
    volumes:
      - ./apps/ai/src:/app/src
      - ai_models:/app/models    # Persistent model cache
    environment:
      - REDIS_URL=redis://redis:6379/0
      - DATABASE_URL=postgresql://crayoli:crayoli@postgres:5432/crayoli_dev
      - PINECONE_API_KEY=${PINECONE_API_KEY}
    depends_on:
      - redis

  web:
    build:
      context: ./apps/web
      target: deps             # Dev: use source + hot reload
    volumes:
      - ./apps/web:/app
      - /app/node_modules
      - /app/.next
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000/v1
      - NEXT_PUBLIC_WS_URL=ws://localhost:8000/v1/ws
    ports:
      - "3000:3000"
    command: pnpm dev

  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: crayoli_dev
      POSTGRES_USER: crayoli
      POSTGRES_PASSWORD: crayoli
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U crayoli"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  localstack:
    image: localstack/localstack:latest
    environment:
      SERVICES: s3
      AWS_DEFAULT_REGION: us-east-1
    ports:
      - "4566:4566"
    volumes:
      - localstack_data:/tmp/localstack

volumes:
  postgres_data:
  ai_models:
  localstack_data:
```

---

## 2. CI/CD — GitHub Actions

### PR Validation Pipeline

```yaml
# .github/workflows/pr.yml
name: PR Validation

on:
  pull_request:
    branches: [main, develop]

jobs:
  lint-api:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v1
      - run: cd apps/api && uv run ruff check src/
      - run: cd apps/api && uv run mypy src/ --ignore-missing-imports

  lint-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: cd apps/web && pnpm install --frozen-lockfile
      - run: cd apps/web && pnpm lint
      - run: cd apps/web && pnpm type-check

  test-api:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: pgvector/pgvector:pg16
        env:
          POSTGRES_DB: crayoli_test
          POSTGRES_USER: crayoli
          POSTGRES_PASSWORD: crayoli
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v1
      - run: cd apps/api && uv run alembic upgrade head
        env:
          DATABASE_URL: postgresql://crayoli:crayoli@localhost:5432/crayoli_test
      - run: cd apps/api && uv run pytest tests/ -v --cov=src --cov-report=xml
        env:
          DATABASE_URL: postgresql://crayoli:crayoli@localhost:5432/crayoli_test
          REDIS_URL: redis://localhost:6379/0
          JWT_SECRET: test-secret
          ENVIRONMENT: test

  test-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: cd apps/web && pnpm install --frozen-lockfile
      - run: cd apps/web && pnpm test

  build:
    runs-on: ubuntu-latest
    needs: [lint-api, lint-web, test-api, test-web]
    steps:
      - uses: actions/checkout@v4
      - name: Build API image
        run: docker build apps/api -f apps/api/Dockerfile --target runtime
      - name: Build Web image
        run: docker build apps/web -f apps/web/Dockerfile --target runner
```

### Staging Deploy Pipeline

```yaml
# .github/workflows/deploy-staging.yml
name: Deploy to Staging

on:
  push:
    branches: [main]

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_STAGING_ROLE_ARN }}
          aws-region: us-east-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push images
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build apps/api -t $ECR_REGISTRY/crayoli-api:$IMAGE_TAG -t $ECR_REGISTRY/crayoli-api:staging
          docker build apps/ai -t $ECR_REGISTRY/crayoli-ai:$IMAGE_TAG -t $ECR_REGISTRY/crayoli-ai:staging
          docker build apps/web -t $ECR_REGISTRY/crayoli-web:$IMAGE_TAG -t $ECR_REGISTRY/crayoli-web:staging
          docker push $ECR_REGISTRY/crayoli-api --all-tags
          docker push $ECR_REGISTRY/crayoli-ai --all-tags
          docker push $ECR_REGISTRY/crayoli-web --all-tags

      - name: Run DB migrations
        run: |
          kubectl exec -n crayoli-api deploy/crayoli-api -- \
            alembic upgrade head
        env:
          KUBECONFIG: ${{ secrets.KUBE_CONFIG_STAGING }}

      - name: Helm upgrade staging
        run: |
          helm upgrade crayoli ./helm/crayoli \
            --namespace crayoli-api \
            --set image.tag=${{ github.sha }} \
            --set environment=staging \
            --wait --timeout 5m
        env:
          KUBECONFIG: ${{ secrets.KUBE_CONFIG_STAGING }}

      - name: Run smoke tests
        run: |
          k6 run tests/smoke/api-smoke.js \
            --env BASE_URL=https://api-staging.crayoli.app

      - name: Notify Slack
        if: always()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Staging deploy ${{ job.status }}: ${{ github.sha }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## 3. Observability Stack

### Metrics & Monitoring

**Primary stack:** Grafana + Prometheus + Loki (open-source, self-hosted on EKS)

```yaml
# prometheus scrape config
scrape_configs:
  - job_name: crayoli-api
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: [crayoli-api]
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: "true"
```

**Key dashboards (Grafana):**
1. **API Health** — request rate, error rate, p50/p95/p99 latency per endpoint
2. **AI Pipeline** — queue depth, job processing time, success/failure rate per stage
3. **Business Metrics** — uploads per hour, recommendations generated, outfits saved
4. **Infrastructure** — CPU/memory per pod, node pressure, disk I/O

### Structured Logging

```python
# All logs are JSON structured — parsed by Loki
import structlog

log = structlog.get_logger()

# Request logging
log.info("api.request",
    method="POST",
    path="/v1/garments",
    user_id=str(user.id),
    duration_ms=142,
    status_code=201,
)

# AI pipeline logging
log.info("ai.garment.processed",
    garment_id=str(garment.id),
    user_id=str(user_id),
    stage="classification",
    category_predicted="tops",
    confidence=0.94,
    duration_ms=1240,
)

# Recommendation logging (explainability)
log.info("recommendation.generated",
    user_id=str(user.id),
    recommendation_id=str(rec.id),
    outfit_count=3,
    weather_temp_c=14.0,
    top_scores=[0.94, 0.87, 0.82],
    generation_ms=820,
)
```

### Distributed Tracing

```python
# OpenTelemetry instrumentation
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument(engine=engine)

# Custom spans for AI pipeline
with trace.get_tracer(__name__).start_as_current_span("ai.background_removal") as span:
    span.set_attribute("garment.id", str(garment_id))
    span.set_attribute("model.name", "SAM-vit-h")
    result = await remove_background(image)
    span.set_attribute("processing.success", True)
```

### Alerting Rules

```yaml
# Prometheus alerting rules
groups:
  - name: crayoli-critical
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Error rate above 5%"

      - alert: AIQueueBacklog
        expr: redis_queue_depth{queue="garment_processing"} > 50
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "AI processing queue backed up (>50 jobs)"

      - alert: HighAPILatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1.0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "API p95 latency above 1 second"

      - alert: DatabaseConnectionSaturation
        expr: pg_stat_activity_count / pg_settings_max_connections > 0.80
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL connections at 80% capacity"
```

---

## 4. Infrastructure Cost Estimate

### MVP (Single User / Beta)

| Service | Spec | Monthly Cost |
|---------|------|-------------|
| EKS Cluster | 3× t3.medium nodes | ~$100 |
| RDS PostgreSQL | db.t3.medium, 20GB | ~$30 |
| ElastiCache Redis | cache.t3.micro | ~$15 |
| S3 Storage | 100GB | ~$2 |
| Cloudinary | Free tier | $0 |
| CloudFront | 100GB transfer | ~$8 |
| **Total** | | **~$155/month** |

### V1 (100-500 Users)

| Service | Spec | Monthly Cost |
|---------|------|-------------|
| EKS | 3× t3.large (API) + 2× t3.xlarge (AI) | ~$300 |
| RDS | db.t3.large, Multi-AZ, 100GB | ~$120 |
| ElastiCache | cache.t3.small, 2 replicas | ~$50 |
| S3 | 1TB | ~$23 |
| Cloudinary | Plus plan | ~$89 |
| CloudFront | 1TB transfer | ~$85 |
| Pinecone | Starter | $70 |
| **Total** | | **~$737/month** |

### V2 (5,000+ Users)

| Service | Spec | Monthly Cost |
|---------|------|-------------|
| EKS | 6× t3.xlarge (API) + 4× g4dn.xlarge (AI GPU) | ~$2,400 |
| RDS | db.r6g.xlarge, Multi-AZ, 500GB | ~$500 |
| ElastiCache | cache.r6g.large, cluster | ~$200 |
| S3 | 10TB | ~$230 |
| Cloudinary | Business | ~$249 |
| CloudFront | 10TB | ~$850 |
| Pinecone | Standard | ~$160 |
| **Total** | | **~$4,589/month** |

---

## 5. Security Hardening

### Secrets Management

```yaml
# All secrets via AWS Secrets Manager — never in code or env vars directly
# Kubernetes ExternalSecrets operator syncs to k8s secrets

apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: crayoli-api-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: crayoli-api-secrets
  data:
    - secretKey: DATABASE_URL
      remoteRef:
        key: /crayoli/production/database_url
    - secretKey: JWT_SECRET
      remoteRef:
        key: /crayoli/production/jwt_secret
    - secretKey: ANTHROPIC_API_KEY
      remoteRef:
        key: /crayoli/production/anthropic_api_key
```

### Network Policies

```yaml
# Deny all inter-pod traffic by default; explicitly allow required paths
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-to-ai
  namespace: crayoli-api
spec:
  podSelector:
    matchLabels:
      app: crayoli-api
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: crayoli-ai
      ports:
        - port: 8001

# AI workers can only reach Redis and PostgreSQL — not the public internet directly
```

### Pod Security

```yaml
# All pods run as non-root, read-only filesystem where possible
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

---

*DevOps & Infrastructure v1.0 — Crayoli Engineering*
