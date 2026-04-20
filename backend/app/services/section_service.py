"""
Section service — CRUD + reorder for todo.sections.

Ownership is verified by joining through todo.lists (user_id check).
"""
import logging
from typing import Any

from fastapi import HTTPException
from supabase import Client

from app.models.section import SectionCreate, SectionUpdate

logger = logging.getLogger(__name__)

_TABLE = "sections"
_SCHEMA = "todo"


class SectionService:
    def __init__(self, client: Client) -> None:
        self._db = client.schema(_SCHEMA)

    # ------------------------------------------------------------------
    # Ownership helper
    # ------------------------------------------------------------------

    async def _assert_list_owned(self, list_id: str, user_id: str) -> None:
        """Raise 404 if the list doesn't exist or isn't owned by user_id."""
        try:
            result = (
                self._db.table("lists")
                .select("id")
                .eq("id", list_id)
                .eq("user_id", user_id)
                .single()
                .execute()
            )
        except Exception as exc:
            raise HTTPException(status_code=404, detail="List not found") from exc
        if not result.data:
            raise HTTPException(status_code=404, detail="List not found")

    async def _assert_section_owned(
        self, section_id: str, user_id: str
    ) -> dict[str, Any]:
        """
        Return the section row if found and owned (via list). Raise 404 otherwise.
        """
        try:
            result = (
                self._db.table(_TABLE)
                .select("*, lists!inner(user_id)")
                .eq("id", section_id)
                .execute()
            )
        except Exception as exc:
            raise HTTPException(status_code=404, detail="Section not found") from exc

        rows = result.data or []
        for row in rows:
            list_info = row.get("lists") or {}
            if isinstance(list_info, list):
                list_info = list_info[0] if list_info else {}
            if str(list_info.get("user_id")) == user_id:
                # Strip the joined list info before returning
                row.pop("lists", None)
                return row
        raise HTTPException(status_code=404, detail="Section not found")

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------

    async def get_sections(
        self, list_id: str, user_id: str
    ) -> list[dict[str, Any]]:
        await self._assert_list_owned(list_id, user_id)
        try:
            result = (
                self._db.table(_TABLE)
                .select("*")
                .eq("list_id", list_id)
                .order("position")
                .execute()
            )
            return result.data or []
        except Exception as exc:
            logger.error("get_sections failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to fetch sections") from exc

    # ------------------------------------------------------------------
    # Create
    # ------------------------------------------------------------------

    async def create_section(
        self, list_id: str, payload: SectionCreate, user_id: str
    ) -> dict[str, Any]:
        await self._assert_list_owned(list_id, user_id)
        data = payload.model_dump(exclude_none=True)
        data["list_id"] = list_id
        if "position" not in data or data["position"] == 0:
            data["position"] = await self._next_position(list_id)
        try:
            result = self._db.table(_TABLE).insert(data).execute()
        except Exception as exc:
            logger.error("create_section failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to create section") from exc

        if not result.data:
            raise HTTPException(status_code=500, detail="Section creation returned no data")
        return result.data[0]

    # ------------------------------------------------------------------
    # Update
    # ------------------------------------------------------------------

    async def update_section(
        self, section_id: str, payload: SectionUpdate, user_id: str
    ) -> dict[str, Any]:
        section = await self._assert_section_owned(section_id, user_id)
        data = payload.model_dump(exclude_none=True)
        if not data:
            raise HTTPException(status_code=422, detail="No fields provided for update")
        try:
            result = (
                self._db.table(_TABLE)
                .update(data)
                .eq("id", section_id)
                .execute()
            )
        except Exception as exc:
            logger.error("update_section failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to update section") from exc

        if not result.data:
            raise HTTPException(status_code=404, detail="Section not found")
        return result.data[0]

    # ------------------------------------------------------------------
    # Delete
    # ------------------------------------------------------------------

    async def delete_section(self, section_id: str, user_id: str) -> None:
        await self._assert_section_owned(section_id, user_id)
        try:
            self._db.table(_TABLE).delete().eq("id", section_id).execute()
        except Exception as exc:
            logger.error("delete_section failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to delete section") from exc

    # ------------------------------------------------------------------
    # Reorder
    # ------------------------------------------------------------------

    async def reorder_sections(
        self, items: list[dict[str, Any]], user_id: str
    ) -> list[dict[str, Any]]:
        """Bulk-update positions. Each section must be owned by user_id."""
        updated: list[dict[str, Any]] = []
        for item in items:
            await self._assert_section_owned(item["id"], user_id)
            try:
                result = (
                    self._db.table(_TABLE)
                    .update({"position": item["position"]})
                    .eq("id", item["id"])
                    .execute()
                )
                if result.data:
                    updated.extend(result.data)
            except Exception as exc:
                logger.error("reorder_sections item %s failed: %s", item.get("id"), exc)
                raise HTTPException(
                    status_code=500, detail="Failed to reorder sections"
                ) from exc
        return updated

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    async def _next_position(self, list_id: str) -> int:
        try:
            result = (
                self._db.table(_TABLE)
                .select("position")
                .eq("list_id", list_id)
                .order("position", desc=True)
                .limit(1)
                .execute()
            )
            if result.data:
                return result.data[0]["position"] + 1
        except Exception:
            pass
        return 0
