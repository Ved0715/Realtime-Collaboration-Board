# ============================================
# Stage 1: Builder (Build dependencies)
# ============================================
# Use official Python 3.13 slim image as base
# "slim" = smaller size, "alpine" = even smaller but compatibility issues
FROM python:3.13-slim as builder

# Set working directory inside container
# All subsequent commands run from this directory
WORKDIR /app

# Install system dependencies needed for Python packages
# - gcc, g++: Compilers for building Python packages with C extensions
# - libpq-dev: PostgreSQL development files (needed for asyncpg)
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first (Docker layer caching optimization)
# If requirements.txt doesn't change, Docker reuses cached layer
COPY requirements.txt .

# Install Python dependencies
# --no-cache-dir: Don't cache pip downloads (saves space)
# --upgrade: Ensure latest pip version
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# ============================================
# Stage 2: Runtime (Final lean image)
# ============================================
FROM python:3.13-slim

# Set environment variables
# PYTHONUNBUFFERED=1: Force Python to print output immediately (good for logs)
# PYTHONDONTWRITEBYTECODE=1: Don't create .pyc files (saves space)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create non-root user for security
# Running as root inside container is bad practice
RUN useradd -m -u 1000 appuser

# Set working directory
WORKDIR /app

# Install only runtime dependencies (not build tools)
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder stage
# This avoids re-installing packages in final image
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
# Uses .dockerignore to exclude unnecessary files
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8000 (documentation only, doesn't actually open port)
# Actual port mapping happens in docker-compose.yml or docker run -p
EXPOSE 8000

# Health check (Docker will periodically check if container is healthy)
# Every 30s, check if app responds on /health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Command to run when container starts
# Uses uvicorn with production settings
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
