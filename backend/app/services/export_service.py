"""
TestPilot – Export Service
===========================
Generation kayıtlarını JSON, Markdown, CSV ve Jira-friendly text olarak dışa aktarır.
"""

from __future__ import annotations

import csv
import io
import json
import re

from app.database import get_db


def get_owned_generation(api_key_id: int, generation_id: int) -> dict | None:
    """Generation kaydını sadece sahibi için döndür."""
    with get_db() as conn:
        row = conn.execute(
            """SELECT id, mode, input_json, output_json, output_md, created_at
               FROM generations
               WHERE id = ? AND api_key_id = ?""",
            (generation_id, api_key_id),
        ).fetchone()

    if not row:
        return None

    output = _loads(row["output_json"])

    return {
        "generation_id": row["id"],
        "mode": row["mode"],
        "input": _loads(row["input_json"]),
        "output": output,
        "markdown": row["output_md"],
        "created_at": output.get("created_at") or row["created_at"],
    }


def to_json_export(record: dict) -> str:
    """JSON export içeriği."""
    return json.dumps(record, ensure_ascii=False, indent=2)


def to_markdown_export(record: dict) -> str:
    """Markdown export içeriği."""
    return record["markdown"] or f"# Generation {record['generation_id']}\n"


def to_csv_export(record: dict) -> str:
    """Test case veya bug report kaydını basit CSV formatına dönüştür."""
    buffer = io.StringIO()
    writer = csv.writer(buffer)

    if record["mode"] == "bug_report":
        bug = record["output"].get("bug_report", {})
        writer.writerow([
            "generation_id",
            "mode",
            "title",
            "severity",
            "priority",
            "environment",
            "steps_to_reproduce",
            "actual_result",
            "expected_result",
            "labels",
        ])
        writer.writerow([
            record["generation_id"],
            record["mode"],
            bug.get("title", ""),
            bug.get("severity", ""),
            bug.get("priority", ""),
            bug.get("environment", ""),
            " | ".join(bug.get("steps_to_reproduce", [])),
            bug.get("actual_result", ""),
            bug.get("expected_result", ""),
            ", ".join(bug.get("labels", [])),
        ])
        return buffer.getvalue()

    writer.writerow([
        "generation_id",
        "mode",
        "test_case_id",
        "title",
        "type",
        "priority",
        "preconditions",
        "steps",
        "expected_result",
        "tags",
    ])

    for test_case in record["output"].get("test_cases", []):
        writer.writerow([
            record["generation_id"],
            record["mode"],
            test_case.get("id", ""),
            test_case.get("title", ""),
            test_case.get("type", ""),
            test_case.get("priority", ""),
            test_case.get("preconditions", ""),
            " | ".join(test_case.get("steps", [])),
            test_case.get("expected_result", ""),
            ", ".join(test_case.get("tags", [])),
        ])

    return buffer.getvalue()


