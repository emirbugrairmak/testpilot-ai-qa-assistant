"""
TestPilot – Auth Utilities
============================
API key doğrulama ve kullanım limiti kontrolü için FastAPI dependency'leri.
"""

from datetime import datetime, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.database import get_db

security = HTTPBearer()


def _next_month_reset() -> str:
    """Bugünden bir ay sonrası için ISO tarih döndür."""
    now = datetime.now(timezone.utc)
    year = now.year + 1 if now.month == 12 else now.year
    month = 1 if now.month == 12 else now.month + 1
    day = min(now.day, _days_in_month(year, month))
    return now.replace(year=year, month=month, day=day).isoformat()


def _days_in_month(year: int, month: int) -> int:
    if month == 2:
        if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0:
            return 29
        return 28
    if month in {4, 6, 9, 11}:
        return 30
    return 31


def get_api_key_info(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """Bearer token doğrula ve API key bilgisini döndür.

    - Geçersiz veya deaktif key → 401
    - Ay sıfırlama gerekiyorsa otomatik sıfırlar
    - dict olarak key bilgisini döndürür
    """
    token = credentials.credentials

    with get_db() as conn:
        row = conn.execute(
            "SELECT * FROM api_keys WHERE key = ? AND is_active = 1",
            (token,),
        ).fetchone()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or inactive API key",
                headers={"WWW-Authenticate": "Bearer"},
            )

        key_info = dict(row)

        # ── Ay sıfırlama kontrolü ──────────────────
        now = datetime.now(timezone.utc)
        try:
            reset_at = datetime.fromisoformat(key_info["usage_reset_at"])
            if reset_at.tzinfo is None:
                reset_at = reset_at.replace(tzinfo=timezone.utc)
        except (ValueError, TypeError):
            reset_at = now  # Bozuk tarih varsa şimdi sıfırla

        if now >= reset_at:
            new_reset = _next_month_reset()
            conn.execute(
                "UPDATE api_keys SET usage_count = 0, usage_reset_at = ? WHERE id = ?",
                (new_reset, key_info["id"]),
            )
            key_info["usage_count"] = 0
            key_info["usage_reset_at"] = new_reset

    return key_info


def check_usage_limit(key_info: dict) -> None:
    """Kullanım limitini kontrol et. Aşıldıysa 429 fırlat."""
    if key_info["usage_count"] >= key_info["monthly_limit"]:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                f"Monthly usage limit reached ({key_info['monthly_limit']} generations). "
                f"Plan: {key_info['plan']}. "
                f"Resets at: {key_info['usage_reset_at']}"
            ),
        )


def increment_usage(api_key_id: int) -> None:
    """Kullanım sayacını 1 artır."""
    with get_db() as conn:
        conn.execute(
            "UPDATE api_keys SET usage_count = usage_count + 1 WHERE id = ?",
            (api_key_id,),
        )
