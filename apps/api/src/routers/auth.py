from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from slowapi import Limiter
from slowapi.util import get_remote_address
from src.core.database import get_db
from src.core.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token,
)
from src.models.user import User
from src.schemas.auth import SignupRequest, LoginRequest, AuthResponse, UserOut, TokenResponse
from src.config import get_settings

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()
limiter = Limiter(key_func=get_remote_address)

_COOKIE = "crayoli_rt"
_COOKIE_OPTS = dict(httponly=True, secure=False, samesite="lax", max_age=604800)


def _set_refresh_cookie(response: Response, token: str) -> None:
    response.set_cookie(_COOKIE, token, **_COOKIE_OPTS)


@router.post("/signup", response_model=AuthResponse, status_code=201)
@limiter.limit("5/minute")
async def signup(request: Request, body: SignupRequest, response: Response, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email already registered")

    is_founder = body.email.lower() == settings.founder_email.lower()
    user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        display_name=body.display_name,
        founder_access=is_founder,
        tier="founder" if is_founder else "essentials",
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    access_token = create_access_token(user.id, user.email, user.founder_access)
    refresh_token = create_refresh_token(user.id)
    _set_refresh_cookie(response, refresh_token)

    return AuthResponse(user=UserOut.model_validate(user), tokens=TokenResponse(access_token=access_token))


@router.post("/login", response_model=AuthResponse)
@limiter.limit("10/minute")
async def login(request: Request, body: LoginRequest, response: Response, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if not user or not user.password_hash or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is inactive")

    access_token = create_access_token(user.id, user.email, user.founder_access)
    refresh_token = create_refresh_token(user.id)
    _set_refresh_cookie(response, refresh_token)

    return AuthResponse(user=UserOut.model_validate(user), tokens=TokenResponse(access_token=access_token))


@router.post("/refresh", response_model=TokenResponse)
async def refresh(request: Request, response: Response, db: AsyncSession = Depends(get_db)):
    token = request.cookies.get(_COOKIE)
    if not token:
        raise HTTPException(status_code=401, detail="No refresh token")

    payload = decode_token(token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    user_id = payload.get("sub")
    result = await db.execute(select(User).where(User.id == user_id, User.is_active == True))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    # Rotate refresh token
    new_access = create_access_token(user.id, user.email, user.founder_access)
    new_refresh = create_refresh_token(user.id)
    _set_refresh_cookie(response, new_refresh)

    return TokenResponse(access_token=new_access)


@router.post("/logout", status_code=204)
async def logout(response: Response):
    response.delete_cookie(_COOKIE)
