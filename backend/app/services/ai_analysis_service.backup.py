from __future__ import annotations

import hashlib
import json
import socket
from datetime import datetime, timezone
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


DISCLAIMER_TEXT = (
    "Analisis ini bersifat edukatif dan bukan rekomendasi beli atau jual. "
    "Risiko investasi sepenuhnya berada di tangan pengguna."
)


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
        gemini_api_key: str = "",
        gemini_model_name: str = "gemini-2.5-flash",
        cache_ttl_seconds: int = 86400,
    ) -> None:
        self._cache_service = cache_service
        self._prompt_builder = prompt_builder
        self._provider_name = provider_name.lower()
        self._openai_api_key = openai_api_key
        self._gemini_api_key = gemini_api_key
        self._model_name = model_name
        self._gemini_model_name = gemini_model_name or "gemini-2.5-flash"
        self._enable_dev_fallback = enable_dev_fallback
        self._cache_ttl_seconds = cache_ttl_seconds

    def analyze(self, payload: dict[str, Any]) -> dict[str, Any]:
        normalized = self._normalize_payload(payload)
        cache_key = self._build_cache_key(normalized)
        cached = self._cache_service.get_valid_analysis(cache_key)

        if cached is not None:
            cached["isCached"] = True
            self._normalize_cached_metadata(cached)
            return cached

        fallback_reason = None

        if self._provider_name == "openai":
            if self._openai_api_key:
                try:
                    analysis = self._request_openai_analysis(normalized)
                    validated = self._validate_analysis(analysis, normalized)
                    self._attach_metadata(
                        validated,
                        provider="openai",
                        model=self._model_name,
                        is_ai_generated=True,
                        is_fallback=False,
                        is_cached=False,
                        fallback_reason=None,
                    )

                    self._cache_service.upsert_analysis(
                        cache_key=cache_key,
                        news_id=validated["newsId"],
                        analysis=validated,
                        provider="openai",
                        model=self._model_name,
                    )
                    return validated
                except AnalysisServiceError as error:
                    if not self._enable_dev_fallback:
                        raise
                    fallback_reason = error.message
                except Exception:
                    if not self._enable_dev_fallback:
                        raise AnalysisServiceError(
                            "Analisis AI belum tersedia saat ini.",
                            "AI_ANALYSIS_UNAVAILABLE",
                            503,
                        )
                    fallback_reason = "Terjadi kesalahan internal pada sistem AI."
            else:
                fallback_reason = "API Key OpenAI belum dikonfigurasi."

        elif self._provider_name == "gemini":
            if self._gemini_api_key:
                try:
                    analysis = self._request_gemini_analysis(normalized)
                    validated = self._validate_analysis(analysis, normalized)
                    self._attach_metadata(
                        validated,
                        provider="gemini",
                        model=self._gemini_model_name,
                        is_ai_generated=True,
                        is_fallback=False,
                        is_cached=False,
                        fallback_reason=None,
                    )

                    self._cache_service.upsert_analysis(
                        cache_key=cache_key,
                        news_id=validated["newsId"],
                        analysis=validated,
                        provider="gemini",
                        model=self._gemini_model_name,
                    )
                    return validated
                except AnalysisServiceError as error:
                    if not self._enable_dev_fallback:
                        raise
                    fallback_reason = error.message
                except Exception:
                    if not self._enable_dev_fallback:
                        raise AnalysisServiceError(
                            "Analisis Gemini belum tersedia saat ini.",
                            "AI_ANALYSIS_UNAVAILABLE",
                            503,
                        )
                    fallback_reason = "Terjadi kesalahan internal pada sistem Gemini."
            else:
                fallback_reason = "API Key Gemini belum dikonfigurasi."

        else:
            fallback_reason = (
                f"AI_PROVIDER '{self._provider_name}' belum didukung. "
                "Gunakan 'openai' atau 'gemini'."
            )

        if self._enable_dev_fallback:
            analysis = self._build_mock_analysis(normalized)
            self._attach_metadata(
                analysis,
                provider="mock-development",
                model="rule-based-fallback",
                is_ai_generated=False,
                is_fallback=True,
                is_cached=False,
                fallback_reason=fallback_reason,
            )

            self._cache_service.upsert_analysis(
                cache_key=cache_key,
                news_id=analysis["newsId"],
                analysis=analysis,
                provider="mock-development",
                model="rule-based-fallback",
            )
            return analysis

        raise AnalysisServiceError(
            "AI provider belum dikonfigurasi dan fallback development dimatikan.",
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

    def _attach_metadata(
        self,
        analysis: dict[str, Any],
        *,
        provider: str,
        model: str,
        is_ai_generated: bool,
        is_fallback: bool,
        is_cached: bool,
        fallback_reason: str | None,
    ) -> None:
        analysis.update(
            {
                "isAiGenerated": is_ai_generated,
                "isFallback": is_fallback,
                "isCached": is_cached,
                "provider": provider,
                "model": model,
                "fallbackReason": fallback_reason,
                "generatedAt": datetime.now(timezone.utc)
                .isoformat()
                .replace("+00:00", "Z"),
                "cacheTtlSeconds": self._cache_ttl_seconds,
                "disclaimer": DISCLAIMER_TEXT,
            }
        )

    def _normalize_cached_metadata(self, cached: dict[str, Any]) -> None:
        provider = str(cached.get("provider") or "").strip().lower()
        if not provider:
            if self._provider_name == "gemini" and self._gemini_api_key:
                provider = "gemini"
            elif self._provider_name == "openai" and self._openai_api_key:
                provider = "openai"
            else:
                provider = "mock-development"

        if "model" not in cached:
            if provider == "gemini":
                cached["model"] = self._gemini_model_name
            elif provider == "openai":
                cached["model"] = self._model_name
            else:
                cached["model"] = "rule-based-fallback"

        cached["provider"] = provider
        cached.setdefault("isAiGenerated", provider in {"openai", "gemini"})
        cached.setdefault("isFallback", provider == "mock-development")
        cached.setdefault("fallbackReason", None)
        cached.setdefault(
            "generatedAt",
            datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        )
        cached["cacheTtlSeconds"] = self._cache_ttl_seconds
        cached["disclaimer"] = DISCLAIMER_TEXT

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
            with urlopen(request, timeout=15) as response:
                body = json.loads(response.read().decode("utf-8"))
        except HTTPError as error:
            detail = error.read().decode("utf-8", errors="ignore")
            raise AnalysisServiceError(
                f"AI provider mengembalikan error. {detail[:200]}".strip(),
                "AI_PROVIDER_ERROR",
                502,
            ) from error
        except TimeoutError:
            raise AnalysisServiceError(
                "API AI memakan waktu terlalu lama (timeout).",
                "AI_PROVIDER_TIMEOUT",
                504,
            )
        except URLError as error:
            if isinstance(error.reason, socket.timeout) or "timeout" in str(error.reason).lower():
                raise AnalysisServiceError(
                    "API AI memakan waktu terlalu lama (timeout).",
                    "AI_PROVIDER_TIMEOUT",
                    504,
                )
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
        return self._parse_json_content(content)

    def _request_gemini_analysis(self, payload: dict[str, str]) -> dict[str, Any]:
        messages = self._prompt_builder.build_news_analysis_messages(payload)
        system_prompt = " ".join(
            message["content"] for message in messages if message.get("role") == "system"
        )
        user_prompt = "\n\n".join(
            message["content"] for message in messages if message.get("role") == "user"
        )

        model = quote(self._gemini_model_name, safe="")
        request_url = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{model}:generateContent?key={self._gemini_api_key}"
        )
        request_body = {
            "systemInstruction": {
                "parts": [{"text": system_prompt}],
            },
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": user_prompt}],
                }
            ],
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
        }
        request = Request(
            request_url,
            data=json.dumps(request_body).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        try:
            with urlopen(request, timeout=15) as response:
                body = json.loads(response.read().decode("utf-8"))
        except HTTPError as error:
            detail = error.read().decode("utf-8", errors="ignore")
            raise AnalysisServiceError(
                f"Gemini provider mengembalikan error. {detail[:200]}".strip(),
                "AI_PROVIDER_ERROR",
                502,
            ) from error
        except TimeoutError:
            raise AnalysisServiceError(
                "API Gemini memakan waktu terlalu lama (timeout).",
                "AI_PROVIDER_TIMEOUT",
                504,
            )
        except URLError as error:
            if isinstance(error.reason, socket.timeout) or "timeout" in str(error.reason).lower():
                raise AnalysisServiceError(
                    "API Gemini memakan waktu terlalu lama (timeout).",
                    "AI_PROVIDER_TIMEOUT",
                    504,
                )
            raise AnalysisServiceError(
                "Gemini provider tidak dapat dihubungi.",
                "AI_PROVIDER_UNAVAILABLE",
                503,
            ) from error

        candidates = body.get("candidates")
        if not isinstance(candidates, list) or not candidates:
            raise AnalysisServiceError(
                "Gemini provider tidak mengembalikan kandidat respons.",
                "AI_INVALID_RESPONSE",
                502,
            )

        content = candidates[0].get("content", {})
        parts = content.get("parts")
        if not isinstance(parts, list):
            raise AnalysisServiceError(
                "Gemini provider mengembalikan struktur respons yang tidak valid.",
                "AI_INVALID_RESPONSE",
                502,
            )

        text = "\n".join(
            str(part.get("text", "")).strip()
            for part in parts
            if isinstance(part, dict) and str(part.get("text", "")).strip()
        )
        if not text:
            raise AnalysisServiceError(
                "Gemini provider mengembalikan respons kosong.",
                "AI_INVALID_RESPONSE",
                502,
            )

        return self._parse_json_content(text)

    def _parse_json_content(self, content: str) -> dict[str, Any]:
        text = content.strip()
        if text.startswith("```"):
            lines = text.splitlines()
            if lines and lines[0].strip().startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            text = "\n".join(lines).strip()

        try:
            parsed = json.loads(text)
        except json.JSONDecodeError as error:
            raise AnalysisServiceError(
                "AI provider mengembalikan JSON yang tidak valid.",
                "AI_INVALID_JSON",
                502,
            ) from error

        if not isinstance(parsed, dict):
            raise AnalysisServiceError(
                "AI provider tidak mengembalikan JSON object.",
                "AI_INVALID_JSON",
                502,
            )
        return parsed

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

        combined_text_for_safety_check = ""

        for field in required_string_fields:
            val = analysis.get(field)
            if not isinstance(val, str) or not val.strip():
                raise AnalysisServiceError(
                    f"Field '{field}' dari AI tidak valid.",
                    "AI_INVALID_SCHEMA",
                    502,
                )
            if field != "disclaimer":
                combined_text_for_safety_check += f" {val}"

        for field in required_list_fields:
            val = analysis.get(field)
            if not isinstance(val, list):
                raise AnalysisServiceError(
                    f"Field '{field}' dari AI tidak valid.",
                    "AI_INVALID_SCHEMA",
                    502,
                )
            combined_text_for_safety_check += f" {' '.join(str(item) for item in val)}"

        if self._contains_forbidden_recommendation(combined_text_for_safety_check):
            raise AnalysisServiceError(
                "Output AI mengandung rekomendasi investasi yang dilarang (beli/jual/dll).",
                "AI_UNSAFE_CONTENT",
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
            "disclaimer": DISCLAIMER_TEXT,
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

    def _contains_forbidden_recommendation(self, text: str) -> bool:
        text_lower = text.lower()
        forbidden_phrases = [
            "beli sekarang",
            "jual sekarang",
            "take profit",
            "stop loss",
            "pasti naik",
            "pasti turun",
            "rekomendasi beli",
            "rekomendasi jual",
            "waktunya beli",
            "waktunya jual",
            "segera beli",
            "segera jual",
            "borong saham",
            "cut loss",
            "rekomendasi trading",
        ]
        return any(phrase in text_lower for phrase in forbidden_phrases)

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
            "disclaimer": DISCLAIMER_TEXT,
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
