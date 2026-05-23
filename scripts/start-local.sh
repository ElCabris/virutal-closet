#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Crayoli Closet — Arranque local (sin Docker para web/api)
# Requiere: Node, Python 3.12, uv, PostgreSQL, Redis corriendo
# ─────────────────────────────────────────────────────────────────────────────
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WEB="$ROOT/apps/web"
API="$ROOT/apps/api"

echo ""
echo "  C R A Y O L I  — iniciando..."
echo ""

# ── 1. API dependencies ───────────────────────────────────────────────────────
echo "→ Instalando dependencias de API..."
cd "$API"
uv sync --quiet

# ── 2. Run migrations ─────────────────────────────────────────────────────────
echo "→ Corriendo migraciones de base de datos..."
uv run alembic upgrade head

# ── 3. Seed founder user ──────────────────────────────────────────────────────
echo "→ Creando usuario Ana María (founder)..."
uv run python -m scripts.seed

# ── 4. Start API in background ────────────────────────────────────────────────
echo "→ Iniciando API en http://localhost:8000 ..."
uv run uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload &
API_PID=$!

# ── 5. Web dependencies ───────────────────────────────────────────────────────
echo "→ Instalando dependencias de web..."
cd "$WEB"
pnpm install --silent

# ── 6. Start web ──────────────────────────────────────────────────────────────
echo "→ Iniciando web en http://localhost:3000 ..."
echo ""
echo "  ✓ API:    http://localhost:8000"
echo "  ✓ Docs:   http://localhost:8000/docs"
echo "  ✓ Web:    http://localhost:3000"
echo ""
echo "  Credenciales:"
echo "  Email:    ana@crayoli.app"
echo "  Password: Crayoli2026!"
echo ""
echo "  Ctrl+C para detener todo"
echo ""

pnpm dev &
WEB_PID=$!

# Cleanup on exit
trap "kill $API_PID $WEB_PID 2>/dev/null; echo 'Crayoli detenido.'" EXIT INT TERM
wait
