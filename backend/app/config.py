import os
from pathlib import Path


def _load_env_file() -> None:
    env_path = Path(__file__).resolve().parents[1] / ".env"
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


_load_env_file()


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
    NEWS_PROVIDER = os.getenv("NEWS_PROVIDER", "google_news_rss").lower()
    NEWS_CACHE_TTL_SECONDS = int(os.getenv("NEWS_CACHE_TTL_SECONDS", "900"))
    ANALYSIS_CACHE_TTL_SECONDS = int(
        os.getenv("ANALYSIS_CACHE_TTL_SECONDS", "86400")
    )
    AI_PROVIDER = os.getenv("AI_PROVIDER", "openai").lower()
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
    AI_MODEL = os.getenv("AI_MODEL", "").strip() or "gpt-4.1-mini"
    ENABLE_DEV_ANALYSIS_FALLBACK = (
        os.getenv("ENABLE_DEV_ANALYSIS_FALLBACK", "1") == "1"
    )
    CORS_ORIGINS = [
        origin.strip()
        for origin in os.getenv("CORS_ORIGINS", "*").split(",")
        if origin.strip()
    ]
