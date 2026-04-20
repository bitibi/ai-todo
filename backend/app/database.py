"""Supabase client factory and database dependency."""
import logging
from typing import Optional

from supabase import Client, create_client

from app.config import settings

logger = logging.getLogger(__name__)


class Database:
    """Lazy-initialised Supabase client wrapper."""

    def __init__(self) -> None:
        self._client: Optional[Client] = None

    def get_client(self) -> Client:
        """Return the shared Supabase client, creating it on first call."""
        if self._client is None:
            if not settings.supabase_url or not settings.supabase_service_key:
                raise ValueError(
                    "SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in env"
                )
            self._client = create_client(
                supabase_url=settings.supabase_url,
                supabase_key=settings.supabase_service_key,
            )
            logger.info("Supabase client initialised (service key)")
        return self._client

    async def health_check(self) -> bool:
        """Verify the database connection is reachable."""
        try:
            client = self.get_client()
            # Lightweight probe against the todo schema
            client.schema("todo").table("lists").select("id").limit(1).execute()
            return True
        except Exception as exc:
            logger.error("Database health check failed: %s", exc)
            return False


# Module-level singleton
database = Database()


def get_database() -> Database:
    """FastAPI dependency that returns the shared Database instance."""
    return database
