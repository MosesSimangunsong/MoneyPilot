from __future__ import annotations

import hashlib
import html
import json
import re
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from typing import Any
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from xml.etree import ElementTree


class GoogleNewsService:
    _category_queries = {
        "Indonesia": "ekonomi Indonesia OR pasar Indonesia OR rupiah",
        "Global": "ekonomi global OR pasar global OR resesi",
        "Saham": "saham Indonesia OR IHSG OR emiten",
        "Forex": "forex OR USD IDR OR nilai tukar",
        "Komoditas": "komoditas OR emas OR minyak OR batu bara",
        "Suku Bunga": "suku bunga OR bank sentral OR the fed OR BI rate",
        "Geopolitik": "geopolitik OR perang dagang OR konflik global",
        "IPO": "IPO OR penawaran umum perdana",
        "Kripto": "kripto OR bitcoin OR aset digital",
    }

    def __init__(
        self,
        *,
        cache_service,
        provider_name: str = "google_news_rss",
        enable_dev_fallback: bool = True,
    ) -> None:
        self._cache_service = cache_service
        self._provider_name = provider_name
        self._enable_dev_fallback = enable_dev_fallback

    def get_news(
        self,
        *,
        category: str | None,
        query: str | None,
        limit: int,
    ) -> list[dict]:
        normalized_category = self._normalize_category(category)
        normalized_query = (query or "").strip()
        cache_key = self._build_cache_key(
            category=normalized_category,
            query=normalized_query,
            limit=limit,
        )
        cached = self._cache_service.get_valid_news_feed(cache_key)
        if cached is not None:
            return cached[:limit]

        try:
            articles = self._fetch_articles(
                category=normalized_category,
                query=normalized_query,
                limit=limit,
            )
        except Exception:
            if not self._enable_dev_fallback:
                raise
            articles = self._mock_articles(
                category=normalized_category or "Global",
                query=normalized_query,
                limit=limit,
            )

        self._cache_service.upsert_news_articles(articles)
        self._cache_service.upsert_news_feed(cache_key, articles)
        return articles[:limit]

    def get_news_detail(self, article_id: str) -> dict | None:
        return self._cache_service.get_news_article(article_id)

    def _fetch_articles(
        self,
        *,
        category: str | None,
        query: str,
        limit: int,
    ) -> list[dict]:
        if self._provider_name != "google_news_rss":
            raise ValueError(f"Unsupported news provider '{self._provider_name}'.")

        search_terms = self._compose_search_terms(category=category, query=query)
        params = urlencode(
            {
                "q": search_terms,
                "hl": "id",
                "gl": "ID",
                "ceid": "ID:id",
            }
        )
        url = f"https://news.google.com/rss/search?{params}"
        request = Request(
            url,
            headers={
                "User-Agent": "MoneyPilotBackend/1.0",
                "Accept": "application/rss+xml, application/xml;q=0.9, */*;q=0.8",
            },
        )

        try:
            with urlopen(request, timeout=8) as response:
                body = response.read()
        except URLError as error:
            raise RuntimeError("Google News RSS tidak dapat dihubungi.") from error

        root = ElementTree.fromstring(body)
        items = root.findall("./channel/item")
        articles: list[dict] = []
        for item in items[:limit]:
            title = self._safe_text(item.findtext("title")) or "Berita tanpa judul"
            link = self._safe_text(item.findtext("link")) or ""
            description = self._strip_html(item.findtext("description"))
            summary = description or "Ringkasan belum tersedia dari sumber RSS."
            source = self._extract_source(item)
            published_at = self._parse_pub_date(item.findtext("pubDate"))
            article_category = category or self._infer_category(title, summary)
            article_id = self._build_article_id(link=link, title=title)
            articles.append(
                {
                    "id": article_id,
                    "title": title,
                    "summary": summary,
                    "source": source,
                    "url": link,
                    "category": article_category,
                    "publishedAt": published_at,
                }
            )
        return articles

    def _compose_search_terms(self, *, category: str | None, query: str) -> str:
        parts: list[str] = []
        if category:
            parts.append(self._category_queries.get(category, category))
        if query:
            parts.append(query)
        if not parts:
            parts.append("ekonomi OR pasar keuangan OR inflasi OR rupiah")
        return " ".join(parts)

    def _normalize_category(self, category: str | None) -> str | None:
        if category is None:
            return None
        trimmed = category.strip()
        if not trimmed:
            return None

        for known_category in self._category_queries:
            if known_category.lower() == trimmed.lower():
                return known_category
        return trimmed

    def _build_cache_key(self, *, category: str | None, query: str, limit: int) -> str:
        payload = json.dumps(
            {"category": category or "", "query": query, "limit": limit},
            sort_keys=True,
        )
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def _build_article_id(self, *, link: str, title: str) -> str:
        raw = f"{link}|{title}".encode("utf-8")
        return hashlib.sha256(raw).hexdigest()[:16]

    def _strip_html(self, value: str | None) -> str:
        if not value:
            return ""
        text = re.sub(r"<[^>]+>", " ", html.unescape(value))
        return re.sub(r"\s+", " ", text).strip()

    def _extract_source(self, item: ElementTree.Element) -> str:
        source = item.find("source")
        if source is not None and source.text:
            return self._safe_text(source.text) or "Google News"
        return "Google News"

    def _parse_pub_date(self, value: str | None) -> str:
        if not value:
            return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        parsed = parsedate_to_datetime(value)
        return parsed.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

    def _safe_text(self, value: str | None) -> str:
        return (value or "").strip()

    def _infer_category(self, title: str, summary: str) -> str:
        combined = f"{title} {summary}".lower()
        keyword_map = {
            "Kripto": ("bitcoin", "kripto", "ethereum"),
            "IPO": ("ipo", "penawaran umum"),
            "Geopolitik": ("perang", "tarif", "sanksi", "konflik"),
            "Suku Bunga": ("suku bunga", "the fed", "bank sentral", "bi rate"),
            "Komoditas": ("emas", "minyak", "komoditas", "batu bara", "nikel"),
            "Forex": ("usd", "idr", "rupiah", "nilai tukar", "forex"),
            "Saham": ("ihsg", "saham", "emiten", "bursa"),
            "Indonesia": ("indonesia", "ri", "bank indonesia"),
        }
        for category, keywords in keyword_map.items():
            if any(keyword in combined for keyword in keywords):
                return category
        return "Global"

    def _mock_articles(self, *, category: str, query: str, limit: int) -> list[dict]:
        base_articles = [
            {
                "title": "Investor menanti arah suku bunga dan dampaknya ke rupiah",
                "summary": "Pelaku pasar menilai perubahan arah suku bunga global dapat memengaruhi arus modal, nilai tukar, dan sentimen aset berisiko di Indonesia.",
                "source": "Mock Development Feed",
                "url": "https://example.com/news/suku-bunga-rupiah",
                "category": "Suku Bunga",
            },
            {
                "title": "Harga emas bergerak stabil saat ketidakpastian global meningkat",
                "summary": "Aset aman seperti emas kembali dipantau ketika pelaku pasar mencoba menilai risiko geopolitik dan arah inflasi beberapa bulan ke depan.",
                "source": "Mock Development Feed",
                "url": "https://example.com/news/emas-geopolitik",
                "category": "Komoditas",
            },
            {
                "title": "IHSG dan rupiah dipantau setelah data ekonomi regional dirilis",
                "summary": "Rilis data ekonomi kawasan membuat pasar menilai ulang prospek pertumbuhan, permintaan ekspor, dan aliran dana asing ke pasar domestik.",
                "source": "Mock Development Feed",
                "url": "https://example.com/news/ihsg-rupiah-regional",
                "category": "Indonesia",
            },
        ]
        now = datetime.now(timezone.utc)
        chosen = [
            article
            for article in base_articles
            if category.lower() in article["category"].lower()
            or not query
            or query.lower() in article["title"].lower()
            or query.lower() in article["summary"].lower()
        ]
        if not chosen:
            chosen = base_articles

        articles: list[dict] = []
        for index, article in enumerate(chosen[:limit]):
            published_at = now.replace(microsecond=0).isoformat().replace("+00:00", "Z")
            article_id = self._build_article_id(
                link=article["url"],
                title=f'{article["title"]}-{index}',
            )
            articles.append(
                {
                    "id": article_id,
                    "title": article["title"],
                    "summary": article["summary"],
                    "source": article["source"],
                    "url": article["url"],
                    "category": article["category"],
                    "publishedAt": published_at,
                }
            )
        return articles
