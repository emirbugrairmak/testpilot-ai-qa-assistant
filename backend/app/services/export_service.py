"""
TestPilot – Export Service
===========================
Generation kayıtlarını JSON, Markdown, CSV ve Jira-friendly text olarak dışa aktarır.
"""

from __future__ import annotations

import csv
import hashlib
import hmac
import io
import json
import re
import uuid
from datetime import datetime, timezone
from typing import Any

from app.config import settings
from app.database import get_db


PROVENANCE_STAMP_TYPE = "testpilot_free_export_provenance"
PROVENANCE_ALGORITHM = "HMAC-SHA256"
MARKDOWN_PROVENANCE_TITLE = "TestPilot Free Export Provenance"


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


def to_json_export(record: dict, key_info: dict | None = None) -> str:
    """JSON export içeriği."""
    export_payload = _deepcopy_json(record)
    if _should_add_free_provenance(key_info):
        export_payload["export_meta"] = _build_export_meta(
            payload=_export_payload_for_hash(export_payload),
            format_name="json",
        )

    return json.dumps(export_payload, ensure_ascii=False, indent=2)


def to_markdown_export(record: dict, key_info: dict | None = None) -> str:
    """Markdown export içeriği."""
    content = record["markdown"] or f"# Generation {record['generation_id']}\n"
    if not _should_add_free_provenance(key_info):
        return content

    body = _strip_legacy_plan_footer(_strip_markdown_provenance(content)).rstrip()
    meta = _build_export_meta(payload=body, format_name="markdown")
    return "\n".join([
        body,
        "",
        "---",
        MARKDOWN_PROVENANCE_TITLE,
        f"Export ID: {meta['export_id']}",
        f"Generated At: {meta['generated_at']}",
        f"Plan: {meta['plan_label']}",
        f"Payload SHA256: {meta['payload_sha256']}",
        f"Signature: {meta['signature']}",
        "",
    ])


def to_csv_export(record: dict, key_info: dict | None = None) -> str:
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


def to_jira_export(record: dict, key_info: dict | None = None) -> str:
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


def verify_export_content(content: str, format_name: str | None = None) -> dict:
    """Free export provenance bilgisini doğrula.

    Bu doğrulama silmeyi engellemez; export gövdesinin imzalı kaynak damgasıyla
    uyumlu olup olmadığını söyler.
    """
    detected_format = format_name or _detect_export_format(content)
    if detected_format == "json":
        return _verify_json_export(content)
    if detected_format in {"markdown", "text"}:
        return _verify_markdown_export(content)

    return _invalid_verify_result(
        format_name=detected_format,
        reason="Unsupported export format.",
    )


def _build_export_meta(payload: Any, format_name: str) -> dict[str, str]:
    payload_sha = _payload_sha256(payload)
    meta = {
        "stamp_type": PROVENANCE_STAMP_TYPE,
        "version": "1",
        "algorithm": PROVENANCE_ALGORITHM,
        "export_id": f"tpx_{uuid.uuid4().hex}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "plan_label": "Free plan",
        "format": format_name,
        "payload_sha256": payload_sha,
    }
    meta["signature"] = _sign_export_meta(meta)
    return meta


def _verify_json_export(content: str) -> dict:
    try:
        parsed = json.loads(content)
    except json.JSONDecodeError:
        return _invalid_verify_result("json", "Invalid JSON content.")

    if not isinstance(parsed, dict):
        return _invalid_verify_result("json", "JSON export must be an object.")

    meta = parsed.get("export_meta")
    if not isinstance(meta, dict):
        return _invalid_verify_result("json", "Missing export_meta.")

    payload = _export_payload_for_hash(parsed)
    return _verify_meta(meta=meta, payload=payload, format_name="json")


def _verify_markdown_export(content: str) -> dict:
    body, meta = _extract_markdown_provenance(content)
    if not meta:
        return _invalid_verify_result("markdown", "Missing provenance footer.")

    return _verify_meta(meta=meta, payload=body, format_name="markdown")


