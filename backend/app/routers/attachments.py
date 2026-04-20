"""
Attachments router.

Upload and list endpoints live under /tasks/{task_id}/attachments.
Delete lives under /attachments/{id}.
"""
import logging
from typing import Any

from fastapi import APIRouter, Depends, File, UploadFile, status

from app.database import Database, get_database
from app.middleware.auth import get_current_user
from app.services.attachment_service import AttachmentService

logger = logging.getLogger(__name__)

# Two separate routers so prefixes are clean
tasks_router = APIRouter(prefix="/tasks", tags=["attachments"])
attachments_router = APIRouter(prefix="/attachments", tags=["attachments"])


# ------------------------------------------------------------------
# Dependency factory
# ------------------------------------------------------------------


def _get_attachment_service(
    db: Database = Depends(get_database),
) -> AttachmentService:
    return AttachmentService(db.get_client())


# ------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------


@tasks_router.get("/{task_id}/attachments", summary="List attachments for a task")
async def get_attachments(
    task_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: AttachmentService = Depends(_get_attachment_service),
) -> list[dict[str, Any]]:
    """Return all attachments for a task, ordered by upload time."""
    return await service.get_attachments(task_id, current_user["id"])


@tasks_router.post(
    "/{task_id}/attachments",
    status_code=status.HTTP_201_CREATED,
    summary="Upload a file attachment",
)
async def upload_attachment(
    task_id: str,
    file: UploadFile = File(...),
    current_user: dict[str, Any] = Depends(get_current_user),
    service: AttachmentService = Depends(_get_attachment_service),
) -> dict[str, Any]:
    """
    Upload a file to Supabase Storage and create an attachment record.

    The file is stored at ``{user_id}/{task_id}/{filename}`` inside the
    ``todo-attachments`` bucket.
    """
    return await service.upload_attachment(task_id, file, current_user["id"])


@attachments_router.delete(
    "/{attachment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete an attachment",
)
async def delete_attachment(
    attachment_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: AttachmentService = Depends(_get_attachment_service),
) -> None:
    """Delete an attachment from storage and from the database."""
    await service.delete_attachment(attachment_id, current_user["id"])
