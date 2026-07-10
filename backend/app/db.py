import sqlite3
from pathlib import Path

from flask import current_app, g

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS market_cache (
    symbol TEXT PRIMARY KEY,
    display_symbol TEXT NOT NULL DEFAULT '',
    price REAL NOT NULL,
    currency TEXT NOT NULL,
    source TEXT NOT NULL,
    provider TEXT NOT NULL DEFAULT '',
    is_mock INTEGER NOT NULL DEFAULT 0,
    is_fallback INTEGER NOT NULL DEFAULT 0,
    as_of TEXT NOT NULL,
    message TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS news_feed_cache (
    cache_key TEXT PRIMARY KEY,
    response_json TEXT NOT NULL,
    fetched_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS news_article_cache (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    source TEXT NOT NULL,
    url TEXT NOT NULL,
    category TEXT NOT NULL,
    published_at TEXT NOT NULL,
    fetched_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS analysis_cache (
    cache_key TEXT PRIMARY KEY,
    news_id TEXT NOT NULL,
    response_json TEXT NOT NULL,
    provider TEXT NOT NULL,
    model TEXT NOT NULL,
    generated_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
"""

MARKET_CACHE_REQUIRED_COLUMNS = {
    "symbol": "TEXT PRIMARY KEY",
    "display_symbol": "TEXT NOT NULL DEFAULT ''",
    "price": "REAL NOT NULL",
    "currency": "TEXT NOT NULL",
    "source": "TEXT NOT NULL",
    "provider": "TEXT NOT NULL DEFAULT ''",
    "is_mock": "INTEGER NOT NULL DEFAULT 0",
    "is_fallback": "INTEGER NOT NULL DEFAULT 0",
    "as_of": "TEXT NOT NULL",
    "message": "TEXT NOT NULL DEFAULT ''",
    "created_at": "TEXT NOT NULL",
    "updated_at": "TEXT NOT NULL",
}


def get_db() -> sqlite3.Connection:
    if "db" not in g:
        db_path = Path(current_app.config["MARKET_CACHE_DB_PATH"])
        db_path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(db_path)
        connection.row_factory = sqlite3.Row
        g.db = connection
    return g.db


def close_db(_error=None) -> None:
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db() -> None:
    db = get_db()
    db.executescript(SCHEMA_SQL)
    existing_columns = {
        row["name"]
        for row in db.execute("PRAGMA table_info(market_cache)").fetchall()
    }
    for column_name, column_sql in MARKET_CACHE_REQUIRED_COLUMNS.items():
        if column_name in existing_columns:
            continue
        db.execute(f"ALTER TABLE market_cache ADD COLUMN {column_name} {column_sql}")
    db.commit()


def init_app(app) -> None:
    @app.before_request
    def ensure_db_ready() -> None:
        init_db()
