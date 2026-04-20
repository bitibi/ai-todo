"""
Auth router — register, login, logout, refresh, me.

All operations delegate to AuthService which wraps Supabase Auth.
"""
import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, EmailStr

from app.database import Database, get_database
from app.middleware.auth import get_current_user
from app.services.auth_service import AuthService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])

_bearer = HTTPBearer(auto_error=False)


# ------------------------------------------------------------------
# Request / response schemas (auth-specific, kept local)
# ------------------------------------------------------------------


class RegisterRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    email: EmailStr
    password: str
    full_name: str | None = None


class LoginRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    refresh_token: str


# ------------------------------------------------------------------
# Dependency factory
# ------------------------------------------------------------------


def _get_auth_service(db: Database = Depends(get_database)) -> AuthService:
    return AuthService(db.get_client())


# ------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(
    body: RegisterRequest,
    service: AuthService = Depends(_get_auth_service),
) -> dict[str, Any]:
    """
    Create a new user account via Supabase Auth.

    Returns the user object. If the Supabase project has email confirmation
    disabled the response will also include ``access_token`` and
    ``refresh_token``.
    """
    return await service.register(body.email, body.password, body.full_name)


@router.post("/login")
async def login(
    body: LoginRequest,
    service: AuthService = Depends(_get_auth_service),
) -> dict[str, Any]:
    """
    Sign in with email + password.

    Returns ``{access_token, refresh_token, token_type, user}``.
    """
    return await service.login(body.email, body.password)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    service: AuthService = Depends(_get_auth_service),
) -> None:
    """Invalidate the current Bearer token."""
    if credentials:
        await service.logout(credentials.credentials)


@router.post("/refresh")
async def refresh(
    body: RefreshRequest,
    service: AuthService = Depends(_get_auth_service),
) -> dict[str, Any]:
    """Exchange a refresh token for a fresh session."""
    return await service.refresh(body.refresh_token)


@router.get("/me")
async def me(
    current_user: dict[str, Any] = Depends(get_current_user),
) -> dict[str, Any]:
    """Return the currently authenticated user."""
    return current_user
