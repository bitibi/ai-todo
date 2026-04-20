"""
Tasks router — CRUD + complete/uncomplete + reorder + filtering.
All routes require authentication.
"""
import logging
from typing import Any, Optional

from fastapi import APIRouter, Depends, Query, status

from app.database import Database, get_database
from app.middleware.auth import get_current_user
from app.models.common import ReorderItem
from app.models.task import TaskCreate, TaskUpdate
from app.services.task_service import TaskService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/tasks", tags=["tasks"])


# ------------------------------------------------------------------
# Dependency factory
# ------------------------------------------------------------------


def _get_task_service(db: Database = Depends(get_database)) -> TaskService:
    return TaskService(db.get_client())


# ------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------


@router.get("", summary="List tasks with optional filters")
async def get_tasks(
    list_id: Optional[str] = Query(None, description="Filter by list"),
    section_id: Optional[str] = Query(None, description="Filter by section"),
    priority: Optional[str] = Query(None, description="urgent | high | medium | low"),
    completed: Optional[bool] = Query(None, description="Filter by completion state"),
    search: Optional[str] = Query(None, description="Fuzzy search on title"),
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> list[dict[str, Any]]:
    """
    Return tasks for the authenticated user.

    Supports optional query-string filters: ``list_id``, ``section_id``,
    ``priority``, ``completed``, ``search``.
    """
    return await service.get_tasks(
        user_id=current_user["id"],
        list_id=list_id,
        section_id=section_id,
        priority=priority,
        completed=completed,
        search=search,
    )


@router.post("", status_code=status.HTTP_201_CREATED, summary="Create a task")
async def create_task(
    body: TaskCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> dict[str, Any]:
    """Create a new task. ``list_id`` is required; ``section_id`` is optional."""
    return await service.create_task(body, current_user["id"])


@router.patch("/reorder", summary="Bulk-reorder tasks")
async def reorder_tasks(
    items: list[ReorderItem],
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> list[dict[str, Any]]:
    """
    Update the position field for multiple tasks in one request.

    Body: ``[{id, position}, ...]``
    """
    return await service.reorder_tasks(
        [item.model_dump() for item in items], current_user["id"]
    )


@router.get("/{task_id}", summary="Get a single task")
async def get_task(
    task_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> dict[str, Any]:
    """Return a single task by ID."""
    return await service.get_task(task_id, current_user["id"])


@router.patch("/{task_id}", summary="Partial-update a task")
async def update_task(
    task_id: str,
    body: TaskUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> dict[str, Any]:
    """Update one or more fields of a task."""
    return await service.update_task(task_id, body, current_user["id"])


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete a task")
async def delete_task(
    task_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> None:
    """Permanently delete a task and its attachments (cascade)."""
    await service.delete_task(task_id, current_user["id"])


@router.post("/{task_id}/complete", summary="Mark task as complete")
async def complete_task(
    task_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> dict[str, Any]:
    """Set ``is_completed = true`` and record ``completed_at`` timestamp."""
    return await service.complete_task(task_id, current_user["id"])


@router.post("/{task_id}/uncomplete", summary="Mark task as incomplete")
async def uncomplete_task(
    task_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: TaskService = Depends(_get_task_service),
) -> dict[str, Any]:
    """Clear ``is_completed`` and ``completed_at``."""
    return await service.uncomplete_task(task_id, current_user["id"])
