"""
TestPilot - Text Formatting Helpers
===================================
Export ve preview metinlerinde tekrar eden liste marker'larını temizler.
"""

from __future__ import annotations

import re
from typing import Any


_LEADING_MARKERS_RE = re.compile(r"^\s*(?:(?:[-*•]\s+)|(?:\d+[\.)]\s+))+")
_ORDERED_LINE_RE = re.compile(r"^(\s*\d+[\.)]\s+)(.+)$")
_BULLET_LINE_RE = re.compile(r"^(\s*[-*]\s+)(.+)$")


def clean_list_item(value: Any) -> str:
    """Liste içinde gösterilecek metnin başındaki numara/bullet tekrarlarını temizle."""
    text = " ".join(str(value or "").split())
    previous = None
    while previous != text:
        previous = text
        text = _LEADING_MARKERS_RE.sub("", text).strip()
    return text


def clean_list_items(values: list[Any] | tuple[Any, ...] | None) -> list[str]:
    """Liste elemanlarını temizle ve boşları at."""
    return [item for item in (clean_list_item(value) for value in values or []) if item]


def clean_markdown_list_markers(content: str) -> str:
    """Markdown liste satırlarındaki `1. 1.` ve `- -` tekrarlarını temizle."""
    cleaned_lines = []
    for line in str(content or "").splitlines():
        ordered = _ORDERED_LINE_RE.match(line)
        if ordered:
            cleaned_lines.append(f"{ordered.group(1)}{clean_list_item(ordered.group(2))}")
            continue

        bullet = _BULLET_LINE_RE.match(line)
        if bullet:
            cleaned_lines.append(f"{bullet.group(1)}{clean_list_item(bullet.group(2))}")
            continue

        cleaned_lines.append(line)

    return "\n".join(cleaned_lines)
