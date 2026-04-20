"""Application configuration loaded from environment variables."""
import os
from dotenv import load_dotenv


class Settings:
    """Application settings sourced from environment variables."""

    def __init__(self) -> None:
        # Load env file for local development. ENV_FILE can override the default.
        env_file = os.getenv("ENV_FILE", "env.dev")
        load_dotenv(env_file)

        # App metadata
        self.app_title: str = "Todo API"
        self.app_description: str = "AI-managed todo list backend"
        self.app_version: str = "1.0.0"

        # Server
        self.host: str = os.getenv("HOST", "127.0.0.1")
        self.port: int = int(os.getenv("PORT", "8001"))
        self.debug: bool = os.getenv("DEBUG", "False").lower() == "true"
        self.environment: str = os.getenv("ENVIRONMENT", "development")

        # CORS — supports comma-separated list
        cors_raw: str = os.getenv("CORS_ORIGINS", "http://localhost:4200")
        self.cors_origins: list[str] = [o.strip() for o in cors_raw.split(",")]

        # Supabase
        self.supabase_url: str = os.getenv("SUPABASE_URL", "")
        self.supabase_anon_key: str = os.getenv("SUPABASE_ANON_KEY", "")
        self.supabase_service_key: str = os.getenv("SUPABASE_SERVICE_KEY", "")

        # Storage bucket name for file attachments
        self.attachments_bucket: str = os.getenv(
            "ATTACHMENTS_BUCKET", "todo-attachments"
        )

        # OpenAI
        self.openai_api_key: str = os.getenv("OPENAI_API_KEY", "")


# Module-level singleton consumed by every other module
settings = Settings()
