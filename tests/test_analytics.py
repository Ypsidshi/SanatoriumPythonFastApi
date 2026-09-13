"""Analytics endpoints, checked against the seeded demo dataset."""

PERIOD = {"date_from": "2025-01-01", "date_to": "2025-12-31"}


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_availability_counts_linked_services(client):
    rows = {row["id_pansionat"]: row for row in client.get("/api/pansionats/availability").json()["items"]}
    assert rows[1]["service_count"] == 3
    assert rows[2]["service_count"] == 1


def test_stats_group_pansionats_by_building_year(client):
    rows = {row["year"]: row["pansionats"] for row in client.get("/api/pansionats/stats").json()["items"]}
    assert rows == {2010: 1, 2015: 1}


def test_admin_summary(client):
    body = client.get("/api/admin/pansionats/summary", params={"administrator_id": 1}).json()
    assert body["administrator_id"] == 1
    assert body["pansionats"] == 2
    assert body["rooms"] == 3
    assert body["residents"] == 2
    assert body["services"] == 3


def test_admin_summary_for_an_unknown_administrator_is_404(client):
    response = client.get("/api/admin/pansionats/summary", params={"administrator_id": 999})
    assert response.status_code == 404


def test_admin_revenue_per_pansionat(client):
    params = {"administrator_id": 1, **PERIOD}
    rows = client.get("/api/admin/contracts/revenue", params=params).json()["items"]
    revenue = {row["pansionat_id"]: row["total_revenue"] for row in rows}
    assert revenue == {1: 20000, 2: 18000}


def test_admin_top_services_is_ordered_and_limited(client):
    rows = client.get("/api/admin/services/top", params={"administrator_id": 1, "limit": 2}).json()["items"]
    assert len(rows) == 2
    counts = [row["pansionat_count"] for row in rows]
    assert counts == sorted(counts, reverse=True)
    # "Бассейн" is the only service offered by both pansionats.
    assert rows[0]["pansionat_count"] == 2


def test_occupancy_counts_overlapping_contracts(client):
    rows = client.get("/api/contracts/occupancy", params=PERIOD).json()["items"]
    assert {row["pansionat_id"]: row["contracts"] for row in rows} == {1: 1, 2: 1}


def test_occupancy_uses_overlap_not_containment(client):
    """Contract 1 runs 10-20 Jan, so a window that only clips its tail counts it."""
    rows = client.get(
        "/api/contracts/occupancy", params={"date_from": "2025-01-18", "date_to": "2025-01-25"}
    ).json()["items"]
    assert {row["pansionat_id"] for row in rows} == {1}


def test_revenue_report(client):
    rows = client.get("/api/contracts/revenue", params=PERIOD).json()["items"]
    assert {row["pansionat_id"]: row["total_revenue"] for row in rows} == {1: 20000, 2: 18000}


def test_manager_contracts_by_status(client):
    rows = client.get("/api/manager/contracts/status", params={"manager_id": 1}).json()["items"]
    assert rows == [{"status": True, "contracts": 2, "total_revenue": 38000}]


def test_manager_period_totals(client):
    body = client.get("/api/manager/contracts/period", params={"manager_id": 1, **PERIOD}).json()
    assert body["contracts"] == 2
    assert body["total_revenue"] == 38000
    assert body["avg_check"] == 19000


def test_manager_period_totals_are_empty_outside_the_range(client):
    body = client.get(
        "/api/manager/contracts/period",
        params={"manager_id": 1, "date_from": "2030-01-01", "date_to": "2030-12-31"},
    ).json()
    assert body == {"contracts": 0, "total_revenue": None, "avg_check": None}


def test_manager_room_type_stats(client):
    rows = client.get("/api/manager/rooms/types", params={"manager_id": 1, **PERIOD}).json()["items"]
    assert {row["room_type"]: row["contracts"] for row in rows} == {"Стандарт": 2}


def test_table_dump_is_restricted_to_the_whitelist(client):
    assert client.get("/api/admin/table/service").status_code == 200

    for name in ("users", "sys.objects", "contract; DROP TABLE contract"):
        response = client.get(f"/api/admin/table/{name}")
        assert response.status_code == 400, name
        assert "Allowed:" in response.json()["detail"]


def test_period_endpoints_require_their_query_parameters(client):
    assert client.get("/api/contracts/occupancy").status_code == 422
