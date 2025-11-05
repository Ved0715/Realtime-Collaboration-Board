"""
Notes API endpoints for collaborative sticky notes.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.db.session import get_db
from app.models.user import User
from app.schemas.note import NoteCreate, NoteUpdate, NoteResponse
from app.services.note import (
    create_note,
    get_notes_by_room,
    get_note_by_id,
    update_note,
    delete_note,
)
from app.api.auth import get_current_user

router = APIRouter()


@router.post("/rooms/{room_id}/notes", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_new_note(
    room_id: int,
    note_in: NoteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Create a new sticky note in a room.
    Requires authentication.
    """
    try:
        return await create_note(db, room_id, note_in, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create note: {str(e)}",
        )


@router.get("/rooms/{room_id}/notes", response_model=List[NoteResponse])
async def get_room_notes(
    room_id: int,
    skip: int = Query(0, ge=0, description="Number of notes to skip"),
    limit: int = Query(100, ge=1, le=500, description="Maximum number of notes to return"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get all sticky notes in a room with pagination.
    Returns notes in descending order (newest first).
    Requires authentication.
    """
    try:
        return await get_notes_by_room(db, room_id, skip, limit)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve notes: {str(e)}",
        )


@router.get("/notes/{note_id}", response_model=NoteResponse)
async def get_specific_note(
    note_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get a specific note by ID.
    Requires authentication.
    """
    try:
        note = await get_note_by_id(db, note_id)
        if not note:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Note not found")
        return note
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve note: {str(e)}",
        )


@router.patch("/notes/{note_id}", response_model=NoteResponse)
async def update_existing_note(
    note_id: int,
    note_in: NoteUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update a sticky note.
    Only the author can update their note.
    All fields are optional - only provided fields will be updated.
    Requires authentication.
    """
    try:
        return await update_note(db, note_id, note_in, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update note: {str(e)}",
        )


@router.delete("/notes/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_note(
    note_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Delete a sticky note.
    Only the author can delete their note.
    Requires authentication.
    """
    try:
        await delete_note(db, note_id, current_user)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete note: {str(e)}",
        )
