"""Legacy generation output normalization helpers."""

from __future__ import annotations

import copy
import re
from typing import Any


def normalize_bug_severity(value: object) -> tuple[str, str]:
    """UI severity seçimini Türkçe gösterim ve priority değerine çevir."""
    normalized = str(value or "").strip().lower()
    normalized = {
        "critical": "kritik",
        "blocker": "kritik",
        "kritik": "kritik",
        "high": "yüksek",
        "major": "yüksek",
        "yüksek": "yüksek",
        "yuksek": "yüksek",
        "medium": "orta",
        "minor": "orta",
        "orta": "orta",
        "low": "düşük",
        "trivial": "düşük",
        "düşük": "düşük",
        "dusuk": "düşük",
    }.get(normalized, "orta")

    display = {
        "kritik": "Kritik",
        "yüksek": "Yüksek",
        "orta": "Orta",
        "düşük": "Düşük",
    }[normalized]
    priority = {
        "kritik": "P0",
        "yüksek": "P1",
        "orta": "P2",
        "düşük": "P3",
    }[normalized]
    return display, priority


def normalize_bug_labels(labels: list[str], severity: str) -> list[str]:
    severity_labels = {
        "critical",
        "blocker",
        "kritik",
        "high",
        "major",
        "yüksek",
        "yuksek",
        "medium",
        "minor",
        "orta",
        "low",
        "trivial",
        "düşük",
        "dusuk",
    }
    cleaned = [
        label
        for label in labels
        if label.strip().lower() not in severity_labels
    ]
    severity_label = severity.lower()
    if severity_label not in {label.strip().lower() for label in cleaned}:
        cleaned.append(severity_label)
    return cleaned


def normalize_generation_output(output: dict, input_payload: dict | None = None) -> dict:
    """Eski kayıtları API/export response seviyesinde yeni gösterime uyarla."""
    normalized = copy.deepcopy(output)
    if normalized.get("mode") != "bug_report":
        return normalized

    bug = normalized.get("bug_report")
    if not isinstance(bug, dict):
        return normalized

    severity, priority = normalize_bug_severity(
        (input_payload or {}).get("severity") or bug.get("severity")
    )
    labels = [
        str(label)
        for label in bug.get("labels", ["bug", "qa-generated"])
    ]
    bug["severity"] = severity
    bug["priority"] = priority
    bug["labels"] = normalize_bug_labels(labels, severity)
    normalized["tags"] = bug["labels"]
    return normalized


def clean_legacy_markdown(content: Any, output: dict | None = None) -> str:
    """Saklanmış eski markdown içindeki teknik metadata satırlarını temizle."""
    lines = []
    for line in str(content or "").splitlines():
        if re.match(r"^\*\*(Mode|AI Provider|Generated):\*\*.*$", line.strip()):
            continue
        lines.append(line)

    cleaned = "\n".join(lines).strip()
    bug = (output or {}).get("bug_report") or {}
    if bug:
        cleaned = re.sub(
            r"^\*\*Severity:\*\*.*$",
            f"**Severity:** {bug.get('severity', '')}",
            cleaned,
            flags=re.MULTILINE,
        )
        cleaned = re.sub(
            r"^\*\*Priority:\*\*.*$",
            f"**Priority:** {bug.get('priority', '')}",
            cleaned,
            flags=re.MULTILINE,
        )

    return cleaned
