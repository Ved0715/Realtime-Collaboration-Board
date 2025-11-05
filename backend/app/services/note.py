"""
Note service with business logic for CRUD operations.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from typing import List, Optional

from app.models.note import Note
from app.models.room import Room
from app.models.user import User
from app.schemas.note import NoteCreate, NoteUpdate


async def create_note(db: AsyncSession, room_id: int, note_in: NoteCreate, user: User) -> Note:
    """Create a new note in a room."""
    # Check if room exists
    result = await db.execute(select(Room).where(Room.id == room_id))
    room = result.scalar_one_or_none()

    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

    db_note = Note(
        content=note_in.content,
        position_x=note_in.position_x,
        position_y=note_in.position_y,
        color=note_in.color,
        room_id=room_id,
        user_id=user.id
    )
    db.add(db_note)
    await db.commit()
    await db.refresh(db_note)
    return db_note


async def get_notes_by_room(
    db: AsyncSession,
    room_id: int,
    skip: int = 0,
    limit: int = 100
) -> List[Note]:
    """Get all notes for a specific room with pagination."""
    # Check if room exists
    result = await db.execute(select(Room).where(Room.id == room_id))
    room = result.scalar_one_or_none()

    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

    result = await db.execute(
        select(Note)
        .where(Note.room_id == room_id)
        .offset(skip)
        .limit(limit)
        .order_by(Note.created_at.desc())
    )
    return result.scalars().all()


async def get_note_by_id(db: AsyncSession, note_id: int) -> Optional[Note]:
    """Get a note by ID."""
    result = await db.execute(select(Note).where(Note.id == note_id))
    return result.scalar_one_or_none()


async def update_note(db: AsyncSession, note_id: int, note_in: NoteUpdate, user: User) -> Note:
    """Update a note. Only the author can update."""
    note = await get_note_by_id(db, note_id)
    if not note:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Note not found")

    if note.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to update this note")

    # Update only provided fields
    if note_in.content is not None:
        note.content = note_in.content
    if note_in.position_x is not None:
        note.position_x = note_in.position_x
    if note_in.position_y is not None:
        note.position_y = note_in.position_y
    if note_in.color is not None:
        note.color = note_in.color

    await db.commit()
    await db.refresh(note)
    return note


async def delete_note(db: AsyncSession, note_id: int, user: User) -> None:
    """Delete a note. Only the author can delete."""
    note = await get_note_by_id(db, note_id)
    if not note:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Note not found")

    if note.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this note")

    await db.delete(note)
    await db.commit()
