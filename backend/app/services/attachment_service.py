"""
Attachment service — upload/delete files in Supabase Storage + DB records.

Storage bucket: "todo-attachments"
Storage path pattern: {user_id}/{task_id}/{file_name}
"""
import logging
import mimetypes
from typing import Any

from fastapi import HTTPException, UploadFile
from supabase import Client

from app.config import settings

logger = logging.getLogger(__name__)

_TABLE = "attachments"
_SCHEMA = "todo"


class AttachmentService:
    def __init__(self, client: Client) -> None:
        self._client = client
        self._db = client.schema(_SCHEMA)
        self._bucket = settings.attachments_bucket

    # ------------------------------------------------------------------
    # Ownership helper
    # ------------------------------------------------------------------

    async def _assert_task_owned(self, task_id: str, user_id: str) -> dict[str, Any]:
        """Return task row if owned by user_id, else raise 404."""
        try:
            result = (
                self._db.table("tasks")
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

    async def _assert_attachment_owned(
        self, attachment_id: str, user_id: str
    ) -> dict[str, Any]:
        """Return attachment row if the owning task belongs to user_id."""
        try:
            result = (
                self._db.table(_TABLE)
                .select("*, tasks!inner(list_id, lists!inner(user_id))")
                .eq("id", attachment_id)
                .execute()
            )
        except Exception as exc:
            raise HTTPException(status_code=404, detail="Attachment not found") from exc

        rows = result.data or []
        for row in rows:
            task_info = row.get("tasks") or {}
            if isinstance(task_info, list):
                task_info = task_info[0] if task_info else {}
            list_info = task_info.get("lists") or {}
            if isinstance(list_info, list):
                list_info = list_info[0] if list_info else {}
            if str(list_info.get("user_id")) == user_id:
                row.pop("tasks", None)
                return row
        raise HTTPException(status_code=404, detail="Attachment not found")

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------

    async def get_attachments(
        self, task_id: str, user_id: str
    ) -> list[dict[str, Any]]:
        await self._assert_task_owned(task_id, user_id)
        try:
            result = (
                self._db.table(_TABLE)
                .select("*")
                .eq("task_id", task_id)
                .order("created_at")
                .execute()
            )
            return result.data or []
        except Exception as exc:
            logger.error("get_attachments failed: %s", exc)
            raise HTTPException(
                status_code=500, detail="Failed to fetch attachments"
            ) from exc

    # ------------------------------------------------------------------
    # Upload
    # ------------------------------------------------------------------

    async def upload_attachment(
        self, task_id: str, file: UploadFile, user_id: str
    ) -> dict[str, Any]:
        await self._assert_task_owned(task_id, user_id)

        file_bytes = await file.read()
        file_size = len(file_bytes)
        file_name = file.filename or "upload"
        mime_type = file.content_type or (
            mimetypes.guess_type(file_name)[0] or "application/octet-stream"
        )
        storage_path = f"{user_id}/{task_id}/{file_name}"

        # Upload to Supabase Storage
        try:
            self._client.storage.from_(self._bucket).upload(
                path=storage_path,
                file=file_bytes,
                file_options={"content-type": mime_type, "upsert": "true"},
            )
        except Exception as exc:
            logger.error("Storage upload failed: %s", exc)
            raise HTTPException(
                status_code=500, detail=f"File upload failed: {exc}"
            ) from exc

        # Build public URL (works if bucket is set to public; otherwise None)
        try:
            url_response = self._client.storage.from_(self._bucket).get_public_url(
                storage_path
            )
            storage_url: str | None = url_response
        except Exception:
            storage_url = None

        # Persist record in DB
        record = {
            "task_id": task_id,
            "file_name": file_name,
            "file_size": file_size,
            "mime_type": mime_type,
            "storage_path": storage_path,
            "storage_url": storage_url,
        }
        try:
            result = self._db.table(_TABLE).insert(record).execute()
        except Exception as exc:
            logger.error("Attachment DB insert failed: %s", exc)
            raise HTTPException(
                status_code=500, detail="Failed to save attachment record"
            ) from exc

        if not result.data:
            raise HTTPException(
                status_code=500, detail="Attachment record creation returned no data"
            )
        return result.data[0]

    # ------------------------------------------------------------------
    # Delete
    # ------------------------------------------------------------------

    async def delete_attachment(self, attachment_id: str, user_id: str) -> None:
        attachment = await self._assert_attachment_owned(attachment_id, user_id)
        storage_path: str = attachment["storage_path"]

        # Remove from storage (best-effort; DB record still deleted)
        try:
            self._client.storage.from_(self._bucket).remove([storage_path])
        except Exception as exc:
            logger.warning("Storage delete failed (non-fatal): %s", exc)

        # Remove DB record
        try:
            self._db.table(_TABLE).delete().eq("id", attachment_id).execute()
        except Exception as exc:
            logger.error("Attachment DB delete failed: %s", exc)
            raise HTTPException(
                status_code=500, detail="Failed to delete attachment record"
            ) from exc
