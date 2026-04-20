"""
TestPilot – Veritabanı Modelleri
=================================
SQLite tabloları için Python dataclass karşılıkları.
ORM kullanılmıyor — sadece tip güvenliği ve kod okunabilirliği için.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class ApiKey:
    """api_keys tablosuna karşılık gelen model."""
    id: int
    key: str
    plan: str                           # "free" | "premium"
    owner_name: str
    is_active: bool
    monthly_limit: int
    usage_count: int
    usage_reset_at: str                 # ISO datetime string
    created_at: str                     # ISO datetime string

    @classmethod
    def from_row(cls, row) -> ApiKey:
        """sqlite3.Row → ApiKey dönüşümü."""
        return cls(**dict(row))


@dataclass
class Generation:
    """generations tablosuna karşılık gelen model."""
    id: int
    api_key_id: int
    mode: str                           # "mod_a" | "mod_b" | "bug_report"
    input_json: str
    output_json: str
    output_md: str
    created_at: str

    @classmethod
    def from_row(cls, row) -> Generation:
        """sqlite3.Row → Generation dönüşümü."""
        return cls(**dict(row))


@dataclass
class CustomTemplate:
    """custom_templates tablosuna karşılık gelen model (ileride kullanılacak)."""
    id: int
    api_key_id: int
    name: str
    template_json: str
    created_at: str

    @classmethod
    def from_row(cls, row) -> CustomTemplate:
        """sqlite3.Row → CustomTemplate dönüşümü."""
        return cls(**dict(row))
