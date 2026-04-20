"""
Todo API — FastAPI application factory.
"""
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import get_database
from app.models.common import HealthResponse, MessageResponse
from app.routers import ai, auth, lists, tasks
from app.routers.sections import lists_router as sections_lists_router
from app.routers.sections import sections_router
from app.routers.attachments import tasks_router as attachments_tasks_router
from app.routers.attachments import attachments_router

# ------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
)
logger = logging.getLogger("todo-api")

# ------------------------------------------------------------------
# Application
# ------------------------------------------------------------------
app = FastAPI(
    title=settings.app_title,
    description=settings.app_description,
    version=settings.app_version,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ------------------------------------------------------------------
# CORS
# ------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------------
# Routers
# ------------------------------------------------------------------
app.include_router(auth.router)

app.include_router(lists.router)

# Sections — two routers share the same service
app.include_router(sections_lists_router)   # GET/POST /lists/{list_id}/sections
app.include_router(sections_router)         # PATCH/DELETE /sections/{id}, PATCH /sections/reorder

app.include_router(tasks.router)

# Attachments — two routers share the same service
app.include_router(attachments_tasks_router)    # GET/POST /tasks/{task_id}/attachments
app.include_router(attachments_router)          # DELETE /attachments/{id}

app.include_router(ai.router)

# ------------------------------------------------------------------
# Meta endpoints
# ------------------------------------------------------------------


@app.get("/", response_model=MessageResponse, tags=["meta"])
async def root() -> MessageResponse:
    """API root — confirms the service is running."""
    logger.info("Root endpoint accessed")
    return MessageResponse(message="Todo API is running")


@app.get("/health", response_model=HealthResponse, tags=["meta"])
async def health_check() -> HealthResponse:
    """
    Health check — probes the Supabase database connection.

    Returns ``{"status": "healthy"}`` or ``{"status": "unhealthy"}``.
    """
    logger.info("Health check accessed")
    db = get_database()
    is_healthy = await db.health_check()
    return HealthResponse(
        status="healthy" if is_healthy else "unhealthy",
        service="todo-api",
    )
