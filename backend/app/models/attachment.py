"""Pydantic models for the todo.attachments table."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class AttachmentResponse(BaseModel):
    """Full attachment row as returned to the client."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    task_id: str
    file_name: str
    file_size: Optional[int] = None
    mime_type: Optional[str] = None
    storage_path: str
    storage_url: Optional[str] = None
    created_at: Optional[datetime] = None
