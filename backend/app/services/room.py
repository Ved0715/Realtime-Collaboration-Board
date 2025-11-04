"""
Room service with business logic for CRUD operations.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from typing import List, Optional

from app.models.room import Room
from app.models.user import User
from app.schemas.room import RoomCreate, RoomUpdate


async def create_room(db: AsyncSession, room_in: RoomCreate, user: User) -> Room:
    """Create a new room."""
    db_room = Room(
        name=room_in.name,
        description=room_in.description,
        created_by=user.id
    )
    db.add(db_room)
    await db.commit()
    await db.refresh(db_room)
    return db_room


async def get_rooms(db: AsyncSession, skip: int = 0, limit: int = 100) -> List[Room]:
    """Get all rooms with pagination."""
    result = await db.execute(
        select(Room).offset(skip).limit(limit).order_by(Room.created_at.desc())
    )
    return result.scalars().all()


async def get_room_by_id(db: AsyncSession, room_id: int) -> Optional[Room]:
    """Get a room by ID."""
    result = await db.execute(select(Room).where(Room.id == room_id))
    return result.scalar_one_or_none()


async def update_room(db: AsyncSession, room_id: int, room_in: RoomUpdate, user: User) -> Room:
    """Update a room. Only the creator can update."""
    room = await get_room_by_id(db, room_id)
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

    if room.created_by != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

    if room_in.name is not None:
        room.name = room_in.name
    if room_in.description is not None:
        room.description = room_in.description

    await db.commit()
    await db.refresh(room)
    return room


async def delete_room(db: AsyncSession, room_id: int, user: User) -> None:
    """Delete a room. Only the creator can delete."""
    room = await get_room_by_id(db, room_id)
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

    if room.created_by != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

    await db.delete(room)
    await db.commit()
