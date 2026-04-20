"""Pydantic models for the todo.sections table."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class SectionBase(BaseModel):
    """Fields shared between create and update."""

    name: str = Field(..., min_length=1, max_length=255)
    icon: Optional[str] = "📁"
    color: Optional[str] = "purple"
    position: Optional[int] = 0


class SectionCreate(SectionBase):
    """Request body for POST /lists/{list_id}/sections."""

    model_config = ConfigDict(from_attributes=True)


class SectionUpdate(BaseModel):
    """Request body for PATCH /sections/{id} — all fields optional."""

    model_config = ConfigDict(from_attributes=True)

    name: Optional[str] = Field(None, min_length=1, max_length=255)
    icon: Optional[str] = None
    color: Optional[str] = None
    position: Optional[int] = None


class SectionResponse(BaseModel):
    """Full section row as returned to the client."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    list_id: str
    name: str
    icon: Optional[str] = "📁"
    color: Optional[str] = "purple"
    position: int = 0
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class SectionWithTasks(SectionResponse):
    """Section with its nested tasks (used by GET /lists/{id})."""

    tasks: list = []  # list[TaskResponse] — typed at runtime to avoid circular import
