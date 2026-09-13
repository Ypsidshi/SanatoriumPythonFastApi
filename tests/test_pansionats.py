"""Administrator workstation: pansionat CRUD."""


def create_payload(**overrides):
    payload = {
        "name": "Пансионат 3",
        "photo": None,
        "building_year": "2020-01-01",
        "health_profile_id": 1,
        "administrator_ids": [1],
        "service_ids": [1, 2],
    }
    payload.update(overrides)
    return payload


def test_create_links_administrators_and_services(client):
    response = client.post("/api/pansionats", json=create_payload())
    assert response.status_code == 200, response.text
    pansionat_id = response.json()["id_pansionat"]

    rows = client.get("/api/pansionats/availability").json()["items"]
    created = next(row for row in rows if row["id_pansionat"] == pansionat_id)
    assert created["service_count"] == 2
    assert created["name"] == "Пансионат 3"


def test_create_stores_only_the_year_of_building_year(client):
    client.post("/api/pansionats", json=create_payload(building_year="2020-07-15"))
    years = {row["year"] for row in client.get("/api/pansionats/stats").json()["items"]}
    assert 2020 in years


def test_create_rejects_empty_administrator_list(client):
    response = client.post("/api/pansionats", json=create_payload(administrator_ids=[]))
    assert response.status_code == 400
    assert response.json()["detail"] == "administrator_ids is required"


def test_create_rejects_unknown_references(client):
    unknown_profile = client.post("/api/pansionats", json=create_payload(health_profile_id=999))
    assert unknown_profile.status_code == 400
    assert unknown_profile.json()["detail"] == "Health profile not found"

    unknown_service = client.post("/api/pansionats", json=create_payload(service_ids=[1, 999]))
    assert unknown_service.status_code == 400
    assert unknown_service.json()["detail"] == "One or more services not found"


def test_duplicate_name_is_a_conflict(client):
    """`pansionat.name` is UNIQUE, so the second insert hits the constraint."""
    response = client.post("/api/pansionats", json=create_payload(name="Пансионат 1"))
    assert response.status_code == 409
    assert "constraint" in response.json()["detail"].lower()


def test_update_replaces_the_service_links(client):
    response = client.put("/api/pansionats/1", json={"service_ids": [3]})
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

    rows = client.get("/api/pansionats/availability").json()["items"]
    assert next(row for row in rows if row["id_pansionat"] == 1)["service_count"] == 1


def test_update_rejects_an_empty_administrator_list(client):
    response = client.put("/api/pansionats/1", json={"administrator_ids": []})
    assert response.status_code == 400
    assert response.json()["detail"] == "administrator_ids cannot be empty"


def test_update_of_a_missing_pansionat_is_404(client):
    assert client.put("/api/pansionats/999", json={"name": "x"}).status_code == 404


def test_delete_removes_the_pansionat(client):
    assert client.delete("/api/pansionats/2").json() == {"status": "deleted"}
    remaining = {row["id_pansionat"] for row in client.get("/api/pansionats/availability").json()["items"]}
    assert remaining == {1}


def test_delete_of_a_missing_pansionat_is_404(client):
    assert client.delete("/api/pansionats/999").status_code == 404
