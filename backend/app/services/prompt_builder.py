from __future__ import annotations

import json


class PromptBuilder:
    @staticmethod
    def build_news_analysis_messages(payload: dict) -> list[dict]:
        schema_description = {
            "newsId": "string",
            "judul": "string",
            "ringkasan": "string",
            "kategori": "string",
            "asetTerdampak": ["string"],
            "impactScore": "number 0-100",
            "confidenceScore": "number 0-100",
            "dampakPotensial": "string",
            "rantaiSebabAkibat": ["string"],
            "dataPendukung": ["string"],
            "skenarioPositif": "string",
            "skenarioNegatif": "string",
            "halYangPerluDipantau": ["string"],
            "kesimpulanPemula": "string",
            "disclaimer": "Informasi ini bukan nasihat keuangan.",
        }
        system_prompt = (
            "Anda adalah analis edukatif untuk aplikasi personal finance MoneyPilot. "
            "Gunakan Bahasa Indonesia yang tenang, mudah dipahami pemula, dan tidak "
            "pernah memberi rekomendasi beli, jual, entry, take profit, stop loss, "
            "atau klaim pasti naik/pasti turun. Gunakan bahasa probabilistik seperti "
            "'berpotensi', 'dapat memengaruhi', dan 'perlu dipantau'. Jika data tidak "
            "cukup, katakan secara eksplisit dan turunkan confidenceScore. Jangan "
            "mengarang harga, inflasi, suku bunga, atau data pasar yang tidak ada pada "
            "input. Kembalikan JSON valid tanpa markdown dan tanpa teks tambahan."
        )
        user_prompt = {
            "instruksi": [
                "Analisis dampak berita berikut untuk tujuan edukasi.",
                "Jangan beri rekomendasi beli atau jual.",
                "Selalu sertakan disclaimer persis: Informasi ini bukan nasihat keuangan.",
                "Jika data pendukung terbatas, tulis itu dengan jelas di dataPendukung dan kesimpulanPemula.",
            ],
            "skema_output": schema_description,
            "input_berita": payload,
        }
        return [
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": json.dumps(user_prompt, ensure_ascii=False),
            },
        ]
