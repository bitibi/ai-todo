"""
Authentication dependency.

Extracts the Bearer token from the Authorization header, verifies it
against Supabase Auth (supabase.auth.get_user(token)), and returns the
authenticated user's data as a plain dict so routers stay decoupled from
any Supabase SDK types.
"""
import logging
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.database import Database, get_database

logger = logging.getLogger(__name__)

# Reusable bearer-token extractor
_bearer = HTTPBearer(auto_error=True)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    db: Database = Depends(get_database),
) -> dict[str, Any]:
    """
    FastAPI dependency that validates the Supabase JWT and returns the
    authenticated user as a dict with at least ``id`` and ``email`` keys.

    Raises HTTP 401 if the token is missing, expired, or invalid.
    """
    token = credentials.credentials
    try:
        client = db.get_client()
        response = client.auth.get_user(token)
        if response is None or response.user is None:
            raise ValueError("Supabase returned no user for the supplied token")
        user = response.user
    except Exception as exc:
        logger.warning("Token validation failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    return {
        "id": str(user.id),
        "email": user.email,
        "user_metadata": user.user_metadata or {},
    }
