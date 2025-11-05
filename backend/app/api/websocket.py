"""
WebSocket endpoints for real-time communication.
"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status, Query
from typing import Optional
import json
import logging
from datetime import datetime

from app.websocket.connection_manager import manager
from app.websocket.redis_pubsub import redis_manager
from app.core.security import verify_token
from app.db.session import get_db
from app.models.user import User
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

router = APIRouter()
logger = logging.getLogger(__name__)


async def get_current_user_ws(token: str, db: AsyncSession) -> Optional[User]:
    """
    Authenticate user from WebSocket token.

    Args:
        token: JWT token from query parameter
        db: Database session

    Returns:
        User object if authenticated, None otherwise
    """
    try:
        # Verify JWT token
        payload = verify_token(token)
        if payload is None:
            return None

        email: str = payload.get("sub")
        if email is None:
            return None

        # Get user from database
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()

        return user
    except Exception as e:
        logger.error(f"WebSocket authentication error: {e}")
        return None


@router.websocket("/ws/room/{room_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    room_id: int,
    token: str = Query(..., description="JWT authentication token")
):
    """
    WebSocket endpoint for real-time room communication.

    Connection URL: ws://localhost:8000/ws/room/{room_id}?token={jwt_token}

    Message Types:
    - message: Chat message
    - note: Sticky note update
    - typing: Typing indicator
    - ping: Keep-alive heartbeat

    Args:
        websocket: WebSocket connection
        room_id: The room ID to join
        token: JWT authentication token (query parameter)
    """
    # Get database session
    db_gen = get_db()
    db: AsyncSession = await anext(db_gen)

    try:
        # Authenticate user
        user = await get_current_user_ws(token, db)

        if not user:
            logger.warning(f"Unauthorized WebSocket connection attempt to room {room_id}")
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid authentication token")
            return

        # Accept connection and register with ConnectionManager
        await manager.connect(websocket, room_id, user.id)

        # Subscribe to Redis channel for this room
        async def handle_redis_message(message: dict):
            """Callback for Redis pub/sub messages"""
            try:
                # Broadcast to all local connections in this room
                await manager.broadcast_to_room(json.dumps(message), room_id)
            except Exception as e:
                logger.error(f"Error handling Redis message: {e}")

        await redis_manager.subscribe(room_id, handle_redis_message)

        # Send join notification
        join_message = {
            "type": "join",
            "data": {
                "user_id": user.id,
                "user_email": user.email,
                "user_name": user.full_name or user.email,
                "room_id": room_id,
                "active_users": manager.get_room_connection_count(room_id)
            },
            "timestamp": datetime.utcnow().isoformat()
        }

        # Publish to Redis (will be broadcast to all servers/connections)
        await redis_manager.publish(room_id, join_message)

        # Listen for messages from this client
        while True:
            try:
                # Receive message from WebSocket
                data = await websocket.receive_text()
                message_data = json.loads(data)

                # Add metadata
                message_data["user_id"] = user.id
                message_data["user_email"] = user.email
                message_data["user_name"] = user.full_name or user.email
                message_data["room_id"] = room_id
                message_data["timestamp"] = datetime.utcnow().isoformat()

                # Handle different message types
                message_type = message_data.get("type")

                if message_type == "ping":
                    # Respond to heartbeat
                    await websocket.send_text(json.dumps({
                        "type": "pong",
                        "timestamp": datetime.utcnow().isoformat()
                    }))
                    continue

                # Publish message to Redis (will fan-out to all servers)
                await redis_manager.publish(room_id, message_data)

                logger.debug(f"User {user.id} sent {message_type} to room {room_id}")

            except WebSocketDisconnect:
                logger.info(f"User {user.id} disconnected from room {room_id}")
                break
            except json.JSONDecodeError:
                logger.warning(f"Invalid JSON from user {user.id}")
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format"
                }))
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                break

    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        # Cleanup on disconnect
        manager.disconnect(websocket, room_id)

        # If no more connections in this room, unsubscribe from Redis
        if manager.get_room_connection_count(room_id) == 0:
            await redis_manager.unsubscribe(room_id)

        # Send leave notification
        if user:
            leave_message = {
                "type": "leave",
                "data": {
                    "user_id": user.id,
                    "user_email": user.email,
                    "user_name": user.full_name or user.email,
                    "room_id": room_id,
                    "active_users": manager.get_room_connection_count(room_id)
                },
                "timestamp": datetime.utcnow().isoformat()
            }

            # Publish leave message
            await redis_manager.publish(room_id, leave_message)

        # Close database session
        await db.close()
