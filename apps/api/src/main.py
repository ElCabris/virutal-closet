from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from src.config import get_settings
from src.core.redis import close_redis, get_redis
from src.routers import analytics, auth, garments, outfits, profile, recommendations, wishlist

settings = get_settings()

limiter = Limiter(key_func=get_remote_address)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_redis()
    yield
    await close_redis()


app = FastAPI(
    title="Crayoli API",
    description="Fashion intelligence platform for Ana María",
    version="0.2.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/v1")
app.include_router(garments.router, prefix="/v1")
app.include_router(recommendations.router, prefix="/v1")
app.include_router(outfits.router, prefix="/v1")
app.include_router(analytics.router, prefix="/v1")
app.include_router(wishlist.router, prefix="/v1")
app.include_router(profile.router, prefix="/v1")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "crayoli-api", "version": "0.2.0"}


@app.get("/")
async def root():
    return {"message": "Crayoli API — Your closet, curated."}
