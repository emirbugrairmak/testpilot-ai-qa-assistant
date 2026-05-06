"""
TestPilot – Uygulama Ayarları
==============================
Ortam değişkenlerinden okunan konfigürasyon.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parents[1]
PROJECT_ROOT = BACKEND_DIR.parent

# Backend hem repo kökünden hem de backend/ içinden çalıştırılabiliyor.
# Bu yüzden önce kök .env, ardından backend/.env okunur; gerçek environment
# değişkenleri varsa python-dotenv bunların üstüne yazmaz.
load_dotenv(PROJECT_ROOT / ".env")
load_dotenv(BACKEND_DIR / ".env")


class Settings:
    """Uygulama konfigürasyonu."""

    # ── Genel ───────────────────────────────────────
    APP_NAME: str = "TestPilot API"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = ENVIRONMENT == "development"

    # ── CORS ────────────────────────────────────────
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",    # Frontend (Vite dev server)
        "http://127.0.0.1:3000",    # Frontend (local Docker/dev)
        "http://localhost:8000",    # Backend (Swagger UI)
        "http://127.0.0.1:8000",    # Backend (local Docker/dev)
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
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "gemini")

    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    # Kullanılacak Gemini modeli
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")

    # Gemini HTTP isteği için timeout (milisaniye)
    GEMINI_TIMEOUT_MS: int = int(os.getenv("GEMINI_TIMEOUT_MS", "30000"))

    # True ise Gemini başarısız olursa mock'a düşer. Demo güvenilirliği için görünür tutulur.
    LLM_FALLBACK_TO_MOCK: bool = (
        os.getenv("LLM_FALLBACK_TO_MOCK", "false").lower() == "true"
    )


settings = Settings()
