"""Manager workstation: contract CRUD."""

import pytest


def contract_payload(**overrides):
    payload = {
        "start_date": "2025-06-01",
        "final_date": "2025-06-10",
        "summa": 15000,
        "manager_id": 1,
        "room_id": 2,
        "resident_id": 1,
        "status_of_contract_id": 1,
    }
    payload.update(overrides)
    return payload


def test_create_after_freeing_the_resident(client):
    # The seeded resident 1 already holds contract 1, and uq_contract_resident
    # allows only one, so the old contract has to go first.
    assert client.delete("/api/contracts/1").status_code == 200

    response = client.post("/api/contracts", json=contract_payload())
    assert response.status_code == 200, response.text
    assert response.json()["id_contract"] > 0


def test_create_for_a_resident_who_already_has_one_is_a_conflict(client):
    response = client.post("/api/contracts", json=contract_payload())
    assert response.status_code == 409
    assert "constraint" in response.json()["detail"].lower()


@pytest.mark.parametrize(
    ("field", "expected"),
    [
        ("manager_id", "Manager not found"),
        ("room_id", "Room not found"),
        ("resident_id", "Resident not found"),
        ("status_of_contract_id", "Status_of_contract not found"),
    ],
)
def test_create_rejects_unknown_references(client, field, expected):
    response = client.post("/api/contracts", json=contract_payload(**{field: 999}))
    assert response.status_code == 400
    assert response.json()["detail"] == expected


def test_create_rejects_a_malformed_date(client):
    response = client.post("/api/contracts", json=contract_payload(start_date="not-a-date"))
    assert response.status_code == 422


def test_update_changes_the_sum(client):
    assert client.put("/api/contracts/1", json={"summa": 25000}).json() == {"status": "ok"}

    totals = client.get(
        "/api/manager/contracts/period",
        params={"manager_id": 1, "date_from": "2025-01-01", "date_to": "2025-12-31"},
    ).json()
    assert totals["total_revenue"] == 25000 + 18000


def test_update_rejects_an_unknown_reference(client):
    response = client.put("/api/contracts/1", json={"manager_id": 999})
    assert response.status_code == 400
    assert response.json()["detail"] == "Manager not found"


def test_update_of_a_missing_contract_is_404(client):
    assert client.put("/api/contracts/999", json={"summa": 1}).status_code == 404


def test_delete_removes_the_contract(client):
    assert client.delete("/api/contracts/2").json() == {"status": "deleted"}
    rows = client.get("/api/admin/table/contract").json()["items"]
    assert [row["id_contract"] for row in rows] == [1]


def test_delete_of_a_missing_contract_is_404(client):
    assert client.delete("/api/contracts/999").status_code == 404
