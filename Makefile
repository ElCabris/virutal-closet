API_DIR  := apps/api
WEB_DIR  := apps/web
PYTHON   := $(API_DIR)/.venv/bin/python
UVICORN  := $(API_DIR)/.venv/bin/uvicorn
ALEMBIC  := $(API_DIR)/.venv/bin/alembic

.DEFAULT_GOAL := help

# ── Help ───────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ── Setup ──────────────────────────────────────────────────────────────────────
.PHONY: setup
setup: setup-api setup-web ## Instala todas las dependencias (API + Web)

.PHONY: setup-api
setup-api: ## Instala dependencias del API con uv
	cd $(API_DIR) && uv sync
	@[ -f $(API_DIR)/.env ] || cp ../.env.example $(API_DIR)/.env && echo "Creado $(API_DIR)/.env — revisa las variables"

.PHONY: setup-web
setup-web: ## Instala dependencias del frontend con pnpm
	cd $(WEB_DIR) && pnpm install
	@[ -f $(WEB_DIR)/.env.local ] || echo "NEXT_PUBLIC_API_URL=http://localhost:8000/v1" > $(WEB_DIR)/.env.local

# ── Docker ─────────────────────────────────────────────────────────────────────
.PHONY: up
up: ## Levanta todos los servicios con Docker Compose
	docker compose up --build

.PHONY: up-d
up-d: ## Levanta todos los servicios en background
	docker compose up --build -d

.PHONY: down
down: ## Detiene todos los servicios
	docker compose down

.PHONY: down-v
down-v: ## Detiene todos los servicios y elimina volúmenes
	docker compose down -v

.PHONY: infra
infra: ## Solo levanta postgres + redis (para dev local)
	docker compose up postgres redis -d

.PHONY: logs
logs: ## Muestra los logs de todos los servicios
	docker compose logs -f

.PHONY: logs-api
logs-api: ## Muestra los logs del API
	docker compose logs -f api

.PHONY: logs-web
logs-web: ## Muestra los logs del frontend
	docker compose logs -f web

# ── Dev local ──────────────────────────────────────────────────────────────────
.PHONY: dev-api
dev-api: ## Inicia el API en modo desarrollo (requiere infra corriendo)
	cd $(API_DIR) && $(UVICORN) src.main:app --reload --port 8000

.PHONY: dev-web
dev-web: ## Inicia el frontend en modo desarrollo
	cd $(WEB_DIR) && pnpm dev

# ── Base de datos ──────────────────────────────────────────────────────────────
.PHONY: migrate
migrate: ## Aplica todas las migraciones pendientes
	cd $(API_DIR) && $(ALEMBIC) upgrade head

.PHONY: migrate-down
migrate-down: ## Revierte la última migración
	cd $(API_DIR) && $(ALEMBIC) downgrade -1

.PHONY: migrate-status
migrate-status: ## Muestra el estado de las migraciones
	cd $(API_DIR) && $(ALEMBIC) current && $(ALEMBIC) history --verbose

.PHONY: migrate-new
migrate-new: ## Crea una nueva migración (uso: make migrate-new name="descripcion")
	@[ -n "$(name)" ] || (echo "Uso: make migrate-new name=\"descripcion\"" && exit 1)
	cd $(API_DIR) && $(ALEMBIC) revision --autogenerate -m "$(name)"

.PHONY: seed
seed: ## Crea el usuario de Ana María y datos de ejemplo
	cd $(API_DIR) && $(PYTHON) -m scripts.seed

.PHONY: db-reset
db-reset: ## Resetea la DB: baja todas las migraciones y vuelve a aplicarlas + seed
	cd $(API_DIR) && $(ALEMBIC) downgrade base && $(ALEMBIC) upgrade head && $(PYTHON) -m scripts.seed

# ── Calidad ────────────────────────────────────────────────────────────────────
.PHONY: lint
lint: lint-api lint-web ## Ejecuta linters en API y Web

.PHONY: lint-api
lint-api: ## Ruff lint en el API
	cd $(API_DIR) && .venv/bin/ruff check src/ scripts/

.PHONY: lint-web
lint-web: ## ESLint en el frontend
	cd $(WEB_DIR) && pnpm lint

.PHONY: format
format: ## Formatea el código (ruff + prettier)
	cd $(API_DIR) && .venv/bin/ruff format src/ scripts/
	cd $(WEB_DIR) && pnpm exec prettier --write "**/*.{ts,tsx}" --ignore-path .gitignore

.PHONY: typecheck
typecheck: ## TypeScript type check
	cd $(WEB_DIR) && pnpm type-check

.PHONY: test
test: test-api ## Ejecuta los tests

.PHONY: test-api
test-api: ## Ejecuta pytest
	cd $(API_DIR) && .venv/bin/pytest tests/ -v

# ── Utilidades ─────────────────────────────────────────────────────────────────
.PHONY: shell-api
shell-api: ## Abre una shell Python con el contexto del API
	cd $(API_DIR) && $(PYTHON) -i -c "from src.config import get_settings; s=get_settings(); print('Settings cargadas')"

.PHONY: psql
psql: ## Conecta a la base de datos local
	docker compose exec postgres psql -U crayoli -d crayoli_dev

.PHONY: redis-cli
redis-cli: ## Abre el cliente de Redis
	docker compose exec redis redis-cli

.PHONY: clean
clean: ## Elimina cachés y archivos temporales
	find $(API_DIR) -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true
	find $(API_DIR) -name "*.pyc" -delete 2>/dev/null; true
	rm -rf $(WEB_DIR)/.next
