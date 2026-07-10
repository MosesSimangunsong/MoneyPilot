from __future__ import annotations

from datetime import datetime, timezone

from flask import Blueprint, current_app, jsonify, request

from ..services.ai_analysis_service import AnalysisServiceError

news_bp = Blueprint("news", __name__)


def _server_time() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _success(data, status_code: int = 200):
    return jsonify({"status": "success", "data": data, "serverTime": _server_time()}), status_code


def _error(message: str, code: str, status_code: int):
    return (
        jsonify(
            {
                "status": "error",
                "message": message,
                "error": {"code": code, "statusCode": status_code},
                "serverTime": _server_time(),
            }
        ),
        status_code,
    )


def _news_service():
    return current_app.extensions["news_service"]


def _analysis_service():
    return current_app.extensions["analysis_service"]


@news_bp.get("")
def get_news():
    category = request.args.get("category")
    query = request.args.get("q")
    raw_limit = request.args.get("limit", "10").strip()
    try:
        limit = int(raw_limit)
    except ValueError:
        return _error("Query param 'limit' harus berupa angka.", "INVALID_LIMIT", 400)

    if limit <= 0 or limit > 20:
        return _error(
            "Query param 'limit' harus di antara 1 sampai 20.",
            "INVALID_LIMIT",
            400,
        )

    articles = _news_service().get_news(category=category, query=query, limit=limit)
    return _success(articles)


@news_bp.get("/<article_id>")
def get_news_detail(article_id: str):
    article = _news_service().get_news_detail(article_id)
    if article is None:
        return _error("Berita tidak ditemukan di cache backend.", "NEWS_NOT_FOUND", 404)
    return _success(article)


@news_bp.post("/analyze")
def analyze_news():
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return _error(
            "Request body harus berupa JSON object.",
            "INVALID_REQUEST_BODY",
            400,
        )

    try:
        analysis = _analysis_service().analyze(payload)
    except AnalysisServiceError as error:
        return _error(error.message, error.code, error.status_code)

    return _success(analysis)
