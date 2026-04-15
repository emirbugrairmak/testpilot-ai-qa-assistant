"""
TestPilot – AI QA Assistant | Backend API
==========================================
FastAPI entry point.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings

app = FastAPI(
    title="TestPilot API",
    description="AI-powered QA assistant – from idea to test cases, in minutes.",
    version="0.1.0",
)

# ── CORS ────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health Check ────────────────────────────────────────
@app.get("/health", tags=["System"])
async def health_check():
    """Servis sağlık kontrolü."""
    return {
        "status": "healthy",
        "service": "TestPilot API",
        "version": "0.1.0",
    }


# ── Root ────────────────────────────────────────────────
@app.get("/", tags=["System"])
async def root():
    """API kök endpoint'i."""
    return {
        "message": "Welcome to TestPilot API",
        "docs": "/docs",
        "health": "/health",
    }