def to_jira_export(record: dict) -> str:
    """Jira'ya kolay taşınabilecek düz metin çıktı."""
    if record["mode"] == "bug_report":
        bug = record["output"].get("bug_report", {})
        return "\n".join([
            "Jira Issue Draft",
            "================",
            "",
            "Issue Type: Bug",
            f"Title: {bug.get('title', '')}",
            f"Summary: {bug.get('summary', '')}",
            f"Priority: {bug.get('priority', '')}",
            f"Severity: {bug.get('severity', '')}",
            f"Labels: {', '.join(bug.get('labels', []))}",
            "",
            "Description:",
            bug.get("summary", ""),
            "",
            f"Environment: {bug.get('environment', '')}",
            "",
            "Steps to Reproduce:",
            *[f"{index}. {step}" for index, step in enumerate(_limit_items(bug.get("steps_to_reproduce", []), 6), 1)],
            "",
            "Actual Result:",
            bug.get("actual_result", ""),
            "",
            "Expected Result:",
            bug.get("expected_result", ""),
        ])

    output = record["output"]
    test_cases = output.get("test_cases", [])
    selected_cases = _select_jira_test_cases(test_cases)
    test_plan = output.get("test_plan", {})
    lines = [
        "Test Preparation Draft",
        "======================",
        "",
        "Issue Type: Task",
        f"Title: QA test preparation - {test_plan.get('objective', 'Generated test cases')}",
        f"Summary: {test_plan.get('objective', 'Generated test cases')}",
        f"Priority: {_highest_priority(selected_cases or test_cases)}",
        f"Labels: {', '.join(output.get('tags', []))}",
        "",
        "Description:",
        "Bu çıktı, özellik test edilmeden önce QA hazırlığı için oluşturulmuş taslaktır. Gerçek bir bug bildirimi değildir.",
        "",
        "User Story:",
        output.get("user_story", ""),
        "",
        "AC Summary:",
    ]

    for item in _limit_items(output.get("acceptance_criteria", []), 3):
        lines.append(f"- {item}")

    lines.extend([
        "",
        "Test Objective:",
        test_plan.get("objective", ""),
        "",
        "Suggested Test Approach:",
        _short_text(
            _remove_assumption_sentences(test_plan.get("approach") or test_plan.get("scope") or ""),
            320,
        ),
        "",
        "Suggested Test Cases:",
    ])

    for test_case in selected_cases:
        lines.extend([
            "",
            f"{test_case.get('id', '')}: {test_case.get('title', '')}",
            f"Priority: {test_case.get('priority', '')}",
            f"Expected Result: {test_case.get('expected_result', '')}",
        ])

    return "\n".join(lines)


def export_filename(record: dict, extension: str, suffix: str | None = None) -> str:
    """Download filename üret."""
    suffix_part = f"-{suffix}" if suffix else ""
    return f"generation-{record['generation_id']}{suffix_part}.{extension}"


def _highest_priority(test_cases: list[dict]) -> str:
    priority_order = ["P0", "P1", "P2", "P3"]
    priorities = {str(test_case.get("priority", "")).upper() for test_case in test_cases}
    for priority in priority_order:
        if priority in priorities:
            return priority
    return ""


def _select_jira_test_cases(test_cases: list[dict], limit: int = 4) -> list[dict]:
    """Jira task açıklaması için en alakalı, kısa test case özetlerini seç."""
    priority_rank = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
    assumption_keywords = [
        "başka cihaz",
        "diğer cihaz",
        "rate limit",
        "rate limiting",
        "audit log",
        "denetim kaydı",
    ]

    ranked = sorted(
        enumerate(test_cases),
        key=lambda item: (
            priority_rank.get(str(item[1].get("priority", "")).upper(), 9),
            item[0],
        ),
    )

    selected = []
    for _, test_case in ranked:
        searchable = " ".join([
            str(test_case.get("title", "")),
            str(test_case.get("expected_result", "")),
            " ".join(str(step) for step in test_case.get("steps", [])),
        ]).lower()
        if any(keyword in searchable for keyword in assumption_keywords):
            continue
        selected.append(test_case)
        if len(selected) >= limit:
            return selected

    return selected or test_cases[:limit]


def _remove_assumption_sentences(value: str) -> str:
    assumption_keywords = [
        "başka cihaz",
        "diğer cihaz",
        "cihazlar arası",
        "rate limit",
        "rate limiting",
        "audit log",
        "denetim kaydı",
    ]
    sentences = re.split(r"(?<=[.!?])\s+", str(value or "").strip())
    filtered = [
        sentence
        for sentence in sentences
        if sentence and not any(keyword in sentence.lower() for keyword in assumption_keywords)
    ]
    return " ".join(filtered)


def _limit_items(items: list, limit: int) -> list:
    return list(items or [])[:limit]


def _short_text(value: str, limit: int) -> str:
    text = " ".join(str(value or "").split())
    if len(text) <= limit:
        return text
    return text[: limit - 1].rstrip() + "…"


def _loads(value: str) -> dict:
    try:
        parsed = json.loads(value)
        return parsed if isinstance(parsed, dict) else {"value": parsed}
    except json.JSONDecodeError:
        return {"raw": value}
