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


settings = Settings()
