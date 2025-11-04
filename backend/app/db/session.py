"""
Database session management with async SQLAlchemy.
Connects to NeonDB PostgreSQL using connection pooling.
"""
import re
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

from app.core.config import settings


# Convert postgresql:// to postgresql+asyncpg:// for async support (Neon official pattern)
async_database_url = re.sub(r'^postgresql:', 'postgresql+asyncpg:', settings.DATABASE_URL)

# Remove sslmode and channel_binding from URL (asyncpg doesn't support these query params)
# asyncpg uses ssl=True by default for URLs with sslmode=require
async_database_url = re.sub(r'[?&]sslmode=[^&]*', '', async_database_url)
async_database_url = re.sub(r'[?&]channel_binding=[^&]*', '', async_database_url)

# Create async engine with connection pooling
engine = create_async_engine(
    async_database_url,
    echo=settings.DEBUG,  # Log SQL queries in debug mode
    future=True,
    pool_pre_ping=True,  # Verify connections before using
    pool_size=10,  # Connection pool size
    max_overflow=20,  # Allow extra connections when pool is full
    connect_args={"ssl": "require"}  # SSL required for Neon
)

# Session factory for creating database sessions
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Base class for all ORM models
Base = declarative_base()


async def get_db() -> AsyncSession:
    """
    Dependency for FastAPI endpoints to get a database session.
    Automatically commits on success, rolls back on error, and closes the session.

    Usage in FastAPI:
        @app.get("/users")
        async def get_users(db: AsyncSession = Depends(get_db)):
            result = await db.execute(select(User))
            return result.scalars().all()
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """
    Initialize database tables.
    This creates all tables defined in models.
    For production, use Alembic migrations instead.
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
