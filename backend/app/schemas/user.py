"""
User schemas for request/response validation.
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    """Base user schema with common fields."""
    email: EmailStr
    full_name: Optional[str] = None


class UserCreate(UserBase):
    """
    Schema for user registration request.
    Password must be 8-72 characters (bcrypt limit).
    """
    password: str = Field(..., min_length=8, max_length=72, description="Password must be between 8-72 characters")


class UserLogin(BaseModel):
    """Schema for user login request."""
    email: EmailStr
    password: str


class UserResponse(UserBase):
    """Schema for user data in responses (excludes password)."""
    id: int
    is_active: bool
    is_superuser: bool
    created_at: datetime

    class Config:
        from_attributes = True


class User(UserResponse):
    """Full user schema with all fields."""
    pass
