"""
Entry point for the Todo API server.
Loads env.dev automatically for local development.
"""
import os
from dotenv import load_dotenv

# Load environment variables before importing app modules
load_dotenv("env.dev")

import uvicorn
from app.config import settings

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info",
    )
