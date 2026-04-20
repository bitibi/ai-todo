"""
Task service — CRUD + complete/uncomplete + reorder + filtering for todo.tasks.
"""
import logging
from datetime import datetime, timezone
from typing import Any, Optional

from fastapi import HTTPException
from supabase import Client

from app.models.task import TaskCreate, TaskUpdate

logger = logging.getLogger(__name__)

_TABLE = "tasks"
_SCHEMA = "todo"


class TaskService:
    def __init__(self, client: Client) -> None:
        self._db = client.schema(_SCHEMA)

    # ------------------------------------------------------------------
    # Ownership helpers
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

    async def _assert_task_owned(
        self, task_id: str, user_id: str
    ) -> dict[str, Any]:
        """Return task row if owned, else raise 404."""
        try:
            result = (
                self._db.table(_TABLE)
                .select("*, lists!inner(user_id)")
                .eq("id", task_id)
                .execute()
            )
        except Exception as exc:
            raise HTTPException(status_code=404, detail="Task not found") from exc

        rows = result.data or []
        for row in rows:
            list_info = row.get("lists") or {}
            if isinstance(list_info, list):
                list_info = list_info[0] if list_info else {}
            if str(list_info.get("user_id")) == user_id:
                row.pop("lists", None)
                return row
        raise HTTPException(status_code=404, detail="Task not found")

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------

    async def get_tasks(
        self,
        user_id: str,
        list_id: Optional[str] = None,
        section_id: Optional[str] = None,
        priority: Optional[str] = None,
        completed: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        """
        Return tasks owned by user_id with optional filters.
        Ownership is enforced by joining through todo.lists.
        """
        try:
            query = (
                self._db.table(_TABLE)
                .select("*, lists!inner(user_id)")
                .eq("lists.user_id", user_id)
                .order("position")
            )
            if list_id:
                query = query.eq("list_id", list_id)
            if section_id:
                query = query.eq("section_id", section_id)
            if priority:
                query = query.eq("priority", priority)
            if completed is not None:
                query = query.eq("is_completed", completed)
            if search:
                query = query.ilike("title", f"%{search}%")

            result = query.execute()
        except Exception as exc:
            logger.error("get_tasks failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to fetch tasks") from exc

        rows = result.data or []
        # Strip the joined list info
        for row in rows:
            row.pop("lists", None)
        return rows

    async def get_task(self, task_id: str, user_id: str) -> dict[str, Any]:
        return await self._assert_task_owned(task_id, user_id)

    # ------------------------------------------------------------------
    # Create
    # ------------------------------------------------------------------

    async def create_task(
        self, payload: TaskCreate, user_id: str
    ) -> dict[str, Any]:
        await self._assert_list_owned(payload.list_id, user_id)
        data = payload.model_dump(exclude_none=True)
        if "position" not in data or data.get("position") == 0:
            data["position"] = await self._next_position(payload.list_id)
        try:
            result = self._db.table(_TABLE).insert(data).execute()
        except Exception as exc:
            logger.error("create_task failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to create task") from exc

        if not result.data:
            raise HTTPException(status_code=500, detail="Task creation returned no data")
        return result.data[0]

    # ------------------------------------------------------------------
    # Update
    # ------------------------------------------------------------------

    async def update_task(
        self, task_id: str, payload: TaskUpdate, user_id: str
    ) -> dict[str, Any]:
        await self._assert_task_owned(task_id, user_id)

        data = payload.model_dump(exclude_none=True)
        if not data:
            raise HTTPException(status_code=422, detail="No fields provided for update")

        # If moving to a different list, verify ownership of the target list
        if "list_id" in data:
            await self._assert_list_owned(data["list_id"], user_id)

        try:
            result = (
                self._db.table(_TABLE)
                .update(data)
                .eq("id", task_id)
                .execute()
            )
        except Exception as exc:
            logger.error("update_task failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to update task") from exc

        if not result.data:
            raise HTTPException(status_code=404, detail="Task not found")
        return result.data[0]

    # ------------------------------------------------------------------
    # Delete
    # ------------------------------------------------------------------

    async def delete_task(self, task_id: str, user_id: str) -> None:
        await self._assert_task_owned(task_id, user_id)
        try:
            self._db.table(_TABLE).delete().eq("id", task_id).execute()
        except Exception as exc:
            logger.error("delete_task failed: %s", exc)
            raise HTTPException(status_code=500, detail="Failed to delete task") from exc

    # ------------------------------------------------------------------
    # Complete / Uncomplete
    # ------------------------------------------------------------------

    async def complete_task(self, task_id: str, user_id: str) -> dict[str, Any]:
        await self._assert_task_owned(task_id, user_id)
        now = datetime.now(timezone.utc).isoformat()
        try:
            result = (
                self._db.table(_TABLE)
                .update({"is_completed": True, "completed_at": now})
                .eq("id", task_id)
                .execute()
            )
        except Exception as exc:
            raise HTTPException(status_code=500, detail="Failed to complete task") from exc

        if not result.data:
            raise HTTPException(status_code=404, detail="Task not found")
        return result.data[0]

    async def uncomplete_task(self, task_id: str, user_id: str) -> dict[str, Any]:
        await self._assert_task_owned(task_id, user_id)
        try:
            result = (
                self._db.table(_TABLE)
                .update({"is_completed": False, "completed_at": None})
                .eq("id", task_id)
                .execute()
            )
        except Exception as exc:
            raise HTTPException(status_code=500, detail="Failed to uncomplete task") from exc

        if not result.data:
            raise HTTPException(status_code=404, detail="Task not found")
        return result.data[0]

    # ------------------------------------------------------------------
    # Reorder
    # ------------------------------------------------------------------

    async def reorder_tasks(
        self, items: list[dict[str, Any]], user_id: str
    ) -> list[dict[str, Any]]:
        updated: list[dict[str, Any]] = []
        for item in items:
            await self._assert_task_owned(item["id"], user_id)
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
                logger.error("reorder_tasks item %s failed: %s", item.get("id"), exc)
                raise HTTPException(
                    status_code=500, detail="Failed to reorder tasks"
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
