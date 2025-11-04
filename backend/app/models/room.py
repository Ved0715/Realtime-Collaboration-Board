"""
Room model for collaboration workspaces.
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base


class Room(Base):
    """
    Collaboration room (workspace/channel) model.

    Attributes:
        id: Primary key
        name: Room name/title
        description: Optional room description
        created_by: User ID who created the room
        created_at: Room creation timestamp
    """
    __tablename__ = "rooms"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    creator = relationship("User", back_populates="created_rooms")
    messages = relationship("Message", back_populates="room", cascade="all, delete-orphan")
    notes = relationship("Note", back_populates="room", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Room(id={self.id}, name='{self.name}')>"
