"""
Message service with business logic for CRUD operations.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from typing import List, Optional

from app.models.message import Message
from app.models.room import Room
from app.models.user import User
from app.schemas.message import MessageCreate, MessageUpdate


async def create_message(db: AsyncSession, room_id: int, message_in: MessageCreate, user: User) -> Message:
    """Create a new message in a room."""
    # Check if room exists
    result = await db.execute(select(Room).where(Room.id == room_id))
    room = result.scalar_one_or_none()

    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

    db_message = Message(
        content=message_in.content,
        room_id=room_id,
        user_id=user.id
    )
    db.add(db_message)
    await db.commit()
    await db.refresh(db_message)
    return db_message


async def get_messages_by_room(
    db: AsyncSession,
    room_id: int,
    skip: int = 0,
    limit: int = 50
) -> List[Message]:
    """Get messages for a specific room with pagination."""
    # Check if room exists
    result = await db.execute(select(Room).where(Room.id == room_id))
    room = result.scalar_one_or_none()

    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

    result = await db.execute(
        select(Message)
        .where(Message.room_id == room_id)
        .offset(skip)
        .limit(limit)
        .order_by(Message.created_at.desc())
    )
    return result.scalars().all()


async def get_message_by_id(db: AsyncSession, message_id: int) -> Optional[Message]:
    """Get a message by ID."""
    result = await db.execute(select(Message).where(Message.id == message_id))
    return result.scalar_one_or_none()


async def update_message(db: AsyncSession, message_id: int, message_in: MessageUpdate, user: User) -> Message:
    """Update a message. Only the author can update."""
    message = await get_message_by_id(db, message_id)
    if not message:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Message not found")

    if message.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to update this message")

    message.content = message_in.content

    await db.commit()
    await db.refresh(message)
    return message


async def delete_message(db: AsyncSession, message_id: int, user: User) -> None:
    """Delete a message. Only the author can delete."""
    message = await get_message_by_id(db, message_id)
    if not message:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Message not found")

    if message.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this message")

    await db.delete(message)
    await db.commit()
