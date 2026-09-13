"""Test fixtures: an in-memory SQLite database and a TestClient bound to it.

The tests need no SQL Server and no network, so they can run in CI. What they
cannot cover is the T-SQL layer - stored procedures, triggers and the CHECK
constraints from sql/ exist only on SQL Server; see tests/test_live_smoke.py
for checks against a real deployment.
"""

import os

# app.db builds the engine at import time, so a URL has to be present before the
# application package is imported. The tests themselves run against the separate
# SQLite engine created below.
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")

from datetime import date

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import get_db
from app.main import app
from app.models import (
    Administrator,
    Base,
    Contract,
    HealthProfile,
    Manager,
    Pansionat,
    Resident,
    Room,
    RoomType,
    Service,
    StatusOfContract,
    StatusRoom,
)


def seed(session: Session) -> None:
    """Mirror of sql/03_seed_mssql.sql, so the tests see the demo dataset."""
    administrator = Administrator(
        surname="Иванов",
        name="Иван",
        otchestvo="Иванович",
        adress="Адрес 1",
        mail="admin1@example.com",
        telephone=79000000001,
    )
    manager = Manager(
        surname="Петров",
        name="Петр",
        otchestvo="Петрович",
        adress="Адрес 2",
        mail="manager1@example.com",
        telephone=79000000002,
    )
    profiles = [
        HealthProfile(profile=name)
        for name in ("сердце", "нервы", "опорно-двигательный")
    ]
    room_statuses = [StatusRoom(status=True), StatusRoom(status=False)]
    contract_statuses = [StatusOfContract(status=True), StatusOfContract(status=False)]
    room_types = [RoomType(type="Стандарт"), RoomType(type="Люкс")]
    services = [
        Service(name="Массаж", price=1000, time="60 мин"),
        Service(name="Бассейн", price=500, time="30 мин"),
        Service(name="Сауна", price=800, time="45 мин"),
    ]
    session.add_all(
        [administrator, manager, *profiles, *room_statuses, *contract_statuses,
         *room_types, *services]
    )
    session.flush()

    first = Pansionat(
        name="Пансионат 1",
        buiding_year=2010,
        administrator_id=administrator.id_administrator,
        health_profile=profiles[0],
    )
    second = Pansionat(
        name="Пансионат 2",
        buiding_year=2015,
        administrator_id=administrator.id_administrator,
        health_profile=profiles[1],
    )
    first.administrators.append(administrator)
    second.administrators.append(administrator)
    first.services.extend(services)
    second.services.append(services[1])
    session.add_all([first, second])
    session.flush()

    rooms = [
        Room(price=2000, pansionat=first, room_type=room_types[0], status_room=room_statuses[0]),
        Room(price=3500, pansionat=first, room_type=room_types[1], status_room=room_statuses[0]),
        Room(price=1800, pansionat=second, room_type=room_types[0], status_room=room_statuses[0]),
    ]
    residents = [
        Resident(
            surname="Сидоров", name="Сидор", otchestvo="Сидорович",
            mail="res1@example.com", telephone=79000000003, passport=1234567890,
            manager=manager,
        ),
        Resident(
            surname="Ильина", name="Анна", otchestvo="Павловна",
            mail="res2@example.com", telephone=79000000004, passport=2345678901,
            manager=manager,
        ),
    ]
    residents[0].services.extend([services[0], services[1]])
    residents[1].services.append(services[1])
    session.add_all([*rooms, *residents])
    session.flush()

    # uq_contract_room and uq_contract_resident allow one contract per room and
    # per resident, so these two use different rooms and different residents.
    session.add_all(
        [
            Contract(
                start_date=date(2025, 1, 10), final_date=date(2025, 1, 20), summa=20000,
                manager=manager, room=rooms[0], resident=residents[0],
                status_of_contract=contract_statuses[0],
            ),
            Contract(
                start_date=date(2025, 2, 5), final_date=date(2025, 2, 15), summa=18000,
                manager=manager, room=rooms[2], resident=residents[1],
                status_of_contract=contract_statuses[0],
            ),
        ]
    )
    session.commit()


@pytest.fixture
def session_factory():
    """A fresh in-memory database per test, seeded with the demo dataset."""
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        # StaticPool keeps every session on the one connection that owns the
        # in-memory database; check_same_thread lets TestClient's worker use it.
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
        future=True,
    )

    # SQLite ignores foreign keys unless asked; without this the ON DELETE
    # CASCADE paths the models rely on would silently leave orphan rows.
    @event.listens_for(engine, "connect")
    def enable_foreign_keys(dbapi_connection, _connection_record):
        dbapi_connection.execute("PRAGMA foreign_keys=ON")

    Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
    with factory() as session:
        seed(session)
    yield factory
    engine.dispose()


@pytest.fixture
def client(session_factory):
    def override_get_db():
        db = session_factory()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
