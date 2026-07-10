from __future__ import annotations

import json


DISCLAIMER_TEXT = (
    "Analisis ini bersifat edukatif dan bukan rekomendasi beli atau jual. "
    "Risiko investasi sepenuhnya berada di tangan pengguna."
)


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
            "disclaimer": DISCLAIMER_TEXT,
        }
        system_prompt = (
            "Anda adalah AI analis edukatif untuk aplikasi personal finance MoneyPilot. "
            "ATURAN MUTLAK: Anda TIDAK BOLEH memberikan rekomendasi investasi, trading, beli, jual, tahan, "
            "entry, take profit, atau stop loss. Jangan gunakan kata 'beli sekarang', 'jual segera', "
            "'pasti naik', 'pasti turun', atau sejenisnya. Gunakan Bahasa Indonesia yang tenang, objektif, "
            "dan probabilistik (misal: 'berpotensi', 'dapat memengaruhi'). Jika data kurang, katakan secara "
            "eksplisit dan turunkan confidenceScore ke bawah 50. Jangan berhalusinasi atau mengarang data metrik "
            "yang tidak ada di input. OUTPUT HARUS BERUPA JSON VALID MURNI. JANGAN GUNAKAN FORMAT MARKDOWN "
            "(jangan bungkus dengan ```json). KEMBALIKAN HANYA TEKS JSON."
        )
        user_prompt = {
            "instruksi": [
                "Buatlah analisis dampak berita secara edukatif berdasarkan data input_berita.",
                "Dilarang keras menyisipkan rekomendasi investasi atau trading (beli/jual).",
                f"Selalu sertakan disclaimer persis: '{DISCLAIMER_TEXT}'",
                "Jika data terbatas, sebutkan batasannya secara eksplisit pada dataPendukung dan kesimpulanPemula.",
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
