import sqlite3
from pathlib import Path

from flask import current_app, g

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS market_cache (
    symbol TEXT PRIMARY KEY,
    price REAL NOT NULL,
    currency TEXT NOT NULL,
    source TEXT NOT NULL,
    as_of TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
"""


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
    db.commit()


def init_app(app) -> None:
    @app.before_request
    def ensure_db_ready() -> None:
        init_db()
