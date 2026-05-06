"""
TestPilot – AI QA Assistant | Backend API
==========================================
FastAPI entry point.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db
from app.routers import auth, export, generate, history, templates, usage


# ── Lifespan ────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Uygulama başlangıcında DB'yi başlat."""
    init_db()
    yield


# ── App ─────────────────────────────────────────────────

app = FastAPI(
    title="TestPilot API",
    description="AI-powered QA assistant – from idea to test cases, in minutes.",
    version="0.1.0",
    lifespan=lifespan,
)

# ── CORS ────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["Content-Disposition"],
)

# ── Routers ─────────────────────────────────────────────
app.include_router(auth.router, prefix="/api/v1")
app.include_router(generate.router, prefix="/api/v1")
app.include_router(history.router, prefix="/api/v1")
app.include_router(export.router, prefix="/api/v1")
app.include_router(usage.router, prefix="/api/v1")
app.include_router(templates.router, prefix="/api/v1")


# ── Health Check ────────────────────────────────────────
@app.get("/health", tags=["System"])
async def health_check():
    """Servis sağlık kontrolü."""
    configured_provider = settings.LLM_PROVIDER.lower()
    if configured_provider == "gemini" and settings.GEMINI_API_KEY:
        effective_provider = "gemini"
    elif configured_provider == "gemini" and settings.LLM_FALLBACK_TO_MOCK:
        effective_provider = "mock"
    elif configured_provider == "gemini":
        effective_provider = "unavailable"
    elif configured_provider == "mock":
        effective_provider = "mock"
    else:
        effective_provider = "unsupported"

    return {
        "status": "healthy",
        "service": "TestPilot API",
        "version": "0.1.0",
        "ai": {
            "configured_provider": configured_provider,
            "effective_provider": effective_provider,
            "model": settings.GEMINI_MODEL if effective_provider == "gemini" else "mock",
            "fallback_to_mock": settings.LLM_FALLBACK_TO_MOCK,
            "gemini_key_configured": bool(settings.GEMINI_API_KEY),
        },
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
