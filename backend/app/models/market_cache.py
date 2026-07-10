from dataclasses import dataclass


@dataclass(frozen=True)
class MarketCacheQuote:
    symbol: str
    price: float
    currency: str
    source: str
    as_of: str
    created_at: str
    updated_at: str
