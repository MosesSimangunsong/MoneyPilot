from dataclasses import dataclass


@dataclass(frozen=True)
class MarketCacheQuote:
    symbol: str
    display_symbol: str
    price: float
    currency: str
    source: str
    provider: str
    is_mock: bool
    is_fallback: bool
    as_of: str
    message: str
    created_at: str
    updated_at: str
