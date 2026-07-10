from datetime import datetime, timedelta, timezone

from flask import abort


class MockMarketDataProvider:
    def __init__(self) -> None:
        as_of = datetime.now(timezone.utc).replace(microsecond=0)
        as_of_text = as_of.isoformat().replace("+00:00", "Z")
        self._quotes = {
            "BBCA.JK": {
                "symbol": "BBCA.JK",
                "price": 9050.0,
                "currency": "IDR",
                "source": "mock",
                "asOf": as_of_text,
            },
            "BMRI.JK": {
                "symbol": "BMRI.JK",
                "price": 6325.0,
                "currency": "IDR",
                "source": "mock",
                "asOf": (as_of - timedelta(minutes=1)).isoformat().replace(
                    "+00:00", "Z"
                ),
            },
            "BBRI.JK": {
                "symbol": "BBRI.JK",
                "price": 4875.0,
                "currency": "IDR",
                "source": "mock",
                "asOf": (as_of - timedelta(minutes=2)).isoformat().replace(
                    "+00:00", "Z"
                ),
            },
            "TLKM.JK": {
                "symbol": "TLKM.JK",
                "price": 3210.0,
                "currency": "IDR",
                "source": "mock",
                "asOf": (as_of - timedelta(minutes=3)).isoformat().replace(
                    "+00:00", "Z"
                ),
            },
            "ASII.JK": {
                "symbol": "ASII.JK",
                "price": 4725.0,
                "currency": "IDR",
                "source": "mock",
                "asOf": (as_of - timedelta(minutes=4)).isoformat().replace(
                    "+00:00", "Z"
                ),
            },
        }

    def get_quote(self, symbol: str) -> dict:
        normalized_symbol = symbol.strip().upper()
        if normalized_symbol not in self._quotes:
            abort(404, description=f"Market quote for symbol '{normalized_symbol}' was not found.")
        return self._quotes[normalized_symbol]


class MarketDataService:
    def __init__(self, cache_service, provider_name: str = "MOCK") -> None:
        self._cache_service = cache_service
        self._provider = self._build_provider(provider_name)

    def get_quote(self, symbol: str) -> dict:
        normalized_symbol = symbol.strip().upper()
        cached = self._cache_service.get_valid_quote(normalized_symbol)
        if cached is not None:
            return cached

        fresh_quote = self._provider.get_quote(normalized_symbol)
        return self._cache_service.upsert_quote(fresh_quote)

    def get_quotes(self, symbols: list[str]) -> list[dict]:
        return [self.get_quote(symbol) for symbol in symbols]

    def _build_provider(self, provider_name: str):
        normalized_name = provider_name.strip().upper()
        if normalized_name == "MOCK":
            return MockMarketDataProvider()
        abort(500, description=f"Unsupported market data provider '{normalized_name}'.")
