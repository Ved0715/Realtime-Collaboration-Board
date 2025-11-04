"""
Room API endpoints with authentication.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.db.session import get_db
from app.schemas.room import RoomCreate, RoomUpdate, RoomResponse
from app.services.room import create_room, get_rooms, get_room_by_id, update_room, delete_room
from app.api.auth import get_current_user
from app.models.user import User


router = APIRouter()


@router.post("/", response_model=RoomResponse, status_code=status.HTTP_201_CREATED)
async def create_new_room(
    room_in: RoomCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new collaboration room.

    Requires authentication.
    """
    try:
        return await create_room(db, room_in, current_user)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create room: {str(e)}"
        )


@router.get("/", response_model=List[RoomResponse])
async def list_rooms(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all rooms with pagination.

    Requires authentication.
    """
    try:
        return await get_rooms(db, skip=skip, limit=limit)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch rooms: {str(e)}"
        )


@router.get("/{room_id}", response_model=RoomResponse)
async def get_room(
    room_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific room by ID.

    Requires authentication.
    """
    try:
        room = await get_room_by_id(db, room_id)
        if not room:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")
        return room
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch room: {str(e)}"
        )


@router.patch("/{room_id}", response_model=RoomResponse)
async def update_existing_room(
    room_id: int,
    room_in: RoomUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update a room. Only the creator can update.

    Requires authentication.
    """
    try:
        return await update_room(db, room_id, room_in, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update room: {str(e)}"
        )


@router.delete("/{room_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_room(
    room_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a room. Only the creator can delete.

    Requires authentication.
    """
    try:
        await delete_room(db, room_id, current_user)
        return None
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete room: {str(e)}"
        )
