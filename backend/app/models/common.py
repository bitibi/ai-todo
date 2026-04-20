"""Shared response models used across multiple routers."""
from typing import Any, Optional
from pydantic import BaseModel, ConfigDict


class HealthResponse(BaseModel):
    """Standard health-check response."""

    model_config = ConfigDict(from_attributes=True)

    status: str
    service: str


class MessageResponse(BaseModel):
    """Generic single-message response."""

    model_config = ConfigDict(from_attributes=True)

    message: str


class ErrorResponse(BaseModel):
    """Standard error envelope."""

    model_config = ConfigDict(from_attributes=True)

    detail: str
    code: Optional[str] = None


class ReorderItem(BaseModel):
    """A single {id, position} pair used in bulk-reorder requests."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    position: int
