import sys
from pathlib import Path

import pytest

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app import create_app
from app.config import Config
from app.db import init_db


class TestConfig(Config):
    TESTING = True
    MARKET_CACHE_TTL_SECONDS = 60


@pytest.fixture
def app(tmp_path: Path):
    class TempConfig(TestConfig):
        MARKET_CACHE_DB_PATH = str(tmp_path / "test_market_cache.db")

    app = create_app(TempConfig)
    with app.app_context():
        init_db()
    yield app


@pytest.fixture
def client(app):
    return app.test_client()
