"""
TestPilot - Access Key Service
==============================
Free erişim ve Premium satın alma simülasyonu için kalıcı API key üretimi.
"""

from __future__ import annotations

import secrets
from datetime import datetime, timezone

from app.config import settings
from app.database import get_db


def create_access_key(plan: str, owner_name: str, issued_via: str) -> dict:
    """Plan için benzersiz, kalıcı access key oluştur."""
    limit = (
        settings.PREMIUM_MONTHLY_LIMIT
        if plan == "premium"
        else settings.FREE_MONTHLY_LIMIT
    )
    key = _generate_unique_key(plan)
    now = datetime.now(timezone.utc).isoformat()
    reset_at = _next_month_reset()

    with get_db() as conn:
        cursor = conn.execute(
            """INSERT INTO api_keys
               (key, plan, owner_name, issued_via, monthly_limit, usage_count, usage_reset_at, created_at)
               VALUES (?, ?, ?, ?, ?, 0, ?, ?)""",
            (key, plan, owner_name.strip(), issued_via, limit, reset_at, now),
        )
        row = conn.execute(
            "SELECT * FROM api_keys WHERE id = ?",
            (cursor.lastrowid,),
        ).fetchone()

    return dict(row)


def _generate_unique_key(plan: str) -> str:
    prefix = "tp_premium_" if plan == "premium" else "tp_free_"

    for _ in range(8):
        candidate = f"{prefix}{secrets.token_urlsafe(18)}"
        with get_db() as conn:
            exists = conn.execute(
                "SELECT 1 FROM api_keys WHERE key = ?",
                (candidate,),
            ).fetchone()
        if not exists:
            return candidate

    raise RuntimeError("Could not generate a unique access key")


def _next_month_reset() -> str:
    now = datetime.utcnow()
    if now.month == 12:
        return datetime(now.year + 1, 1, 1).isoformat()
    return datetime(now.year, now.month + 1, 1).isoformat()
