from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


class Database:
    def __init__(self):
        self.data = [{"code": "A01", "sensor_occupied": True}]
        self.failure = False
        self.calls = []

    def rpc(self, name, params):
        self.calls.append((name, params))
        return self

    def table(self, name):
        return self

    def select(self, columns):
        return self

    def order(self, column):
        return self

    def execute(self):
        if self.failure:
            raise RuntimeError("internal-secret-should-not-be-exposed")
        return SimpleNamespace(data=self.data)


@pytest.fixture
def api():
    database = Database()
    app = create_app(Settings("https://example.supabase.co", "server-secret", "test-device-key"), database)
    with TestClient(app) as client:
        yield client, database


@pytest.mark.parametrize("headers", [{}, {"X-Device-Key": "wrong-key"}])
def test_sensor_requires_device_key(api, headers):
    client, database = api
    result = client.post("/api/v1/parking-slots/A01/sensor", headers=headers, json={"occupied": True})
    assert result.status_code == 401
    assert not database.calls


@pytest.mark.parametrize("body", [
    {"occupied": "false"}, {"occupied": 0}, {"occupied": None},
    {"occupied": True, "user_id": "other"},
])
def test_sensor_rejects_ambiguous_or_extra_payload(api, body):
    client, database = api
    result = client.post("/api/v1/parking-slots/A01/sensor", headers={"X-Device-Key": "test-device-key"}, json=body)
    assert result.status_code == 422
    assert not database.calls


def test_sensor_uses_transactional_rpc(api):
    client, database = api
    result = client.post("/api/v1/parking-slots/A01/sensor", headers={"X-Device-Key": "test-device-key"}, json={"occupied": False})
    assert result.status_code == 200
    assert database.calls == [("ingest_sensor", {"p_code": "A01", "p_occupied": False})]


def test_unknown_slot_returns_404(api):
    client, database = api
    database.data = []
    result = client.post("/api/v1/parking-slots/A99/sensor", headers={"X-Device-Key": "test-device-key"}, json={"occupied": False})
    assert result.status_code == 404


def test_database_failure_does_not_leak_error(api):
    client, database = api
    database.failure = True
    result = client.post("/api/v1/parking-slots/A01/sensor", headers={"X-Device-Key": "test-device-key"}, json={"occupied": False})
    assert result.status_code == 503
    assert "internal-secret" not in result.text


def test_list_and_liveness(api):
    client, _ = api
    assert client.get("/health").json() == {"status": "ok"}
    assert client.get("/api/v1/parking-slots").status_code == 401
    assert client.get("/api/v1/parking-slots", headers={"X-Device-Key": "test-device-key"}).status_code == 200
