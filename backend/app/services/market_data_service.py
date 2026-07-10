from .market_data_provider import (
    EodhdMarketDataProvider,
    MarketDataProvider,
    MarketDataProviderError,
    MockMarketDataProvider,
    normalize_market_symbol,
)


class MarketDataService:
    def __init__(
        self,
        *,
        cache_service,
        provider_name: str = "mock",
        api_key: str = "",
        base_url: str = "",
        timeout_seconds: int = 8,
        cache_ttl_seconds: int = 900,
        enable_mock_fallback: bool = True,
        primary_provider: MarketDataProvider | None = None,
        mock_provider: MarketDataProvider | None = None,
    ) -> None:
        self._cache_service = cache_service
        self._provider_name = provider_name.strip().lower()
        self._cache_ttl_seconds = cache_ttl_seconds
        self._enable_mock_fallback = enable_mock_fallback
        self._primary_provider = primary_provider or self._build_provider(
            self._provider_name,
            api_key=api_key,
            base_url=base_url,
            timeout_seconds=timeout_seconds,
        )
        self._mock_provider = mock_provider or MockMarketDataProvider()

    def get_quote(self, symbol: str) -> dict:
        normalized_symbol = normalize_market_symbol(symbol)
        cached = self._cache_service.get_valid_quote(normalized_symbol)
        if cached is not None:
            return cached

        try:
            fresh_quote = self._primary_provider.get_quote(normalized_symbol)
            return self._cache_service.upsert_quote(
                fresh_quote.to_payload(
                    is_fallback=False,
                    is_stale=False,
                    cached_at=None,
                    cache_ttl_seconds=self._cache_ttl_seconds,
                )
            )
        except MarketDataProviderError as error:
            stale_quote = self._cache_service.get_stale_quote(normalized_symbol)
            if stale_quote is not None:
                stale_quote["isFallback"] = True
                return stale_quote
            if self._should_use_mock_fallback(error):
                fallback_quote = self._mock_provider.get_quote(normalized_symbol)
                return self._cache_service.upsert_quote(
                    fallback_quote.to_payload(
                        is_fallback=True,
                        is_stale=False,
                        cached_at=None,
                        cache_ttl_seconds=self._cache_ttl_seconds,
                    )
                )
            raise error

    def get_quotes(self, symbols: list[str]) -> dict:
        quotes: list[dict] = []
        errors: list[dict] = []

        for symbol in symbols:
            normalized_symbol = normalize_market_symbol(symbol)
            try:
                quotes.append(self.get_quote(normalized_symbol))
            except MarketDataProviderError as error:
                errors.append(
                    {
                        "symbol": normalized_symbol,
                        "message": error.message,
                        "code": error.code,
                    }
                )

        return {
            "quotes": quotes,
            "errors": errors,
            "count": len(quotes),
        }

    def _build_provider(
        self,
        provider_name: str,
        *,
        api_key: str,
        base_url: str,
        timeout_seconds: int,
    ) -> MarketDataProvider:
        normalized_name = provider_name.strip().lower()
        if normalized_name == "mock":
            return MockMarketDataProvider()
        if normalized_name == "eodhd":
            return EodhdMarketDataProvider(
                api_key=api_key,
                base_url=base_url,
                timeout_seconds=timeout_seconds,
            )
        raise MarketDataProviderError(
            message=f"Unsupported market data provider '{normalized_name}'.",
            code="MARKET_PROVIDER_UNSUPPORTED",
            status_code=500,
        )

    def _should_use_mock_fallback(self, error: MarketDataProviderError) -> bool:
        return (
            self._enable_mock_fallback
            and self._provider_name != "mock"
            and error.status_code != 404
        )
