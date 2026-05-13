"""
TestPilot – History Service
============================
Generation geçmişi için raw sqlite3 sorguları.
"""

from __future__ import annotations

import json
from typing import Any

from app.database import get_db
from app.utils.output_compat import clean_legacy_markdown, normalize_generation_output


def list_generations(
    api_key_id: int,
    plan: str,
    mode: str | None = None,
    q: str | None = None,
) -> dict:
    """API key'e ait generation kayıtlarını döndür."""
    where = ["api_key_id = ?"]
    params: list[Any] = [api_key_id]

    if mode:
        where.append("mode = ?")
        params.append(mode)

    if q:
        where.append("(input_json LIKE ? OR output_json LIKE ?)")
        like_q = f"%{q}%"
        params.extend([like_q, like_q])

    sql = f"""
        SELECT id, mode, input_json, output_json, created_at
        FROM generations
        WHERE {' AND '.join(where)}
        ORDER BY datetime(created_at) DESC, id DESC
    """

    limit = 15 if plan == "free" else None
    if limit:
        sql += " LIMIT ?"
        params.append(limit)

    with get_db() as conn:
        rows = conn.execute(sql, params).fetchall()

    items = []
    for row in rows:
        output = _loads(row["output_json"])
        items.append({
            "generation_id": row["id"],
            "mode": row["mode"],
            "input": _loads(row["input_json"]),
            "output_summary": _summarize_output(output),
            "created_at": output.get("created_at") or row["created_at"],
        })

    return {
        "items": items,
        "count": len(items),
        "plan": plan,
        "limit": limit,
    }


def get_generation_detail(api_key_id: int, generation_id: int) -> dict | None:
    """Tek generation detayını sadece sahibi için döndür."""
    with get_db() as conn:
        row = conn.execute(
            """SELECT id, mode, input_json, output_json, output_md, created_at
               FROM generations
               WHERE id = ? AND api_key_id = ?""",
            (generation_id, api_key_id),
        ).fetchone()

    if not row:
        return None

    input_payload = _loads(row["input_json"])
    output = normalize_generation_output(_loads(row["output_json"]), input_payload)

    return {
        "generation_id": row["id"],
        "mode": row["mode"],
        "input": input_payload,
        "output": output,
        "markdown": clean_legacy_markdown(row["output_md"], output),
        "created_at": output.get("created_at") or row["created_at"],
    }


def delete_generation(api_key_id: int, generation_id: int) -> bool:
    """Generation kaydını sadece sahibi silebilir."""
    with get_db() as conn:
        cursor = conn.execute(
            "DELETE FROM generations WHERE id = ? AND api_key_id = ?",
            (generation_id, api_key_id),
        )
        return cursor.rowcount > 0


def _loads(value: str) -> dict:
    try:
        parsed = json.loads(value)
        return parsed if isinstance(parsed, dict) else {"value": parsed}
    except json.JSONDecodeError:
        return {"raw": value}


def _summarize_output(output: dict) -> str:
    if output.get("mode") == "bug_report" and output.get("bug_report"):
        return output["bug_report"].get("title", "Bug report")

    if output.get("user_story"):
        return output["user_story"][:180]

    test_plan = output.get("test_plan") or {}
    if test_plan.get("objective"):
        return test_plan["objective"][:180]

    return "Generation output"
