"""
Note schemas for request/response validation.
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class NoteBase(BaseModel):
    """Base note schema."""
    content: str = Field(..., min_length=1, max_length=1000)
    position_x: float = Field(default=0.0)
    position_y: float = Field(default=0.0)
    color: str = Field(default="#FFEB3B", pattern="^#[0-9A-Fa-f]{6}$")


class NoteCreate(NoteBase):
    """Schema for creating a note."""
    pass


class NoteUpdate(BaseModel):
    """Schema for updating a note (all fields optional)."""
    content: Optional[str] = Field(None, min_length=1, max_length=1000)
    position_x: Optional[float] = None
    position_y: Optional[float] = None
    color: Optional[str] = Field(None, pattern="^#[0-9A-Fa-f]{6}$")


class NoteResponse(NoteBase):
    """Schema for note in responses."""
    id: int
    room_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
