from datetime import datetime, timedelta, timezone

from app.services.cache_service import CacheService
from app.services.market_data_provider import (
    MarketDataProvider,
    MarketDataProviderError,
    ProviderQuote,
    normalize_market_symbol,
    utc_now_text,
)
from app.services.market_data_service import MarketDataService


class CountingProvider(MarketDataProvider):
    provider_label = "CountingProvider"
    source_name = "counting"

    def __init__(self) -> None:
        self.calls = 0

    def get_quote(self, symbol: str) -> ProviderQuote:
        self.calls += 1
        return ProviderQuote(
            symbol=normalize_market_symbol(symbol),
            display_symbol="BBCA",
            price=9100.0,
            currency="IDR",
            source=self.source_name,
            provider=self.provider_label,
            is_mock=False,
            as_of=utc_now_text(),
        )


class TimeoutProvider(MarketDataProvider):
    provider_label = "TimeoutProvider"
    source_name = "timeout"

    def get_quote(self, symbol: str) -> ProviderQuote:
        raise MarketDataProviderError(
            message="Data pasar belum tersedia. Coba lagi nanti.",
            code="MARKET_PROVIDER_UNAVAILABLE",
            status_code=503,
        )


def test_normalize_idx_symbol_adds_jk_suffix():
    assert normalize_market_symbol("BBCA") == "BBCA.JK"


def test_normalize_idx_symbol_keeps_existing_suffix():
    assert normalize_market_symbol("BBCA.JK") == "BBCA.JK"


def test_quote_endpoint_returns_valid_json(client):
    response = client.get("/api/market/quote/BBCA")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    assert payload["data"]["symbol"] == "BBCA.JK"
    assert payload["data"]["displaySymbol"] == "BBCA"
    assert payload["data"]["currency"] == "IDR"
    assert payload["data"]["source"] == "mock"
    assert payload["data"]["provider"] == "MockMarketDataProvider"
    assert payload["data"]["isMock"] is True
    assert payload["data"]["isFallback"] is False
    assert payload["data"]["isStale"] is False
    assert payload["data"]["message"] == (
        "Data pasar bersifat estimasi dan bukan rekomendasi investasi."
    )


def test_batch_quote_endpoint_accepts_symbol_list(client):
    response = client.post(
        "/api/market/quotes",
        json={"symbols": ["BBCA", "BMRI.JK"]},
    )

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    assert payload["data"]["count"] == 2
    assert payload["data"]["errors"] == []
    assert {item["symbol"] for item in payload["data"]["quotes"]} == {
        "BBCA.JK",
        "BMRI.JK",
    }


def test_unknown_symbol_returns_json_error(client):
    response = client.get("/api/market/quote/XXXX.JK")

    assert response.status_code == 404
    payload = response.get_json()
    assert payload["status"] == "error"
    assert payload["error"]["statusCode"] == 404
    assert payload["error"]["code"] == "MARKET_SYMBOL_NOT_FOUND"
    assert payload["message"] == "Market quote for symbol 'XXXX.JK' was not found."


def test_cache_service_can_store_and_read_quote(app):
    with app.app_context():
        service = CacheService()
        quote = {
            "symbol": "BBCA.JK",
            "displaySymbol": "BBCA",
            "price": 9050.0,
            "currency": "IDR",
            "source": "mock",
            "provider": "MockMarketDataProvider",
            "isMock": True,
            "isFallback": False,
            "asOf": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "message": "Data pasar bersifat estimasi dan bukan rekomendasi investasi.",
        }

        service.upsert_quote(quote)
        cached = service.get_valid_quote("BBCA")

        assert cached is not None
        assert cached["symbol"] == "BBCA.JK"
        assert cached["displaySymbol"] == "BBCA"
        assert cached["price"] == 9050.0
        assert cached["cachedAt"] is not None


def test_expired_cache_fetches_new_provider_data(app):
    with app.app_context():
        cache_service = CacheService()
        expired_time = datetime.now(timezone.utc) - timedelta(
            seconds=app.config["MARKET_CACHE_TTL_SECONDS"] + 10
        )
        cache_service.upsert_quote(
            {
                "symbol": "BBCA.JK",
                "displaySymbol": "BBCA",
                "price": 1.0,
                "currency": "IDR",
                "source": "mock",
                "provider": "MockMarketDataProvider",
                "isMock": True,
                "isFallback": False,
                "asOf": expired_time.isoformat().replace("+00:00", "Z"),
                "message": "Data pasar bersifat estimasi dan bukan rekomendasi investasi.",
            }
        )
        service = MarketDataService(cache_service=cache_service)

        quote = service.get_quote("BBCA")

        assert quote["price"] == 9050.0
        assert quote["isStale"] is False
        assert quote["symbol"] == "BBCA.JK"


def test_cache_hit_avoids_second_provider_call(app):
    with app.app_context():
        provider = CountingProvider()
        service = MarketDataService(
            cache_service=CacheService(),
            primary_provider=provider,
            provider_name="mock",
        )

        first = service.get_quote("BBCA")
        second = service.get_quote("BBCA.JK")

        assert first["price"] == 9100.0
        assert second["price"] == 9100.0
        assert provider.calls == 1


def test_provider_timeout_uses_mock_fallback_when_enabled(app):
    with app.app_context():
        service = MarketDataService(
            cache_service=CacheService(),
            provider_name="eodhd",
            primary_provider=TimeoutProvider(),
            enable_mock_fallback=True,
        )

        quote = service.get_quote("BBCA")

        assert quote["symbol"] == "BBCA.JK"
        assert quote["source"] == "mock"
        assert quote["isMock"] is True
        assert quote["isFallback"] is True


def test_provider_timeout_returns_json_error_when_fallback_disabled(app, client):
    with app.app_context():
        app.extensions["market_service"] = MarketDataService(
            cache_service=CacheService(),
            provider_name="eodhd",
            primary_provider=TimeoutProvider(),
            enable_mock_fallback=False,
        )

    response = client.get("/api/market/quote/BBCA")

    assert response.status_code == 503
    payload = response.get_json()
    assert payload["status"] == "error"
    assert payload["error"]["code"] == "MARKET_PROVIDER_UNAVAILABLE"
    assert payload["message"] == "Data pasar belum tersedia. Coba lagi nanti."


def test_quote_response_does_not_contain_api_key(client):
    response = client.get("/api/market/quote/BBCA")

    payload = response.get_json()
    assert "MARKET_DATA_API_KEY" not in str(payload)
    assert "api_token" not in str(payload)


def test_invalid_batch_request_returns_json_error(client):
    response = client.post("/api/market/quotes", json={"symbols": []})

    assert response.status_code == 400
    payload = response.get_json()
    assert payload["status"] == "error"
    assert payload["error"]["statusCode"] == 400
