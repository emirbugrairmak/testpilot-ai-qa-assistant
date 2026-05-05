"""
TestPilot – Export Service
===========================
Generation kayıtlarını JSON, Markdown, CSV ve Jira-friendly text olarak dışa aktarır.
"""

from __future__ import annotations

import csv
import io
import json

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
            f"Summary: {bug.get('title', '')}",
            "Issue Type: Bug",
            f"Priority: {bug.get('priority', '')}",
            f"Labels: {', '.join(bug.get('labels', []))}",
            "",
            "Description:",
            bug.get("summary", ""),
            "",
            "Environment:",
            bug.get("environment", ""),
            "",
            "Steps to Reproduce:",
            *[f"{index}. {step}" for index, step in enumerate(bug.get("steps_to_reproduce", []), 1)],
            "",
            "Actual Result:",
            bug.get("actual_result", ""),
            "",
            "Expected Result:",
            bug.get("expected_result", ""),
        ])

    output = record["output"]
    lines = [
        f"Summary: QA test suite - {output.get('test_plan', {}).get('objective', 'Generated test cases')}",
        "Issue Type: Task",
        f"Labels: {', '.join(output.get('tags', []))}",
        "",
        "Description:",
        output.get("user_story", ""),
        "",
        "Acceptance Criteria:",
    ]

    for item in output.get("acceptance_criteria", []):
        lines.append(f"- {item}")

    lines.extend(["", "Test Cases:"])
    for test_case in output.get("test_cases", []):
        lines.extend([
            "",
            f"* {test_case.get('id', '')}: {test_case.get('title', '')}",
            f"  Priority: {test_case.get('priority', '')}",
            f"  Expected: {test_case.get('expected_result', '')}",
        ])

    return "\n".join(lines)


def export_filename(record: dict, extension: str) -> str:
    """Download filename üret."""
    return f"testpilot-generation-{record['generation_id']}.{extension}"


def _loads(value: str) -> dict:
    try:
        parsed = json.loads(value)
        return parsed if isinstance(parsed, dict) else {"value": parsed}
    except json.JSONDecodeError:
        return {"raw": value}
