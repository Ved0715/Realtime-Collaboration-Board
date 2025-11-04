from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import time

from app.core.config import settings

# Application startup/shutdown lifecycle
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handles application lifecycle: startup and shutdown."""
    # Startup
    app.state.start_time = time.time()
    print(f"🚀 {settings.APP_NAME} starting up...")
    print(f"📊 Debug mode: {settings.DEBUG}")

    # Initialize database
    from app.db.session import init_db, engine
    print("📊 Initializing database...")
    await init_db()
    print("✅ Database initialized")

    # TODO: Initialize Redis connection pool

    yield

    # Shutdown
    print(f"🛑 {settings.APP_NAME} shutting down...")

    # Close database connections
    await engine.dispose()
    print("✅ Database connections closed")

    # TODO: Close Redis connections


app = FastAPI(
    title=settings.APP_NAME,
    description="A real-time collaboration board with WebSockets, Redis pub/sub, and JWT auth",
    version="1.0.0",
    lifespan=lifespan,
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#health check endpoint
@app.get("/")
async def root():
    return {
        "message": f"Welcome to {settings.APP_NAME}!",
        "uptime_seconds": time.time() - app.state.start_time,
        "status": "healthy",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "uptime_seconds": time.time() - app.state.start_time,
        "service": settings.APP_NAME
    }


# Metrics endpoint (basic version - will expand later)
@app.get("/metrics")
async def metrics():
    """
      Prometheus-style metrics endpoint.
      Shows active connections, uptime, and message counts.
    """
    uptime = time.time() - app.state.start_time
    return {
        "uptime_seconds": round(uptime, 2),
        "active_websocket_connections": 0,  # TODO: Track from ConnectionManager
        "total_messages_sent": 0,  # TODO: Track from Redis/DB
        "total_rooms": 0,  # TODO: Query from DB
    }


# Include API routers
from app.api import auth

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])

# TODO: Add more API routers
# app.include_router(rooms_router, prefix="/api/rooms", tags=["Rooms"])
# app.include_router(messages_router, prefix="/api/messages", tags=["Messages"])
# app.include_router(websocket_router, prefix="/ws", tags=["WebSocket"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
