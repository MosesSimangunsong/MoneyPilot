import json
from datetime import datetime, timedelta, timezone

from flask import current_app

from ..db import get_db
from ..models.market_cache import MarketCacheQuote


class CacheService:
    def _utc_now_text(self) -> str:
        return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def _is_still_valid(self, timestamp_text: str, ttl_seconds: int) -> bool:
        timestamp = datetime.fromisoformat(timestamp_text.replace("Z", "+00:00"))
        expires_at = timestamp + timedelta(seconds=ttl_seconds)
        return expires_at > datetime.now(timezone.utc)

    def get_valid_quote(self, symbol: str) -> dict | None:
        record = self.get_quote(symbol)
        if record is None:
            return None

        ttl_seconds = current_app.config["MARKET_CACHE_TTL_SECONDS"]
        if not self._is_still_valid(record.as_of, ttl_seconds):
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
        now = self._utc_now_text()
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

    def get_valid_news_feed(self, cache_key: str) -> list[dict] | None:
        row = get_db().execute(
            """
            SELECT response_json, fetched_at
            FROM news_feed_cache
            WHERE cache_key = ?
            """,
            (cache_key,),
        ).fetchone()
        if row is None:
            return None

        ttl_seconds = current_app.config["NEWS_CACHE_TTL_SECONDS"]
        if not self._is_still_valid(row["fetched_at"], ttl_seconds):
            return None

        return json.loads(row["response_json"])

    def upsert_news_feed(self, cache_key: str, articles: list[dict]) -> None:
        now = self._utc_now_text()
        get_db().execute(
            """
            INSERT INTO news_feed_cache (cache_key, response_json, fetched_at, updated_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(cache_key) DO UPDATE SET
                response_json = excluded.response_json,
                fetched_at = excluded.fetched_at,
                updated_at = excluded.updated_at
            """,
            (cache_key, json.dumps(articles), now, now),
        )
        get_db().commit()

    def upsert_news_articles(self, articles: list[dict]) -> None:
        now = self._utc_now_text()
        for article in articles:
            get_db().execute(
                """
                INSERT INTO news_article_cache (
                    id, title, summary, source, url, category,
                    published_at, fetched_at, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title = excluded.title,
                    summary = excluded.summary,
                    source = excluded.source,
                    url = excluded.url,
                    category = excluded.category,
                    published_at = excluded.published_at,
                    fetched_at = excluded.fetched_at,
                    updated_at = excluded.updated_at
                """,
                (
                    article["id"],
                    article["title"],
                    article["summary"],
                    article["source"],
                    article["url"],
                    article["category"],
                    article["publishedAt"],
                    now,
                    now,
                ),
            )
        get_db().commit()

    def get_news_article(self, article_id: str) -> dict | None:
        row = get_db().execute(
            """
            SELECT id, title, summary, source, url, category, published_at
            FROM news_article_cache
            WHERE id = ?
            """,
            (article_id,),
        ).fetchone()
        if row is None:
            return None

        return {
            "id": row["id"],
            "title": row["title"],
            "summary": row["summary"],
            "source": row["source"],
            "url": row["url"],
            "category": row["category"],
            "publishedAt": row["published_at"],
        }

    def get_valid_analysis(self, cache_key: str) -> dict | None:
        row = get_db().execute(
            """
            SELECT response_json, generated_at
            FROM analysis_cache
            WHERE cache_key = ?
            """,
            (cache_key,),
        ).fetchone()
        if row is None:
            return None

        ttl_seconds = current_app.config["ANALYSIS_CACHE_TTL_SECONDS"]
        if not self._is_still_valid(row["generated_at"], ttl_seconds):
            return None

        return json.loads(row["response_json"])

    def upsert_analysis(
        self,
        *,
        cache_key: str,
        news_id: str,
        analysis: dict,
        provider: str,
        model: str,
    ) -> None:
        now = self._utc_now_text()
        get_db().execute(
            """
            INSERT INTO analysis_cache (
                cache_key, news_id, response_json, provider, model,
                generated_at, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(cache_key) DO UPDATE SET
                news_id = excluded.news_id,
                response_json = excluded.response_json,
                provider = excluded.provider,
                model = excluded.model,
                generated_at = excluded.generated_at,
                updated_at = excluded.updated_at
            """,
            (
                cache_key,
                news_id,
                json.dumps(analysis),
                provider,
                model,
                now,
                now,
            ),
        )
        get_db().commit()

    def _to_payload(self, quote: MarketCacheQuote, *, is_stale: bool) -> dict:
        return {
            "symbol": quote.symbol,
            "price": quote.price,
            "currency": quote.currency,
            "source": quote.source,
            "asOf": quote.as_of,
            "isStale": is_stale,
        }
