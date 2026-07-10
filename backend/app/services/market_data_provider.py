import json
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any
from urllib import error, parse, request


MARKET_DATA_DISCLAIMER = (
    "Data pasar bersifat estimasi dan bukan rekomendasi investasi."
)


def utc_now_text() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace(
        "+00:00",
        "Z",
    )


def normalize_market_symbol(symbol: str, market: str = "IDX") -> str:
    normalized_symbol = symbol.strip().upper()
    normalized_market = market.strip().upper()
    if not normalized_symbol:
        return normalized_symbol
    if "." in normalized_symbol:
        return normalized_symbol
    if normalized_market == "IDX":
        return f"{normalized_symbol}.JK"
    return normalized_symbol


def display_market_symbol(symbol: str) -> str:
    normalized_symbol = normalize_market_symbol(symbol)
    if normalized_symbol.endswith(".JK"):
        return normalized_symbol[:-3]
    return normalized_symbol


class MarketDataProviderError(Exception):
    def __init__(
        self,
        *,
        message: str,
        code: str = "MARKET_PROVIDER_UNAVAILABLE",
        status_code: int = 503,
    ) -> None:
        super().__init__(message)
        self.message = message
        self.code = code
        self.status_code = status_code


@dataclass(frozen=True)
class ProviderQuote:
    symbol: str
    display_symbol: str
    price: float
    currency: str
    source: str
    provider: str
    is_mock: bool
    as_of: str
    message: str = MARKET_DATA_DISCLAIMER

    def to_payload(
        self,
        *,
        is_fallback: bool,
        is_stale: bool,
        cached_at: str | None,
        cache_ttl_seconds: int,
    ) -> dict[str, Any]:
        return {
            "symbol": self.symbol,
            "displaySymbol": self.display_symbol,
            "price": self.price,
            "currency": self.currency,
            "source": self.source,
            "provider": self.provider,
            "isMock": self.is_mock,
            "isFallback": is_fallback,
            "isStale": is_stale,
            "asOf": self.as_of,
            "cachedAt": cached_at,
            "cacheTtlSeconds": cache_ttl_seconds,
            "message": self.message,
        }


class MarketDataProvider:
    provider_label = "MarketDataProvider"
    source_name = "unknown"

    def get_quote(self, symbol: str) -> ProviderQuote:
        raise NotImplementedError


class MockMarketDataProvider(MarketDataProvider):
    provider_label = "MockMarketDataProvider"
    source_name = "mock"

    def __init__(self) -> None:
        as_of = datetime.now(timezone.utc).replace(microsecond=0)
        self._quotes = {
            "BBCA.JK": 9050.0,
            "BMRI.JK": 6325.0,
            "BBRI.JK": 4875.0,
            "TLKM.JK": 3210.0,
            "ASII.JK": 4725.0,
        }
        self._as_of_by_symbol = {
            symbol: (as_of - timedelta(minutes=index)).isoformat().replace(
                "+00:00",
                "Z",
            )
            for index, symbol in enumerate(self._quotes.keys())
        }

    def get_quote(self, symbol: str) -> ProviderQuote:
        normalized_symbol = normalize_market_symbol(symbol)
        if normalized_symbol not in self._quotes:
            raise MarketDataProviderError(
                message=f"Market quote for symbol '{normalized_symbol}' was not found.",
                code="MARKET_SYMBOL_NOT_FOUND",
                status_code=404,
            )

        return ProviderQuote(
            symbol=normalized_symbol,
            display_symbol=display_market_symbol(normalized_symbol),
            price=self._quotes[normalized_symbol],
            currency="IDR",
            source=self.source_name,
            provider=self.provider_label,
            is_mock=True,
            as_of=self._as_of_by_symbol[normalized_symbol],
        )


class EodhdMarketDataProvider(MarketDataProvider):
    provider_label = "EODHD"
    source_name = "eodhd"

    def __init__(
        self,
        *,
        api_key: str,
        base_url: str,
        timeout_seconds: int,
    ) -> None:
        self._api_key = api_key.strip()
        self._base_url = base_url.rstrip("/")
        self._timeout_seconds = timeout_seconds
        if not self._api_key:
            raise MarketDataProviderError(
                message="Provider market eksternal memerlukan MARKET_DATA_API_KEY.",
                code="MARKET_PROVIDER_MISCONFIGURED",
                status_code=500,
            )

    def get_quote(self, symbol: str) -> ProviderQuote:
        normalized_symbol = normalize_market_symbol(symbol)
        params = parse.urlencode({"api_token": self._api_key, "fmt": "json"})
        url = f"{self._base_url}/{normalized_symbol}?{params}"

        try:
            with request.urlopen(url, timeout=self._timeout_seconds) as response:
                body = response.read().decode("utf-8")
        except error.HTTPError as exc:
            if exc.code == 404:
                raise MarketDataProviderError(
                    message=f"Market quote for symbol '{normalized_symbol}' was not found.",
                    code="MARKET_SYMBOL_NOT_FOUND",
                    status_code=404,
                ) from exc
            raise MarketDataProviderError(
                message="Data pasar belum tersedia. Coba lagi nanti.",
                code="MARKET_PROVIDER_UNAVAILABLE",
                status_code=503,
            ) from exc
        except error.URLError as exc:
            raise MarketDataProviderError(
                message="Data pasar belum tersedia. Coba lagi nanti.",
                code="MARKET_PROVIDER_UNAVAILABLE",
                status_code=503,
            ) from exc

        try:
            payload = json.loads(body)
        except json.JSONDecodeError as exc:
            raise MarketDataProviderError(
                message="Data pasar belum tersedia. Coba lagi nanti.",
                code="MARKET_PROVIDER_INVALID_RESPONSE",
                status_code=503,
            ) from exc

        price = payload.get("close") or payload.get("adjusted_close") or payload.get(
            "price"
        )
        if price is None:
            raise MarketDataProviderError(
                message="Data pasar belum tersedia. Coba lagi nanti.",
                code="MARKET_PROVIDER_INVALID_RESPONSE",
                status_code=503,
            )

        timestamp = payload.get("timestamp")
        as_of = utc_now_text()
        if isinstance(timestamp, (int, float)) and timestamp > 0:
            as_of = datetime.fromtimestamp(timestamp, tz=timezone.utc).replace(
                microsecond=0
            ).isoformat().replace("+00:00", "Z")

        return ProviderQuote(
            symbol=normalized_symbol,
            display_symbol=display_market_symbol(normalized_symbol),
            price=float(price),
            currency=str(payload.get("currency") or "IDR").upper(),
            source=self.source_name,
            provider=self.provider_label,
            is_mock=False,
            as_of=as_of,
        )
