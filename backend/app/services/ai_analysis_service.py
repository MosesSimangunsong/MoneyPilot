from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class AnalysisServiceError(Exception):
    def __init__(self, message: str, code: str, status_code: int) -> None:
        super().__init__(message)
        self.message = message
        self.code = code
        self.status_code = status_code


class AIAnalysisService:
    def __init__(
        self,
        *,
        cache_service,
        prompt_builder,
        provider_name: str,
        openai_api_key: str,
        model_name: str,
        enable_dev_fallback: bool,
    ) -> None:
        self._cache_service = cache_service
        self._prompt_builder = prompt_builder
        self._provider_name = provider_name.lower()
        self._openai_api_key = openai_api_key
        self._model_name = model_name
        self._enable_dev_fallback = enable_dev_fallback

    def analyze(self, payload: dict[str, Any]) -> dict[str, Any]:
        normalized = self._normalize_payload(payload)
        cache_key = self._build_cache_key(normalized)
        cached = self._cache_service.get_valid_analysis(cache_key)
        if cached is not None:
            return cached

        if self._provider_name == "openai" and self._openai_api_key:
            try:
                analysis = self._request_openai_analysis(normalized)
                validated = self._validate_analysis(analysis, normalized)
                self._cache_service.upsert_analysis(
                    cache_key=cache_key,
                    news_id=validated["newsId"],
                    analysis=validated,
                    provider="openai",
                    model=self._model_name,
                )
                return validated
            except AnalysisServiceError:
                if not self._enable_dev_fallback:
                    raise
            except Exception:
                if not self._enable_dev_fallback:
                    raise AnalysisServiceError(
                        "Analisis AI belum tersedia saat ini.",
                        "AI_ANALYSIS_UNAVAILABLE",
                        503,
                    )

        if self._enable_dev_fallback:
            analysis = self._build_mock_analysis(normalized)
            self._cache_service.upsert_analysis(
                cache_key=cache_key,
                news_id=analysis["newsId"],
                analysis=analysis,
                provider="mock-development",
                model="rule-based-fallback",
            )
            return analysis

        raise AnalysisServiceError(
            "OPENAI_API_KEY belum diatur dan fallback development dimatikan.",
            "AI_PROVIDER_NOT_CONFIGURED",
            503,
        )

    def _normalize_payload(self, payload: dict[str, Any]) -> dict[str, str]:
        title = str(payload.get("title", "")).strip()
        summary = str(payload.get("summary", "")).strip()
        url = str(payload.get("url", "")).strip()
        category = str(payload.get("category", "")).strip() or "Global"
        news_id = str(payload.get("newsId", "")).strip()

        if not title:
            raise AnalysisServiceError(
                "Field 'title' wajib diisi.",
                "INVALID_ANALYSIS_PAYLOAD",
                400,
            )
        if not summary:
            raise AnalysisServiceError(
                "Field 'summary' wajib diisi.",
                "INVALID_ANALYSIS_PAYLOAD",
                400,
            )

        if not news_id:
            news_id = hashlib.sha256(f"{title}|{url}".encode("utf-8")).hexdigest()[:16]

        return {
            "newsId": news_id,
            "title": title,
            "summary": summary,
            "url": url,
            "category": category,
        }

    def _build_cache_key(self, payload: dict[str, str]) -> str:
        return hashlib.sha256(
            json.dumps(payload, sort_keys=True).encode("utf-8")
        ).hexdigest()

    def _request_openai_analysis(self, payload: dict[str, str]) -> dict[str, Any]:
        messages = self._prompt_builder.build_news_analysis_messages(payload)
        request_body = {
            "model": self._model_name,
            "messages": messages,
            "response_format": {"type": "json_object"},
            "temperature": 0.2,
        }
        request = Request(
            "https://api.openai.com/v1/chat/completions",
            data=json.dumps(request_body).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self._openai_api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:
            with urlopen(request, timeout=20) as response:
                body = json.loads(response.read().decode("utf-8"))
        except HTTPError as error:
            detail = error.read().decode("utf-8", errors="ignore")
            raise AnalysisServiceError(
                f"AI provider mengembalikan error. {detail[:200]}".strip(),
                "AI_PROVIDER_ERROR",
                502,
            ) from error
        except URLError as error:
            raise AnalysisServiceError(
                "AI provider tidak dapat dihubungi.",
                "AI_PROVIDER_UNAVAILABLE",
                503,
            ) from error

        choices = body.get("choices")
        if not isinstance(choices, list) or not choices:
            raise AnalysisServiceError(
                "AI provider tidak mengembalikan pilihan respons.",
                "AI_INVALID_RESPONSE",
                502,
            )
        message = choices[0].get("message", {})
        content = message.get("content", "")
        if not isinstance(content, str) or not content.strip():
            raise AnalysisServiceError(
                "AI provider mengembalikan respons kosong.",
                "AI_INVALID_RESPONSE",
                502,
            )
        try:
            return json.loads(content)
        except json.JSONDecodeError as error:
            raise AnalysisServiceError(
                "AI provider mengembalikan JSON yang tidak valid.",
                "AI_INVALID_JSON",
                502,
            ) from error

    def _validate_analysis(
        self,
        analysis: dict[str, Any],
        payload: dict[str, str],
    ) -> dict[str, Any]:
        required_string_fields = [
            "judul",
            "ringkasan",
            "kategori",
            "dampakPotensial",
            "skenarioPositif",
            "skenarioNegatif",
            "kesimpulanPemula",
            "disclaimer",
        ]
        required_list_fields = [
            "asetTerdampak",
            "rantaiSebabAkibat",
            "dataPendukung",
            "halYangPerluDipantau",
        ]

        for field in required_string_fields:
            if not isinstance(analysis.get(field), str) or not analysis[field].strip():
                raise AnalysisServiceError(
                    f"Field '{field}' dari AI tidak valid.",
                    "AI_INVALID_SCHEMA",
                    502,
                )
        for field in required_list_fields:
            if not isinstance(analysis.get(field), list):
                raise AnalysisServiceError(
                    f"Field '{field}' dari AI tidak valid.",
                    "AI_INVALID_SCHEMA",
                    502,
                )

        impact_score = self._coerce_score(analysis.get("impactScore"), fallback=40)
        confidence_score = self._coerce_score(
            analysis.get("confidenceScore"), fallback=45
        )

        return {
            "newsId": str(analysis.get("newsId") or payload["newsId"]),
            "judul": analysis["judul"].strip(),
            "ringkasan": analysis["ringkasan"].strip(),
            "kategori": analysis["kategori"].strip(),
            "asetTerdampak": self._normalize_string_list(analysis["asetTerdampak"]),
            "impactScore": impact_score,
            "confidenceScore": confidence_score,
            "dampakPotensial": analysis["dampakPotensial"].strip(),
            "rantaiSebabAkibat": self._normalize_string_list(
                analysis["rantaiSebabAkibat"]
            ),
            "dataPendukung": self._normalize_string_list(analysis["dataPendukung"]),
            "skenarioPositif": analysis["skenarioPositif"].strip(),
            "skenarioNegatif": analysis["skenarioNegatif"].strip(),
            "halYangPerluDipantau": self._normalize_string_list(
                analysis["halYangPerluDipantau"]
            ),
            "kesimpulanPemula": analysis["kesimpulanPemula"].strip(),
            "disclaimer": "Informasi ini bukan nasihat keuangan.",
        }

    def _coerce_score(self, value: Any, *, fallback: int) -> int:
        try:
            score = int(round(float(value)))
        except (TypeError, ValueError):
            score = fallback
        return max(0, min(score, 100))

    def _normalize_string_list(self, value: list[Any]) -> list[str]:
        normalized = [str(item).strip() for item in value if str(item).strip()]
        return normalized[:6] or ["Data belum cukup untuk dirinci lebih jauh."]

    def _build_mock_analysis(self, payload: dict[str, str]) -> dict[str, Any]:
        summary_lower = payload["summary"].lower()
        category = payload["category"]
        affected_assets = self._infer_affected_assets(category, summary_lower)
        confidence_score = 58 if len(payload["summary"]) > 80 else 42
        impact_score = 68 if category in {"Geopolitik", "Suku Bunga"} else 54
        mention_limited_data = (
            "Data pasar pendukung belum ikut dikirim dalam permintaan ini, jadi analisis "
            "masih bersifat awal dan perlu dipantau ulang."
        )
        return {
            "newsId": payload["newsId"],
            "judul": payload["title"],
            "ringkasan": payload["summary"],
            "kategori": category,
            "asetTerdampak": affected_assets,
            "impactScore": impact_score,
            "confidenceScore": confidence_score,
            "dampakPotensial": (
                "Berita ini berpotensi memengaruhi sentimen pasar karena dapat "
                "mengubah cara pelaku pasar menilai risiko, arus dana, atau "
                "prospek pertumbuhan dalam jangka pendek."
            ),
            "rantaiSebabAkibat": [
                "Berita baru memicu penilaian ulang terhadap risiko atau prospek ekonomi.",
                "Perubahan persepsi tersebut dapat memengaruhi arus dana ke aset yang dianggap lebih aman atau lebih berisiko.",
                "Pergerakan arus dana itu kemudian dapat terasa pada harga aset, nilai tukar, atau sentimen pasar domestik.",
            ],
            "dataPendukung": [
                f"Sumber berita: {payload['url'] or 'tautan tidak tersedia'}.",
                f"Kategori utama yang terdeteksi: {category}.",
                mention_limited_data,
            ],
            "skenarioPositif": (
                "Jika pasar menilai risiko dari berita ini mulai mereda, tekanan terhadap aset "
                "berisiko dapat berkurang dan sentimen bisa membaik secara bertahap."
            ),
            "skenarioNegatif": (
                "Jika berita berkembang ke arah yang lebih buruk atau memicu ketidakpastian baru, "
                "pelaku pasar dapat menjadi lebih hati-hati sehingga volatilitas berpotensi meningkat."
            ),
            "halYangPerluDipantau": [
                "Perkembangan lanjutan dari berita yang sama dalam 1-3 hari ke depan.",
                "Respons pasar global dan domestik setelah berita ini menyebar lebih luas.",
                "Data ekonomi resmi atau pernyataan otoritas yang bisa menguatkan atau melemahkan narasi berita.",
            ],
            "kesimpulanPemula": (
                "Untuk pemula, baca berita ini sebagai sinyal bahwa sentimen pasar bisa berubah, "
                "bukan sebagai perintah untuk bertindak. Karena data pendukung masih terbatas, "
                "hasil ini lebih cocok dipakai sebagai bahan belajar dan pemantauan awal."
            ),
            "disclaimer": "Informasi ini bukan nasihat keuangan.",
        }

    def _infer_affected_assets(self, category: str, summary_lower: str) -> list[str]:
        assets = {
            "Indonesia": ["IHSG", "USD/IDR", "Obligasi Indonesia"],
            "Global": ["IHSG", "USD/IDR", "Emas"],
            "Saham": ["IHSG", "Saham Blue Chip", "Saham Sektoral"],
            "Forex": ["USD/IDR", "Dolar AS", "Mata Uang Asia"],
            "Komoditas": ["Emas", "Minyak", "Saham Komoditas"],
            "Suku Bunga": ["IHSG", "USD/IDR", "Obligasi"],
            "Geopolitik": ["Emas", "USD/IDR", "IHSG"],
            "IPO": ["IHSG", "Likuiditas Pasar", "Sentimen Emiten Baru"],
            "Kripto": ["Bitcoin", "Ethereum", "Aset Berisiko"],
        }.get(category, ["IHSG", "USD/IDR", "Emas"])
        if "rupiah" in summary_lower and "USD/IDR" not in assets:
            assets = ["USD/IDR", *assets]
        return assets[:3]
