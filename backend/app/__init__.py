from flask import Flask, jsonify
from flask_cors import CORS
from werkzeug.exceptions import HTTPException

from .config import Config
from .db import close_db, init_app as init_db_app
from .routes.health import health_bp
from .routes.market import market_bp
from .services.cache_service import CacheService
from .services.market_data_service import MarketDataService


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

    cache_service = CacheService()
    market_service = MarketDataService(
        cache_service=cache_service,
        provider_name=app.config["MARKET_DATA_PROVIDER"],
    )
    app.extensions["market_service"] = market_service

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
                    "message": "Internal server error",
                    "error": {
                        "code": "INTERNAL_SERVER_ERROR",
                        "statusCode": 500,
                    },
                }
            ),
            500,
        )

    return app
