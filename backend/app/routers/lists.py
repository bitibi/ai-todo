"""
Lists router — CRUD + reorder for todo.lists.
All routes require authentication.
"""
import logging
from typing import Any

from fastapi import APIRouter, Depends, status

from app.database import Database, get_database
from app.middleware.auth import get_current_user
from app.models.common import ReorderItem
from app.models.list import TodoListCreate, TodoListUpdate
from app.services.list_service import ListService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/lists", tags=["lists"])


# ------------------------------------------------------------------
# Dependency factory
# ------------------------------------------------------------------


def _get_list_service(db: Database = Depends(get_database)) -> ListService:
    return ListService(db.get_client())


# ------------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------------


@router.get("", summary="Get all lists for current user")
async def get_lists(
    current_user: dict[str, Any] = Depends(get_current_user),
    service: ListService = Depends(_get_list_service),
) -> list[dict[str, Any]]:
    """Return all lists owned by the authenticated user, ordered by position."""
    return await service.get_lists(current_user["id"])


@router.post("", status_code=status.HTTP_201_CREATED, summary="Create a list")
async def create_list(
    body: TodoListCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: ListService = Depends(_get_list_service),
) -> dict[str, Any]:
    """Create a new list (category) for the authenticated user."""
    return await service.create_list(body, current_user["id"])


@router.patch("/reorder", summary="Bulk-reorder lists")
async def reorder_lists(
    items: list[ReorderItem],
    current_user: dict[str, Any] = Depends(get_current_user),
    service: ListService = Depends(_get_list_service),
) -> list[dict[str, Any]]:
    """
    Update the position field for multiple lists in one request.

    Body: ``[{id, position}, ...]``
    """
    return await service.reorder_lists(
        [item.model_dump() for item in items], current_user["id"]
    )


@router.get("/{list_id}", summary="Get list detail (with sections + tasks)")
async def get_list(
    list_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: ListService = Depends(_get_list_service),
) -> dict[str, Any]:
    """Return a single list with all its sections and tasks nested."""
    return await service.get_list_detail(list_id, current_user["id"])


@router.patch("/{list_id}", summary="Partial-update a list")
async def update_list(
    list_id: str,
    body: TodoListUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: ListService = Depends(_get_list_service),
) -> dict[str, Any]:
    """Update one or more fields of a list."""
    return await service.update_list(list_id, body, current_user["id"])


@router.delete("/{list_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete a list")
async def delete_list(
    list_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: ListService = Depends(_get_list_service),
) -> None:
    """Permanently delete a list and all its sections/tasks (cascade)."""
    await service.delete_list(list_id, current_user["id"])
