"""
TestPilot – Template Service
=============================
Custom template CRUD iş mantığı (premium only).

raw sqlite3 kullanılır; ORM yok.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status

from app.database import get_db


def _require_premium(key_info: dict) -> None:
    """Premium plan kontrolü. Free ise 403 fırlat."""
    if key_info.get("plan") != "premium":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Custom templates are available for Premium plan users only.",
        )


def list_templates(key_info: dict) -> list[dict]:
    """Kullanıcının kendi template'lerini listele."""
    _require_premium(key_info)
    with get_db() as conn:
        rows = conn.execute(
            "SELECT * FROM custom_templates WHERE api_key_id = ? ORDER BY updated_at DESC",
            (key_info["id"],),
        ).fetchall()
    return [dict(r) for r in rows]


def create_template(key_info: dict, name: str, prompt_text: str) -> dict:
    """Yeni template oluştur."""
    _require_premium(key_info)
    now = datetime.now(timezone.utc).isoformat()
    with get_db() as conn:
        cursor = conn.execute(
            """INSERT INTO custom_templates (api_key_id, name, prompt_text, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?)""",
            (key_info["id"], name.strip(), prompt_text.strip(), now, now),
        )
        template_id = cursor.lastrowid
        row = conn.execute(
            "SELECT * FROM custom_templates WHERE id = ?", (template_id,)
        ).fetchone()
    return dict(row)


def update_template(key_info: dict, template_id: int, name: str | None, prompt_text: str | None) -> dict:
    """Template güncelle (sadece sahip güncelleyebilir)."""
    _require_premium(key_info)

    with get_db() as conn:
        row = conn.execute(
            "SELECT * FROM custom_templates WHERE id = ? AND api_key_id = ?",
            (template_id, key_info["id"]),
        ).fetchone()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Template not found or access denied.",
            )

        existing = dict(row)
        new_name = name.strip() if name else existing["name"]
        new_prompt = prompt_text.strip() if prompt_text else existing["prompt_text"]
        now = datetime.now(timezone.utc).isoformat()

        conn.execute(
            "UPDATE custom_templates SET name = ?, prompt_text = ?, updated_at = ? WHERE id = ?",
            (new_name, new_prompt, now, template_id),
        )
        updated = conn.execute(
            "SELECT * FROM custom_templates WHERE id = ?", (template_id,)
        ).fetchone()

    return dict(updated)


def delete_template(key_info: dict, template_id: int) -> None:
    """Template sil (sadece sahip silebilir)."""
    _require_premium(key_info)

    with get_db() as conn:
        row = conn.execute(
            "SELECT id FROM custom_templates WHERE id = ? AND api_key_id = ?",
            (template_id, key_info["id"]),
        ).fetchone()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Template not found or access denied.",
            )

        conn.execute("DELETE FROM custom_templates WHERE id = ?", (template_id,))


def get_template_prompt(key_info: dict, template_id: int) -> str:
    """Template'in prompt_text'ini getir (generate akışında kullanılır).

    Premium kontrolü ve sahiplik doğrulaması yapar.
    """
    if key_info.get("plan") != "premium":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Template-based generation is available for Premium plan users only.",
        )

    with get_db() as conn:
        row = conn.execute(
            "SELECT prompt_text FROM custom_templates WHERE id = ? AND api_key_id = ?",
            (template_id, key_info["id"]),
        ).fetchone()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Template {template_id} not found or access denied.",
        )

    return row["prompt_text"]
