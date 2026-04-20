"""Pydantic models for the todo.lists table."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field
from app.models.section import SectionWithTasks
from app.models.task import TaskResponse


class TodoListBase(BaseModel):
    """Fields shared between create and update."""

    name: str = Field(..., min_length=1, max_length=255)
    icon: Optional[str] = "📋"
    icon_bg: Optional[str] = "#f5f5f5"
    is_urgent: Optional[bool] = False
    position: Optional[int] = 0


class TodoListCreate(TodoListBase):
    """Request body for POST /lists."""

    model_config = ConfigDict(from_attributes=True)


class TodoListUpdate(BaseModel):
    """Request body for PATCH /lists/{id} — all fields optional."""

    model_config = ConfigDict(from_attributes=True)

    name: Optional[str] = Field(None, min_length=1, max_length=255)
    icon: Optional[str] = None
    icon_bg: Optional[str] = None
    is_urgent: Optional[bool] = None
    position: Optional[int] = None


class TodoListResponse(BaseModel):
    """Full list row as returned to the client."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    name: str
    icon: Optional[str] = "📋"
    icon_bg: Optional[str] = "#f5f5f5"
    is_urgent: bool = False
    position: int = 0
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class TodoListDetail(TodoListResponse):
    """List with nested sections and tasks (used by GET /lists/{id})."""

    sections: list[SectionWithTasks] = []
    tasks: list[TaskResponse] = []
