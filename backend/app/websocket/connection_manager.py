"""
WebSocket Connection Manager
Manages WebSocket connections per room with proper isolation.
"""
from typing import Dict, List
from fastapi import WebSocket
from collections import defaultdict
import logging

logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages WebSocket connections with room-based isolation.
    Each room has its own set of active connections.
    """

    def __init__(self):
        # Room ID -> List of WebSocket connections
        self.active_connections: Dict[int, List[WebSocket]] = defaultdict(list)
        # WebSocket -> User ID mapping
        self.connection_users: Dict[WebSocket, int] = {}
        # Track total connection count
        self.total_connections: int = 0

    async def connect(self, websocket: WebSocket, room_id: int, user_id: int):
        """
        Accept and register a new WebSocket connection for a room.

        Args:
            websocket: The WebSocket connection
            room_id: The room the user is joining
            user_id: The authenticated user's ID
        """
        await websocket.accept()
        self.active_connections[room_id].append(websocket)
        self.connection_users[websocket] = user_id
        self.total_connections += 1

        logger.info(
            f"User {user_id} connected to room {room_id}. "
            f"Room has {len(self.active_connections[room_id])} connections. "
            f"Total connections: {self.total_connections}"
        )

    def disconnect(self, websocket: WebSocket, room_id: int):
        """
        Remove a WebSocket connection from a room.

        Args:
            websocket: The WebSocket connection to remove
            room_id: The room the connection was in
        """
        if websocket in self.active_connections[room_id]:
            self.active_connections[room_id].remove(websocket)
            user_id = self.connection_users.pop(websocket, None)
            self.total_connections -= 1

            # Clean up empty room lists
            if not self.active_connections[room_id]:
                del self.active_connections[room_id]

            logger.info(
                f"User {user_id} disconnected from room {room_id}. "
                f"Remaining connections in room: {len(self.active_connections.get(room_id, []))}. "
                f"Total connections: {self.total_connections}"
            )

    async def send_personal_message(self, message: str, websocket: WebSocket):
        """
        Send a message to a specific WebSocket connection.

        Args:
            message: The message to send
            websocket: The target WebSocket connection
        """
        try:
            await websocket.send_text(message)
        except Exception as e:
            logger.error(f"Error sending personal message: {e}")

    async def broadcast_to_room(self, message: str, room_id: int, exclude_websocket: WebSocket = None):
        """
        Broadcast a message to all connections in a room.

        Args:
            message: The message to broadcast
            room_id: The target room ID
            exclude_websocket: Optional WebSocket to exclude from broadcast (e.g., sender)
        """
        if room_id not in self.active_connections:
            logger.warning(f"Attempted to broadcast to non-existent room {room_id}")
            return

        disconnected = []
        connections = self.active_connections[room_id]

        for connection in connections:
            # Skip the excluded connection (usually the sender)
            if exclude_websocket and connection == exclude_websocket:
                continue

            try:
                await connection.send_text(message)
            except Exception as e:
                logger.error(f"Error broadcasting to connection: {e}")
                disconnected.append(connection)

        # Clean up any failed connections
        for connection in disconnected:
            self.disconnect(connection, room_id)

    def get_room_connection_count(self, room_id: int) -> int:
        """
        Get the number of active connections in a room.

        Args:
            room_id: The room ID

        Returns:
            Number of active connections
        """
        return len(self.active_connections.get(room_id, []))

    def get_total_connections(self) -> int:
        """
        Get the total number of active connections across all rooms.

        Returns:
            Total number of active connections
        """
        return self.total_connections

    def get_active_rooms(self) -> List[int]:
        """
        Get list of room IDs with active connections.

        Returns:
            List of room IDs
        """
        return list(self.active_connections.keys())


# Global ConnectionManager instance
manager = ConnectionManager()
