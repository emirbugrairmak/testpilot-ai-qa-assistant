"""
TestPilot – Generation Service
================================
Üretim iş mantığı: input doğrulama → LLM çağrısı → DB kayıt → response.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone

from app.database import get_db
from app.services.llm_service import generate_with_llm


def run_generation(mode: str, inputs: dict, key_info: dict) -> dict:
    """Tek bir test üretimi gerçekleştir.

    Args:
        mode: "mod_a", "mod_b" veya "bug_report"
        inputs: Moda göre değişen input dict
        key_info: API key bilgisi (plan, id, vb.)

    Returns:
        Tam response dict (generation_id dahil)
    """
    # ── 1. LLM ile üret ────────────────────────────
    plan = key_info.get("plan", "free")

    # Template hint'i inputs'tan çıkar (DB'ye kaydedilmeyecek)
    inputs_for_db = {k: v for k, v in inputs.items() if k != "custom_template_hint"}
    template_hint = inputs.get("custom_template_hint")

    result = generate_with_llm(mode, inputs_for_db, plan=plan, template_hint=template_hint)
    provider = result.get("provider", "unknown")


    # ── 2. Free plan kaynak damgası ─────────────────
    plan_stamp = None
    if key_info["plan"] == "free":
        plan_stamp = {
            "plan": "free",
            "label": "Free plan",
            "source": "testpilot_free",
            "note": "Generated with TestPilot Free plan.",
        }

    # ── 3. Timestamp ───────────────────────────────
    created_at = datetime.now(timezone.utc).isoformat()

    # ── 4. Output dict oluştur ─────────────────────
    if mode == "bug_report":
        br = result["bug_report"]
        output = {
            "mode": mode,
            "provider": provider,
            "bug_report": br,
            "tags": br.get("labels", ["bug"]),
            "created_at": created_at,
        }
    else:
        all_tags = set()
        for tc in result.get("test_cases", []):
            all_tags.update(tc.get("tags", []))

        output = {
            "mode": mode,
            "provider": provider,
            "user_story": result["user_story"],
            "acceptance_criteria": result["acceptance_criteria"],
            "test_plan": result["test_plan"],
            "test_cases": result["test_cases"],
            "tags": sorted(all_tags),
            "created_at": created_at,
        }

    if plan_stamp:
        output["plan_stamp"] = plan_stamp

    # ── 5. Markdown çıktı üret ─────────────────────
    output_md = _to_markdown(output)

    # ── 6. Veritabanına kaydet ─────────────────────
    output_json_str = json.dumps(output, ensure_ascii=False)
    input_json_str = json.dumps(inputs_for_db, ensure_ascii=False)

    with get_db() as conn:
        cursor = conn.execute(
            """INSERT INTO generations
               (api_key_id, mode, input_json, output_json, output_md, created_at)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                key_info["id"],
                mode,
                input_json_str,
                output_json_str,
                output_md,
                created_at,
            ),
        )
        generation_id = cursor.lastrowid

    # ── 7. Response ────────────────────────────────
    output["generation_id"] = generation_id
    if mode == "bug_report":
        output["markdown"] = output_md
    return output


def _to_markdown(data: dict) -> str:
    """Üretim çıktısını markdown formatına dönüştür."""
    if data.get("mode") == "bug_report":
        return _bug_report_to_markdown(data)

    lines = []

    lines.append(f"# Test Plan: {data['test_plan']['objective']}")
    lines.append("")
    lines.append(f"**Mode:** `{data['mode']}`")
    lines.append(f"**AI Provider:** `{data.get('provider', 'unknown')}`")
    lines.append(f"**Generated:** {data['created_at']}")
    lines.append("")

    # User Story
    lines.append("## User Story")
    lines.append("")
    lines.append(data["user_story"])
    lines.append("")

    # Acceptance Criteria
    lines.append("## Acceptance Criteria")
    lines.append("")
    ac = data["acceptance_criteria"]
    if isinstance(ac, list):
        for item in ac:
            lines.append(f"- {item}")
    else:
        lines.append(ac)
    lines.append("")

    # Test Plan
    tp = data["test_plan"]
    lines.append("## Test Plan")
    lines.append("")
    lines.append(f"**Objective:** {tp['objective']}")
    lines.append(f"**Scope:** {tp['scope']}")
    lines.append(f"**Test Types:** {', '.join(tp['test_types'])}")
    lines.append(f"**Approach:** {tp['approach']}")
    lines.append("")

    # Test Cases
    lines.append("## Test Cases")
    lines.append("")
    for tc in data.get("test_cases", []):
        lines.append(f"### {tc['id']} — {tc['title']}")
        lines.append("")
        lines.append(f"- **Type:** {tc['type']}")
        lines.append(f"- **Priority:** {tc['priority']}")
        lines.append(f"- **Preconditions:** {tc['preconditions']}")
        lines.append("- **Steps:**")
        for i, step in enumerate(tc["steps"], 1):
            lines.append(f"  {i}. {step}")
        lines.append(f"- **Expected Result:** {tc['expected_result']}")
        lines.append(f"- **Tags:** {', '.join(tc['tags'])}")
        lines.append("")

    if data.get("plan_stamp"):
        lines.append("---")
        lines.append(f"*Plan source: {data['plan_stamp'].get('label', 'Free plan')}.*")
        lines.append("")

    return "\n".join(lines)


def _bug_report_to_markdown(data: dict) -> str:
    """Bug report çıktısını markdown formatına dönüştür."""
    bug = data["bug_report"]
    lines = [
        f"# Bug Report: {bug['title']}",
        "",
        f"**Mode:** `{data['mode']}`",
        f"**AI Provider:** `{data.get('provider', 'unknown')}`",
        f"**Generated:** {data['created_at']}",
        f"**Severity:** {bug['severity']}",
        f"**Priority:** {bug['priority']}",
        f"**Environment:** {bug['environment']}",
        "",
        "## Summary",
        "",
        bug["summary"],
        "",
        "## Steps to Reproduce",
        "",
    ]

    for index, step in enumerate(bug["steps_to_reproduce"], 1):
        lines.append(f"{index}. {step}")

    lines.extend([
        "",
        "## Actual Result",
        "",
        bug["actual_result"],
        "",
        "## Expected Result",
        "",
        bug["expected_result"],
        "",
        "## Labels",
        "",
        ", ".join(bug["labels"]),
        "",
    ])

    if data.get("plan_stamp"):
        lines.append("---")
        lines.append(f"*Plan source: {data['plan_stamp'].get('label', 'Free plan')}.*")
        lines.append("")

    return "\n".join(lines)
