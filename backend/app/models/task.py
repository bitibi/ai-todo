"""Pydantic models for the todo.tasks table."""
from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, ConfigDict, Field

PriorityLevel = Literal["urgent", "high", "medium", "low"]


class TaskBase(BaseModel):
    """Fields shared between create and update."""

    title: str = Field(..., min_length=1, max_length=500)
    priority: Optional[PriorityLevel] = "medium"
    time_estimate: Optional[str] = None
    details: Optional[str] = None
    sub_text: Optional[str] = None
    position: Optional[int] = 0
    due_date: Optional[datetime] = None


class TaskCreate(TaskBase):
    """Request body for POST /tasks."""

    model_config = ConfigDict(from_attributes=True)

    list_id: str
    section_id: Optional[str] = None


class TaskUpdate(BaseModel):
    """Request body for PATCH /tasks/{id} — all fields optional."""

    model_config = ConfigDict(from_attributes=True)

    title: Optional[str] = Field(None, min_length=1, max_length=500)
    list_id: Optional[str] = None
    section_id: Optional[str] = None
    priority: Optional[PriorityLevel] = None
    time_estimate: Optional[str] = None
    details: Optional[str] = None
    sub_text: Optional[str] = None
    position: Optional[int] = None
    is_completed: Optional[bool] = None
    due_date: Optional[datetime] = None


class TaskResponse(BaseModel):
    """Full task row as returned to the client."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    list_id: str
    section_id: Optional[str] = None
    title: str
    priority: PriorityLevel = "medium"
    time_estimate: Optional[str] = None
    details: Optional[str] = None
    sub_text: Optional[str] = None
    position: int = 0
    is_completed: bool = False
    due_date: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
