"""
Token schemas for JWT authentication.
"""
from pydantic import BaseModel
from typing import Optional


class Token(BaseModel):
    """OAuth2 token response schema."""
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Data extracted from JWT token."""
    email: Optional[str] = None
