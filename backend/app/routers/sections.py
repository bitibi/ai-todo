"""
Sections router.

Sections live under /lists/{list_id}/sections for collection operations,
and under /sections/{id} for single-resource operations (update/delete/reorder)
so the frontend doesn't need to supply list_id for every mutation.
"""
import logging
from typing import Any

from fastapi import APIRouter, Depends, status

from app.database import Database, get_database
from app.middleware.auth import get_current_user
from app.models.common import ReorderItem
from app.models.section import SectionCreate, SectionUpdate
from app.services.section_service import SectionService

logger = logging.getLogger(__name__)

# Two separate routers mounted in main.py so prefixes work cleanly
lists_router = APIRouter(prefix="/lists", tags=["sections"])
sections_router = APIRouter(prefix="/sections", tags=["sections"])


# ------------------------------------------------------------------
# Dependency factory
# ------------------------------------------------------------------


def _get_section_service(db: Database = Depends(get_database)) -> SectionService:
    return SectionService(db.get_client())


# ------------------------------------------------------------------
# Collection endpoints (under /lists/{list_id}/sections)
# ------------------------------------------------------------------


@lists_router.get("/{list_id}/sections", summary="Get sections for a list")
async def get_sections(
    list_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: SectionService = Depends(_get_section_service),
) -> list[dict[str, Any]]:
    """Return all sections for a list, ordered by position."""
    return await service.get_sections(list_id, current_user["id"])


@lists_router.post(
    "/{list_id}/sections",
    status_code=status.HTTP_201_CREATED,
    summary="Create a section",
)
async def create_section(
    list_id: str,
    body: SectionCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: SectionService = Depends(_get_section_service),
) -> dict[str, Any]:
    """Create a new section inside the given list."""
    return await service.create_section(list_id, body, current_user["id"])


# ------------------------------------------------------------------
# Single-resource endpoints (under /sections/{id})
# ------------------------------------------------------------------


@sections_router.patch("/reorder", summary="Bulk-reorder sections")
async def reorder_sections(
    items: list[ReorderItem],
    current_user: dict[str, Any] = Depends(get_current_user),
    service: SectionService = Depends(_get_section_service),
) -> list[dict[str, Any]]:
    """
    Update the position field for multiple sections in one request.

    Body: ``[{id, position}, ...]``
    """
    return await service.reorder_sections(
        [item.model_dump() for item in items], current_user["id"]
    )


@sections_router.patch("/{section_id}", summary="Partial-update a section")
async def update_section(
    section_id: str,
    body: SectionUpdate,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: SectionService = Depends(_get_section_service),
) -> dict[str, Any]:
    """Update one or more fields of a section."""
    return await service.update_section(section_id, body, current_user["id"])


@sections_router.delete(
    "/{section_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a section",
)
async def delete_section(
    section_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: SectionService = Depends(_get_section_service),
) -> None:
    """Delete a section. Tasks within it have their section_id set to NULL (cascade SET NULL)."""
    await service.delete_section(section_id, current_user["id"])
