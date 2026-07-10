def test_news_endpoint_returns_consistent_json(client):
    response = client.get("/api/news")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    assert isinstance(payload["data"], list)
    assert payload["serverTime"].endswith("Z")
    assert payload["data"]
    first = payload["data"][0]
    assert {"id", "title", "summary", "source", "url", "category", "publishedAt"} <= set(
        first.keys()
    )


def test_news_endpoint_accepts_category_filter(client):
    response = client.get("/api/news?category=Geopolitik&limit=5")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    assert len(payload["data"]) <= 5


def test_news_detail_uses_cached_article(client):
    list_response = client.get("/api/news")
    article_id = list_response.get_json()["data"][0]["id"]

    detail_response = client.get(f"/api/news/{article_id}")

    assert detail_response.status_code == 200
    payload = detail_response.get_json()
    assert payload["status"] == "success"
    assert payload["data"]["id"] == article_id


def test_news_invalid_limit_returns_json_error(client):
    response = client.get("/api/news?limit=0")

    assert response.status_code == 400
    payload = response.get_json()
    assert payload["status"] == "error"
    assert payload["error"]["statusCode"] == 400
