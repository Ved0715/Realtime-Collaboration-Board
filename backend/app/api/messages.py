"""
Messages API endpoints for chat functionality.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.db.session import get_db
from app.models.user import User
from app.schemas.message import MessageCreate, MessageUpdate, MessageResponse
from app.services.message import (
    create_message,
    get_messages_by_room,
    get_message_by_id,
    update_message,
    delete_message,
)
from app.api.auth import get_current_user

router = APIRouter()


@router.post("/rooms/{room_id}/messages", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_new_message(
    room_id: int,
    message_in: MessageCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Create a new message in a room.
    Requires authentication.
    """
    try:
        return await create_message(db, room_id, message_in, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create message: {str(e)}",
        )


@router.get("/rooms/{room_id}/messages", response_model=List[MessageResponse])
async def get_room_messages(
    room_id: int,
    skip: int = Query(0, ge=0, description="Number of messages to skip"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of messages to return"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get all messages in a room with pagination.
    Returns messages in descending order (newest first).
    Requires authentication.
    """
    try:
        return await get_messages_by_room(db, room_id, skip, limit)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve messages: {str(e)}",
        )


@router.get("/messages/{message_id}", response_model=MessageResponse)
async def get_specific_message(
    message_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get a specific message by ID.
    Requires authentication.
    """
    try:
        message = await get_message_by_id(db, message_id)
        if not message:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Message not found")
        return message
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve message: {str(e)}",
        )


@router.patch("/messages/{message_id}", response_model=MessageResponse)
async def update_existing_message(
    message_id: int,
    message_in: MessageUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update a message.
    Only the author can update their message.
    Requires authentication.
    """
    try:
        return await update_message(db, message_id, message_in, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update message: {str(e)}",
        )


@router.delete("/messages/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_message(
    message_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Delete a message.
    Only the author can delete their message.
    Requires authentication.
    """
    try:
        await delete_message(db, message_id, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete message: {str(e)}",
        )
