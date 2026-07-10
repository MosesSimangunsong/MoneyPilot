def test_health_returns_success(client):
    response = client.get("/health")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["status"] == "success"
    assert payload["message"] == "MoneyPilot backend is healthy"
    assert payload["serverTime"].endswith("Z")
