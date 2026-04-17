"""
TestPilot – Uygulama Ayarları
==============================
Ortam değişkenlerinden okunan konfigürasyon.
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Uygulama konfigürasyonu."""

    # ── Genel ───────────────────────────────────────
    APP_NAME: str = "TestPilot API"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = ENVIRONMENT == "development"

    # ── CORS ────────────────────────────────────────
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",    # Frontend (Vite dev server)
        "http://localhost:8000",    # Backend (Swagger UI)
    ]

    # ── Database ────────────────────────────────────
    DATABASE_PATH: str = os.getenv("DATABASE_PATH", "data/testpilot.db")

    # ── Usage Limits ────────────────────────────────
    FREE_MONTHLY_LIMIT: int = 30
    PREMIUM_MONTHLY_LIMIT: int = 200

    # ── LLM (ileride Gemini entegrasyonu için) ──────
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "mock")  # "mock" | "gemini"


settings = Settings()
