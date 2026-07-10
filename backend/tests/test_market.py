from datetime import datetime, timedelta, timezone

from flask import current_app

from app.services.cache_service import CacheService


def test_quote_endpoint_returns_valid_json(client):
    response = client.get("/api/market/quote/BBCA.JK")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    assert payload["data"]["symbol"] == "BBCA.JK"
    assert payload["data"]["currency"] == "IDR"
    assert payload["data"]["source"] == "mock"
    assert payload["data"]["isStale"] is False


def test_batch_quote_endpoint_accepts_symbol_list(client):
    response = client.post(
        "/api/market/quotes",
        json={"symbols": ["BBCA.JK", "BMRI.JK"]},
    )

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    assert len(payload["data"]) == 2
    assert {item["symbol"] for item in payload["data"]} == {"BBCA.JK", "BMRI.JK"}


def test_unknown_symbol_returns_json_error(client):
    response = client.get("/api/market/quote/XXXX.JK")

    assert response.status_code == 404
    payload = response.get_json()
    assert payload["status"] == "error"
    assert payload["error"]["statusCode"] == 404
    assert payload["message"] == "Market quote for symbol 'XXXX.JK' was not found."


def test_cache_service_can_store_and_read_quote(app):
    with app.app_context():
        service = CacheService()
        quote = {
            "symbol": "BBCA.JK",
            "price": 9050.0,
            "currency": "IDR",
            "source": "mock",
            "asOf": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        }

        service.upsert_quote(quote)
        cached = service.get_valid_quote("BBCA.JK")

        assert cached is not None
        assert cached["symbol"] == "BBCA.JK"
        assert cached["price"] == 9050.0


def test_expired_cache_fetches_new_provider_data(app, client):
    with app.app_context():
        service = CacheService()
        expired_time = datetime.now(timezone.utc) - timedelta(
            seconds=current_app.config["MARKET_CACHE_TTL_SECONDS"] + 10
        )
        service.upsert_quote(
            {
                "symbol": "BBCA.JK",
                "price": 1.0,
                "currency": "IDR",
                "source": "mock",
                "asOf": expired_time.isoformat().replace("+00:00", "Z"),
            }
        )

    response = client.get("/api/market/quote/BBCA.JK")
    payload = response.get_json()

    assert response.status_code == 200
    assert payload["data"]["price"] == 9050.0
    assert payload["data"]["isStale"] is False


def test_invalid_batch_request_returns_json_error(client):
    response = client.post("/api/market/quotes", json={"symbols": []})

    assert response.status_code == 400
    payload = response.get_json()
    assert payload["status"] == "error"
    assert payload["error"]["statusCode"] == 400
