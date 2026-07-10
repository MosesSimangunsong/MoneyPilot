from datetime import datetime, timedelta, timezone

from flask import current_app

from ..db import get_db
from ..models.market_cache import MarketCacheQuote


class CacheService:
    def get_valid_quote(self, symbol: str) -> dict | None:
        record = self.get_quote(symbol)
        if record is None:
            return None

        as_of = datetime.fromisoformat(record.as_of.replace("Z", "+00:00"))
        ttl_seconds = current_app.config["MARKET_CACHE_TTL_SECONDS"]
        expires_at = as_of + timedelta(seconds=ttl_seconds)
        if expires_at <= datetime.now(timezone.utc):
            return None

        return self._to_payload(record, is_stale=False)

    def get_quote(self, symbol: str) -> MarketCacheQuote | None:
        row = get_db().execute(
            """
            SELECT symbol, price, currency, source, as_of, created_at, updated_at
            FROM market_cache
            WHERE symbol = ?
            """,
            (symbol,),
        ).fetchone()
        if row is None:
            return None

        return MarketCacheQuote(
            symbol=row["symbol"],
            price=float(row["price"]),
            currency=row["currency"],
            source=row["source"],
            as_of=row["as_of"],
            created_at=row["created_at"],
            updated_at=row["updated_at"],
        )

    def upsert_quote(self, quote: dict) -> dict:
        now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        existing = self.get_quote(quote["symbol"])
        created_at = existing.created_at if existing is not None else now

        get_db().execute(
            """
            INSERT INTO market_cache (
                symbol, price, currency, source, as_of, created_at, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(symbol) DO UPDATE SET
                price = excluded.price,
                currency = excluded.currency,
                source = excluded.source,
                as_of = excluded.as_of,
                updated_at = excluded.updated_at
            """,
            (
                quote["symbol"],
                quote["price"],
                quote["currency"],
                quote["source"],
                quote["asOf"],
                created_at,
                now,
            ),
        )
        get_db().commit()

        return {
            **quote,
            "isStale": False,
        }

    def _to_payload(self, quote: MarketCacheQuote, *, is_stale: bool) -> dict:
        return {
            "symbol": quote.symbol,
            "price": quote.price,
            "currency": quote.currency,
            "source": quote.source,
            "asOf": quote.as_of,
            "isStale": is_stale,
        }
