from flask import Flask, jsonify
from flask_cors import CORS
from werkzeug.exceptions import HTTPException

from .config import Config
from .db import close_db, init_app as init_db_app
from .routes.health import health_bp
from .routes.market import market_bp
from .routes.news import news_bp
from .services.ai_analysis_service import AIAnalysisService
from .services.cache_service import CacheService
from .services.google_news_service import GoogleNewsService
from .services.market_data_service import MarketDataService
from .services.market_data_provider import MarketDataProviderError
from .services.prompt_builder import PromptBuilder


def create_app(config_object: type[Config] = Config) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config_object)

    CORS(
        app,
        resources={r"/api/*": {"origins": app.config["CORS_ORIGINS"]}},
    )

    init_db_app(app)
    app.teardown_appcontext(close_db)
    app.register_blueprint(health_bp)
    app.register_blueprint(market_bp, url_prefix="/api/market")
    app.register_blueprint(news_bp, url_prefix="/api/news")

    cache_service = CacheService()
    market_service = MarketDataService(
        cache_service=cache_service,
        provider_name=app.config["MARKET_DATA_PROVIDER"],
        api_key=app.config["MARKET_DATA_API_KEY"],
        base_url=app.config["MARKET_DATA_BASE_URL"],
        timeout_seconds=app.config["MARKET_REQUEST_TIMEOUT_SECONDS"],
        cache_ttl_seconds=app.config["MARKET_CACHE_TTL_SECONDS"],
        enable_mock_fallback=app.config["ENABLE_MARKET_MOCK_FALLBACK"],
    )
    news_service = GoogleNewsService(
        cache_service=cache_service,
        provider_name=app.config["NEWS_PROVIDER"],
        enable_dev_fallback=app.config["DEBUG"]
        or app.config["TESTING"]
        or app.config["ENABLE_DEV_ANALYSIS_FALLBACK"],
    )
    analysis_service = AIAnalysisService(
        cache_service=cache_service,
        prompt_builder=PromptBuilder(),
        provider_name=app.config["AI_PROVIDER"],
        openai_api_key=app.config["OPENAI_API_KEY"],
        model_name=app.config["AI_MODEL"],
        enable_dev_fallback=app.config["DEBUG"]
        or app.config["TESTING"]
        or app.config["ENABLE_DEV_ANALYSIS_FALLBACK"],
    )
    app.extensions["market_service"] = market_service
    app.extensions["news_service"] = news_service
    app.extensions["analysis_service"] = analysis_service

    @app.errorhandler(MarketDataProviderError)
    def handle_market_provider_error(error: MarketDataProviderError):
        return (
            jsonify(
                {
                    "status": "error",
                    "error": {
                        "code": error.code,
                        "statusCode": error.status_code,
                    },
                    "message": error.message,
                }
            ),
            error.status_code,
        )

    @app.errorhandler(HTTPException)
    def handle_http_exception(error: HTTPException):
        response = error.get_response()
        response.data = jsonify(
            {
                "status": "error",
                "message": error.description,
                "error": {
                    "code": error.name.upper().replace(" ", "_"),
                    "statusCode": error.code,
                },
            }
        ).get_data()
        response.content_type = "application/json"
        return response

    @app.errorhandler(Exception)
    def handle_unexpected_error(error: Exception):
        app.logger.exception("Unexpected backend error", exc_info=error)
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Terjadi kesalahan internal pada server.",
                    "error": {
                        "code": "INTERNAL_SERVER_ERROR",
                        "statusCode": 500,
                    },
                }
            ),
            500,
        )

    return app
