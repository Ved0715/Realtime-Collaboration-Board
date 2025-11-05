"""
Redis Pub/Sub Service for WebSocket message broadcasting.
Handles publishing and subscribing to room-specific channels.
"""
import json
import asyncio
import logging
from typing import Callable, Dict
import redis.asyncio as redis
from app.core.config import settings

logger = logging.getLogger(__name__)


class RedisPubSubManager:
    """
    Manages Redis Pub/Sub for WebSocket message broadcasting.
    Allows horizontal scaling across multiple servers.
    """

    def __init__(self):
        self.redis_client: redis.Redis = None
        self.pubsub: redis.client.PubSub = None
        self.subscriptions: Dict[str, Callable] = {}  # channel -> callback

    async def connect(self):
        """Initialize Redis connection and pub/sub client."""
        try:
            self.redis_client = redis.from_url(
                settings.redis_url,
                encoding="utf-8",
                decode_responses=True
            )
            self.pubsub = self.redis_client.pubsub()

            # Test connection
            await self.redis_client.ping()
            logger.info(f"✅ Connected to Redis at {settings.redis_url}")
        except Exception as e:
            logger.error(f"❌ Failed to connect to Redis: {e}")
            raise

    async def disconnect(self):
        """Close Redis connections gracefully."""
        try:
            if self.pubsub:
                await self.pubsub.close()
            if self.redis_client:
                await self.redis_client.close()
            logger.info("✅ Disconnected from Redis")
        except Exception as e:
            logger.error(f"Error disconnecting from Redis: {e}")

    def get_room_channel(self, room_id: int) -> str:
        """
        Get Redis channel name for a room.

        Args:
            room_id: The room ID

        Returns:
            Channel name in format "room:{room_id}"
        """
        return f"room:{room_id}"

    async def publish(self, room_id: int, message: dict):
        """
        Publish a message to a room's Redis channel.
        All servers subscribed to this channel will receive the message.

        Args:
            room_id: The target room ID
            message: The message data (will be JSON serialized)
        """
        try:
            channel = self.get_room_channel(room_id)
            message_json = json.dumps(message)

            await self.redis_client.publish(channel, message_json)
            logger.debug(f"Published to {channel}: {message.get('type', 'unknown')}")
        except Exception as e:
            logger.error(f"Error publishing to Redis: {e}")

    async def subscribe(self, room_id: int, callback: Callable):
        """
        Subscribe to a room's Redis channel.
        When a message is published to this channel, the callback is invoked.

        Args:
            room_id: The room ID to subscribe to
            callback: Async function to call when message received
        """
        try:
            channel = self.get_room_channel(room_id)

            # Subscribe to channel
            await self.pubsub.subscribe(channel)
            self.subscriptions[channel] = callback

            logger.info(f"✅ Subscribed to channel: {channel}")

            # Start listening in background
            asyncio.create_task(self._listen(channel))
        except Exception as e:
            logger.error(f"Error subscribing to Redis channel: {e}")

    async def unsubscribe(self, room_id: int):
        """
        Unsubscribe from a room's Redis channel.

        Args:
            room_id: The room ID to unsubscribe from
        """
        try:
            channel = self.get_room_channel(room_id)

            await self.pubsub.unsubscribe(channel)
            self.subscriptions.pop(channel, None)

            logger.info(f"✅ Unsubscribed from channel: {channel}")
        except Exception as e:
            logger.error(f"Error unsubscribing from Redis channel: {e}")

    async def _listen(self, channel: str):
        """
        Background task to listen for messages on a subscribed channel.

        Args:
            channel: The Redis channel to listen to
        """
        try:
            async for message in self.pubsub.listen():
                if message["type"] == "message":
                    # Parse JSON message
                    data = json.loads(message["data"])

                    # Call the registered callback
                    callback = self.subscriptions.get(channel)
                    if callback:
                        await callback(data)
                    else:
                        logger.warning(f"No callback registered for channel: {channel}")
        except Exception as e:
            logger.error(f"Error in Redis listener for {channel}: {e}")
            # Clean up subscription
            self.subscriptions.pop(channel, None)


# Global Redis Pub/Sub Manager instance
redis_manager = RedisPubSubManager()
