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
    DEMO_RESET_ON_STARTUP: bool = (
        os.getenv("DEMO_RESET_ON_STARTUP", "true").lower() == "true"
    )

    # ── Usage Limits ────────────────────────────────
    FREE_MONTHLY_LIMIT: int = 30
    PREMIUM_MONTHLY_LIMIT: int = 200

    # ── LLM ─────────────────────────────────────────
    # "mock" → deterministik mock generator (test / geliştirme)
    # "gemini" → gerçek Gemini API (GEMINI_API_KEY gerekli)
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "mock")

    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    # Kullanılacak Gemini modeli
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")

    # True ise Gemini başarısız olursa mock'a düşer. Demo güvenilirliği için görünür tutulur.
    LLM_FALLBACK_TO_MOCK: bool = (
        os.getenv("LLM_FALLBACK_TO_MOCK", "false").lower() == "true"
    )


settings = Settings()
