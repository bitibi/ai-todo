"""
Auth service — thin wrapper around Supabase Auth operations.

All methods raise HTTPException on failure so routers stay simple.
"""
import logging
from typing import Any

from fastapi import HTTPException, status
from supabase import Client

logger = logging.getLogger(__name__)


class AuthService:
    """Wraps Supabase Auth for register / login / logout / refresh / me."""

    def __init__(self, client: Client) -> None:
        self._client = client

    # ------------------------------------------------------------------
    # Register
    # ------------------------------------------------------------------

    async def register(
        self,
        email: str,
        password: str,
        full_name: str | None = None,
    ) -> dict[str, Any]:
        """
        Create a new Supabase Auth user.

        Returns the auth response serialised as a plain dict containing
        ``user`` and (if email confirmation is disabled) ``session`` keys.
        """
        try:
            options: dict[str, Any] = {}
            if full_name:
                options["data"] = {"full_name": full_name}

            response = self._client.auth.sign_up(
                {"email": email, "password": password, "options": options}
                if options
                else {"email": email, "password": password}
            )
        except Exception as exc:
            logger.error("Register failed for %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(exc),
            ) from exc

        if response.user is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Registration failed — no user returned",
            )

        return _serialise_auth_response(response)

    # ------------------------------------------------------------------
    # Login
    # ------------------------------------------------------------------

    async def login(self, email: str, password: str) -> dict[str, Any]:
        """
        Sign in with email + password.

        Returns ``{access_token, refresh_token, token_type, user}``.
        """
        try:
            response = self._client.auth.sign_in_with_password(
                {"email": email, "password": password}
            )
        except Exception as exc:
            logger.warning("Login failed for %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            ) from exc

        if response.session is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Login failed — no session returned",
            )

        session = response.session
        return {
            "access_token": session.access_token,
            "refresh_token": session.refresh_token,
            "token_type": "bearer",
            "user": _serialise_user(response.user),
        }

    # ------------------------------------------------------------------
    # Logout
    # ------------------------------------------------------------------

    async def logout(self, access_token: str) -> None:
        """Invalidate the supplied access token on the Supabase side."""
        try:
            # Set the session so sign_out targets the right token
            self._client.auth.set_session(access_token, "")
            self._client.auth.sign_out()
        except Exception as exc:
            # Best-effort — log but don't surface an error to the client
            logger.warning("Logout error (non-fatal): %s", exc)

    # ------------------------------------------------------------------
    # Refresh
    # ------------------------------------------------------------------

    async def refresh(self, refresh_token: str) -> dict[str, Any]:
        """Exchange a refresh token for a new session."""
        try:
            response = self._client.auth.refresh_session(refresh_token)
        except Exception as exc:
            logger.warning("Token refresh failed: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token",
            ) from exc

        if response.session is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh failed — no session returned",
            )

        session = response.session
        return {
            "access_token": session.access_token,
            "refresh_token": session.refresh_token,
            "token_type": "bearer",
            "user": _serialise_user(response.user),
        }


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------


def _serialise_user(user: Any) -> dict[str, Any] | None:
    if user is None:
        return None
    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": (user.user_metadata or {}).get("full_name"),
        "created_at": str(user.created_at) if user.created_at else None,
    }


def _serialise_auth_response(response: Any) -> dict[str, Any]:
    result: dict[str, Any] = {"user": _serialise_user(response.user)}
    if response.session:
        result["access_token"] = response.session.access_token
        result["refresh_token"] = response.session.refresh_token
        result["token_type"] = "bearer"
    return result


def get_auth_service(client: Any) -> AuthService:
    """Factory used by router dependencies."""
    return AuthService(client)
