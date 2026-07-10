def test_analyze_without_api_key_does_not_crash(client):
    response = client.post(
        "/api/news/analyze",
        json={
            "newsId": "demo-news",
            "title": "Bank sentral memberi sinyal kehati-hatian baru",
            "summary": "Pelaku pasar menilai sinyal kehati-hatian bank sentral dapat memengaruhi arah likuiditas dan sentimen aset berisiko.",
            "url": "https://example.com/news/demo-news",
            "category": "Suku Bunga",
        },
    )

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    
    # Memastikan disclaimer baru dan deteksi fallback berjalan
    analysis = payload["data"]
    assert analysis["disclaimer"] == "Analisis ini bersifat edukatif dan bukan rekomendasi beli atau jual. Risiko investasi sepenuhnya berada di tangan pengguna."
    assert analysis["isFallback"] is True
    assert analysis["provider"] == "mock-development"


def test_analyze_returns_valid_schema_with_mock_fallback(client):
    response = client.post(
        "/api/news/analyze",
        json={
            "title": "Ketidakpastian global membuat investor memantau emas",
            "summary": "Ketidakpastian global yang meningkat membuat investor lebih hati-hati dan memantau aset aman seperti emas serta pergerakan dolar.",
            "url": "https://example.com/news/mock-analysis",
            "category": "Geopolitik",
        },
    )

    assert response.status_code == 200
    payload = response.get_json()
    analysis = payload["data"]
    
    # Menambahkan metadata baru ke dalam required keys
    required_keys = {
        "newsId",
        "judul",
        "ringkasan",
        "kategori",
        "asetTerdampak",
        "impactScore",
        "confidenceScore",
        "dampakPotensial",
        "rantaiSebabAkibat",
        "dataPendukung",
        "skenarioPositif",
        "skenarioNegatif",
        "halYangPerluDipantau",
        "kesimpulanPemula",
        "disclaimer",
        "isAiGenerated",
        "isFallback",
        "isCached",
        "provider",
        "model",
        "fallbackReason",
        "generatedAt",
        "cacheTtlSeconds",
    }
    assert required_keys <= set(analysis.keys())
    assert isinstance(analysis["asetTerdampak"], list)
    assert 0 <= analysis["impactScore"] <= 100
    assert 0 <= analysis["confidenceScore"] <= 100


def test_analyze_invalid_payload_returns_json_error(client):
    response = client.post("/api/news/analyze", json={"title": ""})

    assert response.status_code == 400
    payload = response.get_json()
    assert payload["status"] == "error"
    assert payload["error"]["statusCode"] == 400