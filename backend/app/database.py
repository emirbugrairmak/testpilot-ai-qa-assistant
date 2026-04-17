"""
TestPilot – SQLite Database
============================
Veritabanı başlatma, bağlantı yönetimi ve seed data.
"""

import os
import sqlite3
from contextlib import contextmanager
from datetime import datetime

from app.config import settings

# ── SQL Schema ──────────────────────────────────────────

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS api_keys (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    key             TEXT    UNIQUE NOT NULL,
    plan            TEXT    NOT NULL DEFAULT 'free' CHECK(plan IN ('free', 'premium')),
    owner_name      TEXT    DEFAULT '',
    is_active       INTEGER NOT NULL DEFAULT 1,
    monthly_limit   INTEGER NOT NULL DEFAULT 30,
    usage_count     INTEGER NOT NULL DEFAULT 0,
    usage_reset_at  TEXT    NOT NULL,
    created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS generations (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    api_key_id      INTEGER NOT NULL,
    mode            TEXT    NOT NULL CHECK(mode IN ('mod_a', 'mod_b')),
    input_json      TEXT    NOT NULL,
    output_json     TEXT    NOT NULL,
    output_md       TEXT    NOT NULL DEFAULT '',
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (api_key_id) REFERENCES api_keys(id)
);

CREATE TABLE IF NOT EXISTS custom_templates (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    api_key_id      INTEGER NOT NULL,
    name            TEXT    NOT NULL,
    template_json   TEXT    NOT NULL DEFAULT '{}',
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (api_key_id) REFERENCES api_keys(id)
);
"""

# ── Seed Data ───────────────────────────────────────────

SEED_KEYS = [
    ("tp_free_demo_key", "free", "Demo Free User", 30),
    ("tp_premium_demo_key", "premium", "Demo Premium User", 200),
]


def _next_month_reset() -> str:
    """Bir sonraki ayın 1'i için ISO tarih döndür."""
    now = datetime.utcnow()
    if now.month == 12:
        return datetime(now.year + 1, 1, 1).isoformat()
    return datetime(now.year, now.month + 1, 1).isoformat()


# ── Connection Management ──────────────────────────────

def _get_db_path() -> str:
    """Veritabanı dosyasının mutlak yolunu döndür."""
    return settings.DATABASE_PATH


@contextmanager
def get_db():
    """SQLite bağlantısı sağlayan context manager.

    - Row factory aktif (dict-like erişim)
    - WAL mode (eşzamanlı okuma/yazma)
    - Foreign key constraint aktif
    """
    conn = sqlite3.connect(_get_db_path())
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ── Initialization ─────────────────────────────────────

def _seed_api_keys(conn: sqlite3.Connection) -> None:
    """Demo API key'lerini ekle (yoksa)."""
    reset_at = _next_month_reset()
    for key, plan, owner, limit in SEED_KEYS:
        conn.execute(
            """INSERT OR IGNORE INTO api_keys
               (key, plan, owner_name, monthly_limit, usage_count, usage_reset_at)
               VALUES (?, ?, ?, ?, 0, ?)""",
            (key, plan, owner, limit, reset_at),
        )


def init_db() -> None:
    """Tabloları oluştur ve seed data ekle.

    Uygulama başlangıcında (lifespan) bir kez çağrılır.
    """
    db_path = _get_db_path()
    db_dir = os.path.dirname(db_path)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)

    with get_db() as conn:
        conn.executescript(SCHEMA_SQL)
        _seed_api_keys(conn)
        conn.commit()

    print(f"✅ Database initialized: {db_path}")
