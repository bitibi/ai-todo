"""
List service — CRUD + reorder for todo.lists.

All DB calls use the service-key client operating against the "todo" schema.
Ownership is enforced by filtering on user_id (not relying solely on RLS)
so there is no ambiguity when the service key bypasses row-level policies.
"""
import logging
from typing import Any

from fastapi import HTTPException, status
from supabase import Client

from app.models.list import TodoListCreate, TodoListUpdate

logger = logging.getLogger(__name__)

_TABLE = "lists"
_SCHEMA = "todo"


class ListService:
    def __init__(self, client: Client) -> None:
        self._db = client.schema(_SCHEMA)

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------

    async def get_lists(self, user_id: str) -> list[dict[str, Any]]:
        """Return all lists owned by user_id, ordered by position."""
        try:
            result = (
                self._db.table(_TABLE)
                .select("*")
                .eq("user_id", user_id)
                .order("position")
                .execute()
            )
            return result.data or []
        except Exception as exc:
            logger.error("get_lists failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to fetch lists") from exc

    async def get_list(self, list_id: str, user_id: str) -> dict[str, Any]:
        """Return a single list owned by user_id, or 404."""
        try:
            result = (
                self._db.table(_TABLE)
                .select("*")
                .eq("id", list_id)
                .eq("user_id", user_id)
                .single()
                .execute()
            )
        except Exception as exc:
            logger.error("get_list failed: %s", exc)
            raise HTTPException(status_code=404, detail="List not found") from exc

        if not result.data:
            raise HTTPException(status_code=404, detail="List not found")
        return result.data

    async def get_list_detail(self, list_id: str, user_id: str) -> dict[str, Any]:
        """
        Return a list with its sections (ordered by position) and tasks
        (ordered by position, grouped under their section).
        """
        lst = await self.get_list(list_id, user_id)

        # Fetch sections for this list
        try:
            sections_result = (
                self._db.table("sections")
                .select("*")
                .eq("list_id", list_id)
                .order("position")
                .execute()
            )
            sections: list[dict[str, Any]] = sections_result.data or []
        except Exception as exc:
            logger.error("get_list_detail sections failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to fetch sections") from exc

        # Fetch all tasks for this list
        try:
            tasks_result = (
                self._db.table("tasks")
                .select("*")
                .eq("list_id", list_id)
                .order("position")
                .execute()
            )
            all_tasks: list[dict[str, Any]] = tasks_result.data or []
        except Exception as exc:
            logger.error("get_list_detail tasks failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to fetch tasks") from exc

        # Group tasks by section_id
        tasks_by_section: dict[str | None, list[dict[str, Any]]] = {}
        for task in all_tasks:
            key = task.get("section_id")
            tasks_by_section.setdefault(key, []).append(task)

        # Attach tasks to their section
        for section in sections:
            section["tasks"] = tasks_by_section.get(section["id"], [])

        lst["sections"] = sections
        lst["tasks"] = all_tasks
        return lst

    # ------------------------------------------------------------------
    # Create
    # ------------------------------------------------------------------

    async def create_list(
        self, payload: TodoListCreate, user_id: str
    ) -> dict[str, Any]:
        data = payload.model_dump(exclude_none=True)
        data["user_id"] = user_id
        # Auto-assign position to end of list if not supplied
        if "position" not in data or data["position"] == 0:
            data["position"] = await self._next_position(user_id)
        try:
            result = self._db.table(_TABLE).insert(data).execute()
        except Exception as exc:
            logger.error("create_list failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to create list") from exc

        if not result.data:
            raise HTTPException(status_code=500, detail="List creation returned no data")
        return result.data[0]

    # ------------------------------------------------------------------
    # Update
    # ------------------------------------------------------------------

    async def update_list(
        self, list_id: str, payload: TodoListUpdate, user_id: str
    ) -> dict[str, Any]:
        # Verify ownership first
        await self.get_list(list_id, user_id)

        data = payload.model_dump(exclude_none=True)
        if not data:
            raise HTTPException(status_code=422, detail="No fields provided for update")
        try:
            result = (
                self._db.table(_TABLE)
                .update(data)
                .eq("id", list_id)
                .eq("user_id", user_id)
                .execute()
            )
        except Exception as exc:
            logger.error("update_list failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to update list") from exc

        if not result.data:
            raise HTTPException(status_code=404, detail="List not found")
        return result.data[0]

    # ------------------------------------------------------------------
    # Delete
    # ------------------------------------------------------------------

    async def delete_list(self, list_id: str, user_id: str) -> None:
        await self.get_list(list_id, user_id)  # raises 404 if not found/owned
        try:
            self._db.table(_TABLE).delete().eq("id", list_id).eq("user_id", user_id).execute()
        except Exception as exc:
            logger.error("delete_list failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to delete list") from exc

    # ------------------------------------------------------------------
    # Reorder
    # ------------------------------------------------------------------

    async def reorder_lists(
        self, items: list[dict[str, Any]], user_id: str
    ) -> list[dict[str, Any]]:
        """
        Bulk-update positions for the given list of {id, position} dicts.
        Each list must belong to user_id.
        """
        updated: list[dict[str, Any]] = []
        for item in items:
            try:
                result = (
                    self._db.table(_TABLE)
                    .update({"position": item["position"]})
                    .eq("id", item["id"])
                    .eq("user_id", user_id)
                    .execute()
                )
                if result.data:
                    updated.extend(result.data)
            except Exception as exc:
                logger.error("reorder_lists item %s failed: %s", item.get("id"), exc)
                raise HTTPException(
                    status_code=500, detail="Failed to reorder lists"
                ) from exc
        return updated

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    async def _next_position(self, user_id: str) -> int:
        """Return position = (current max position + 1) for user."""
        try:
            result = (
                self._db.table(_TABLE)
                .select("position")
                .eq("user_id", user_id)
                .order("position", desc=True)
                .limit(1)
                .execute()
            )
            if result.data:
                return result.data[0]["position"] + 1
        except Exception:
            pass
        return 0
