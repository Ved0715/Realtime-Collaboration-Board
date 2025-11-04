"""
Room schemas for request/response validation.
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class RoomBase(BaseModel):
    """Base room schema."""
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)


class RoomCreate(RoomBase):
    """Schema for creating a room."""
    pass


class RoomUpdate(BaseModel):
    """Schema for updating a room (all fields optional)."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)


class RoomResponse(RoomBase):
    """Schema for room in responses."""
    id: int
    created_by: int
    created_at: datetime

    class Config:
        from_attributes = True
