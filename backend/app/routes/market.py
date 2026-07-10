from flask import Blueprint, abort, current_app, jsonify, request

market_bp = Blueprint("market", __name__)


def _market_service():
    return current_app.extensions["market_service"]


@market_bp.get("/quote/<symbol>")
def get_quote(symbol: str):
    quote = _market_service().get_quote(symbol)
    return jsonify({"status": "success", "data": quote})


@market_bp.post("/quotes")
def get_quotes():
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        abort(400, description="Request body must be a JSON object.")

    symbols = payload.get("symbols")
    if not isinstance(symbols, list) or not symbols:
        abort(400, description="Field 'symbols' must be a non-empty list.")
    if not all(isinstance(symbol, str) and symbol.strip() for symbol in symbols):
        abort(400, description="Every symbol must be a non-empty string.")

    quotes = _market_service().get_quotes(symbols)
    return jsonify({"status": "success", "data": quotes})
