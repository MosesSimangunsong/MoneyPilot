import os
from pathlib import Path


class Config:
    BASE_DIR = Path(__file__).resolve().parents[1]
    DEBUG = os.getenv("FLASK_DEBUG", "0") == "1"
    TESTING = os.getenv("FLASK_TESTING", "0") == "1"
    BACKEND_HOST = os.getenv("BACKEND_HOST", "127.0.0.1")
    BACKEND_PORT = int(os.getenv("BACKEND_PORT", "5000"))
    MARKET_DATA_PROVIDER = os.getenv("MARKET_DATA_PROVIDER", "MOCK").upper()
    MARKET_CACHE_TTL_SECONDS = int(os.getenv("MARKET_CACHE_TTL_SECONDS", "900"))
    MARKET_CACHE_DB_PATH = os.getenv(
        "MARKET_CACHE_DB_PATH",
        str(BASE_DIR / "data" / "market_cache.db"),
    )
    CORS_ORIGINS = [
        origin.strip()
        for origin in os.getenv("CORS_ORIGINS", "*").split(",")
        if origin.strip()
    ]
