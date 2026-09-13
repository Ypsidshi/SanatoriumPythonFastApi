"""Smoke checks against a running deployment.

Unlike the rest of the suite these need a live API and a real SQL Server, so
they only run when BASE_URL is set:

    docker compose up -d
    BASE_URL=http://127.0.0.1:8000 pytest tests/test_live_smoke.py
"""

import os

import httpx
import pytest

BASE_URL = os.getenv("BASE_URL")

pytestmark = pytest.mark.skipif(
    not BASE_URL, reason="set BASE_URL to run the smoke tests against a live API"
)


def test_health():
    response = httpx.get(f"{BASE_URL}/health", timeout=10)
    assert response.status_code == 200
    assert response.json().get("status") == "ok"


def test_admin_table_service():
    response = httpx.get(f"{BASE_URL}/api/admin/table/service", timeout=10)
    assert response.status_code == 200
    payload = response.json()
    assert "items" in payload


def test_pansionat_availability():
    response = httpx.get(f"{BASE_URL}/api/pansionats/availability", timeout=10)
    assert response.status_code == 200
    payload = response.json()
    assert "items" in payload


def test_contracts_occupancy():
    response = httpx.get(
        f"{BASE_URL}/api/contracts/occupancy",
        params={"date_from": "2025-01-01", "date_to": "2025-12-31"},
        timeout=10,
    )
    assert response.status_code == 200
    payload = response.json()
    assert "items" in payload


def test_manager_contracts_status():
    response = httpx.get(
        f"{BASE_URL}/api/manager/contracts/status",
        params={"manager_id": 1},
        timeout=10,
    )
    assert response.status_code == 200
    payload = response.json()
    assert "items" in payload
