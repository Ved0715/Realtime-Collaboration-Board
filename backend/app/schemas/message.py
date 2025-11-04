"""
Message schemas for request/response validation.
"""
from pydantic import BaseModel, Field
from datetime import datetime


class MessageBase(BaseModel):
    """Base message schema."""
    content: str = Field(..., min_length=1, max_length=5000)


class MessageCreate(MessageBase):
    """Schema for creating a message."""
    pass


class MessageUpdate(BaseModel):
    """Schema for updating a message."""
    content: str = Field(..., min_length=1, max_length=5000)


class MessageResponse(MessageBase):
    """Schema for message in responses."""
    id: int
    room_id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
