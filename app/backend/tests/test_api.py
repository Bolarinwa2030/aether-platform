from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").status_code == 200


def test_environments_seeded():
    r = client.get("/api/environments")
    assert r.status_code == 200
    assert {e["id"] for e in r.json()} >= {"dev", "staging", "prod"}


def test_deployment_lifecycle():
    r = client.post("/api/deployments", json={
        "service": "orders-api", "environment_id": "dev",
        "image": "ghcr.io/org/orders-api:abc1234", "git_sha": "abc1234",
    })
    assert r.status_code == 201
    dep_id = r.json()["id"]
    assert r.json()["status"] == "pending"

    r = client.patch(f"/api/deployments/{dep_id}", json={"status": "succeeded"})
    assert r.status_code == 200
    assert r.json()["finished_at"] is not None

    assert client.get(f"/api/deployments/{dep_id}").json()["status"] == "succeeded"


def test_unknown_environment_rejected():
    r = client.post("/api/deployments", json={
        "service": "x", "environment_id": "nope", "image": "i:1", "git_sha": "abc1234",
    })
    assert r.status_code == 404


def test_invalid_service_name_rejected():
    r = client.post("/api/deployments", json={
        "service": "Bad_Name", "environment_id": "dev", "image": "i:1", "git_sha": "abc1234",
    })
    assert r.status_code == 422


def test_drift_flow_updates_environment_and_overview():
    r = client.post("/api/drift", json={
        "environment_id": "staging", "drifted": True, "resources_changed": 3, "summary": "sg rule edited in console",
    })
    assert r.status_code == 201
    envs = {e["id"]: e for e in client.get("/api/environments").json()}
    assert envs["staging"]["drift"] == "drifted"
    assert client.get("/api/overview").json()["environments_drifted"] >= 1

    client.post("/api/drift", json={"environment_id": "staging", "drifted": False})
    envs = {e["id"]: e for e in client.get("/api/environments").json()}
    assert envs["staging"]["drift"] == "in_sync"


def test_metrics_endpoint():
    client.get("/healthz")
    body = client.get("/metrics").text
    assert "aether_http_requests_total" in body