def _verify_meta(meta: dict, payload: Any, format_name: str) -> dict:
    expected_payload_sha = _payload_sha256(payload)
    payload_changed = meta.get("payload_sha256") != expected_payload_sha
    signature_valid = hmac.compare_digest(
        str(meta.get("signature", "")),
        _sign_export_meta(meta),
    )
    stamp_type_valid = meta.get("stamp_type") == PROVENANCE_STAMP_TYPE
    algorithm_valid = meta.get("algorithm") == PROVENANCE_ALGORITHM
    plan_valid = meta.get("plan_label") == "Free plan"
    format_valid = meta.get("format") in {format_name, None}
    valid = (
        not payload_changed
        and signature_valid
        and stamp_type_valid
        and algorithm_valid
        and plan_valid
        and format_valid
    )

    reason = "Signature and payload hash are valid."
    if payload_changed:
        reason = "Payload hash does not match export content."
    elif not signature_valid:
        reason = "Signature is invalid."
    elif not stamp_type_valid or not algorithm_valid or not plan_valid or not format_valid:
        reason = "Provenance metadata is not a valid TestPilot Free export stamp."

    return {
        "valid": valid,
        "signature_valid": signature_valid,
        "payload_changed": payload_changed,
        "is_testpilot_free_export": valid,
        "format": format_name,
        "reason": reason,
        "export_meta": _public_meta(meta),
    }


def _sign_export_meta(meta: dict) -> str:
    message = "\n".join([
        str(meta.get("stamp_type", "")),
        str(meta.get("version", "")),
        str(meta.get("algorithm", "")),
        str(meta.get("export_id", "")),
        str(meta.get("generated_at", "")),
        str(meta.get("plan_label", "")),
        str(meta.get("format", "")),
        str(meta.get("payload_sha256", "")),
    ])
    return hmac.new(
        settings.EXPORT_SIGNATURE_SECRET.encode("utf-8"),
        message.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def _payload_sha256(payload: Any) -> str:
    if isinstance(payload, str):
        payload_bytes = payload.encode("utf-8")
    else:
        payload_bytes = json.dumps(
            payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
    return hashlib.sha256(payload_bytes).hexdigest()


def _export_payload_for_hash(payload: dict) -> dict:
    clean = _deepcopy_json(payload)
    clean.pop("export_meta", None)
    return clean


def _should_add_free_provenance(key_info: dict | None) -> bool:
    return key_info is not None and key_info.get("plan") == "free"


def _detect_export_format(content: str) -> str:
    stripped = content.lstrip()
    if stripped.startswith("{"):
        return "json"
    return "markdown"


def _strip_markdown_provenance(content: str) -> str:
    body, _ = _extract_markdown_provenance(content)
    return body if body else content


def _extract_markdown_provenance(content: str) -> tuple[str, dict[str, str] | None]:
    marker = f"\n---\n{MARKDOWN_PROVENANCE_TITLE}\n"
    index = content.rfind(marker)
    if index == -1:
        return content.rstrip(), None

    body = content[:index].rstrip()
    footer = content[index + len(marker):]
    meta = {
        "stamp_type": PROVENANCE_STAMP_TYPE,
        "version": "1",
        "algorithm": PROVENANCE_ALGORITHM,
        "format": "markdown",
    }
    field_map = {
        "Export ID": "export_id",
        "Generated At": "generated_at",
        "Plan": "plan_label",
        "Payload SHA256": "payload_sha256",
        "Signature": "signature",
    }

    for line in footer.splitlines():
        if ": " not in line:
            continue
        key, value = line.split(": ", 1)
        if key in field_map:
            meta[field_map[key]] = value.strip()

    return body, meta


def _strip_legacy_plan_footer(content: str) -> str:
    return re.sub(
        r"\n---\n\*Plan source: Free plan\.\*\s*$",
        "",
        content.rstrip(),
    )


def _public_meta(meta: dict) -> dict[str, str]:
    keys = [
        "stamp_type",
        "version",
        "algorithm",
        "export_id",
        "generated_at",
        "plan_label",
        "format",
        "payload_sha256",
        "signature",
    ]
    return {key: str(meta[key]) for key in keys if key in meta}


def _invalid_verify_result(format_name: str, reason: str) -> dict:
    return {
        "valid": False,
        "signature_valid": False,
        "payload_changed": False,
        "is_testpilot_free_export": False,
        "format": format_name,
        "reason": reason,
        "export_meta": None,
    }


def _deepcopy_json(value: Any) -> Any:
    return json.loads(json.dumps(value, ensure_ascii=False))


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
