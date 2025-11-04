"""
Note model for collaborative sticky notes.
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base


class Note(Base):
    """
    Collaborative sticky note model.

    Attributes:
        id: Primary key
        room_id: Room this note belongs to
        user_id: User who created the note
        content: Note text content
        position_x: X coordinate on the board (for UI positioning)
        position_y: Y coordinate on the board (for UI positioning)
        color: Note color (hex code, e.g., "#FFEB3B")
        created_at: Note creation timestamp
        updated_at: Last update timestamp
    """
    __tablename__ = "notes"

    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("rooms.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    content = Column(Text, nullable=False)
    position_x = Column(Float, default=0.0, nullable=False)
    position_y = Column(Float, default=0.0, nullable=False)
    color = Column(String(7), default="#FFEB3B", nullable=False)  # Default yellow
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    room = relationship("Room", back_populates="notes")
    user = relationship("User", back_populates="notes")

    def __repr__(self):
        return f"<Note(id={self.id}, room_id={self.room_id}, user_id={self.user_id})>"
