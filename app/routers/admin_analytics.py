"""Administrator workstation: aggregate reports."""

from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import (
    Administrator,
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
    provision_of_services,
    using_service,
    vladenie,
)
from ..schemas import (
    AdminRevenueItem,
    AdminSummary,
    AvailabilityItem,
    Items,
    PansionatYearStat,
    TableRows,
    TopServiceItem,
)
from .common import as_dicts, first_dict, items

router = APIRouter(tags=["Admin: Analytics"])

# Whitelist for the raw table dump: a name outside this mapping is rejected, so
# the path parameter can never reach the database as an identifier.
ALLOWED_TABLES = {
    "manager": Manager.__table__,
    "administrator": Administrator.__table__,
    "health_profile": HealthProfile.__table__,
    "status_room": StatusRoom.__table__,
    "status_of_contract": StatusOfContract.__table__,
    "room_type": RoomType.__table__,
    "pansionat": Pansionat.__table__,
    "service": Service.__table__,
    "room": Room.__table__,
    "resident": Resident.__table__,
    "contract": Contract.__table__,
    "provision_of_services": provision_of_services,
    "using_service": using_service,
    "vladenie": vladenie,
}


@router.get(
    "/api/pansionats/availability",
    response_model=Items[AvailabilityItem],
    summary="Aggregated services availability",
)
def availability_report(db: Session = Depends(get_db)):
    stmt = (
        select(
            Pansionat.id_pansionat,
            Pansionat.name,
            func.count(provision_of_services.c.service).label("service_count"),
        )
        .join(
            provision_of_services,
            provision_of_services.c.pansionat == Pansionat.id_pansionat,
            isouter=True,
        )
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return items(db.execute(stmt))


@router.get(
    "/api/pansionats/stats",
    response_model=Items[PansionatYearStat],
    summary="Technical characteristics stats",
)
def pansionat_stats(db: Session = Depends(get_db)):
    stmt = select(
        Pansionat.buiding_year.label("year"),
        func.count().label("pansionats"),
    ).group_by(Pansionat.buiding_year)
    return items(db.execute(stmt))


@router.get(
    "/api/admin/pansionats/summary",
    response_model=AdminSummary,
    summary="Admin summary: pansionats, rooms, residents, services",
)
def admin_summary(administrator_id: int = Query(...), db: Session = Depends(get_db)):
    stmt = (
        select(
            Administrator.id_administrator.label("administrator_id"),
            func.count(func.distinct(Pansionat.id_pansionat)).label("pansionats"),
            func.count(func.distinct(Room.id_room)).label("rooms"),
            func.count(func.distinct(Resident.id_resident)).label("residents"),
            func.count(func.distinct(Service.id_service)).label("services"),
        )
        .select_from(Administrator)
        .join(vladenie, vladenie.c.administrator == Administrator.id_administrator)
        .join(Pansionat, Pansionat.id_pansionat == vladenie.c.pansionat)
        .join(Room, Room.pansionat_id == Pansionat.id_pansionat, isouter=True)
        .join(Contract, Contract.room_id == Room.id_room, isouter=True)
        .join(Resident, Resident.id_resident == Contract.resident_id, isouter=True)
        .join(
            provision_of_services,
            provision_of_services.c.pansionat == Pansionat.id_pansionat,
            isouter=True,
        )
        .join(Service, Service.id_service == provision_of_services.c.service, isouter=True)
        .where(Administrator.id_administrator == administrator_id)
        .group_by(Administrator.id_administrator)
    )
    row = first_dict(db.execute(stmt))
    if row is None:
        raise HTTPException(status_code=404, detail="Administrator not found or no pansionats")
    return row


@router.get(
    "/api/admin/contracts/revenue",
    response_model=Items[AdminRevenueItem],
    summary="Admin revenue by pansionat in period",
)
def admin_revenue(
    administrator_id: int = Query(...),
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            Pansionat.id_pansionat.label("pansionat_id"),
            Pansionat.name,
            func.count(Contract.id_contract).label("contracts"),
            func.sum(Contract.summa).label("total_revenue"),
            func.avg(Contract.summa).label("avg_check"),
        )
        .join(vladenie, vladenie.c.pansionat == Pansionat.id_pansionat)
        .join(Room, Room.pansionat_id == Pansionat.id_pansionat)
        .join(Contract, Contract.room_id == Room.id_room)
        .where(
            vladenie.c.administrator == administrator_id,
            Contract.start_date >= date_from,
            Contract.final_date <= date_to,
        )
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return items(db.execute(stmt))


@router.get(
    "/api/admin/services/top",
    response_model=Items[TopServiceItem],
    summary="Top services offered in admin pansionats",
)
def admin_top_services(
    administrator_id: int = Query(...),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    offering_count = func.count(func.distinct(provision_of_services.c.pansionat))
    stmt = (
        select(
            Service.id_service.label("service_id"),
            Service.name,
            offering_count.label("pansionat_count"),
        )
        .join(provision_of_services, provision_of_services.c.service == Service.id_service)
        .join(Pansionat, Pansionat.id_pansionat == provision_of_services.c.pansionat)
        .join(vladenie, vladenie.c.pansionat == Pansionat.id_pansionat)
        .where(vladenie.c.administrator == administrator_id)
        .group_by(Service.id_service, Service.name)
        .order_by(offering_count.desc())
        .limit(limit)
    )
    return items(db.execute(stmt))


@router.get(
    "/api/admin/table/{table_name}",
    response_model=TableRows,
    summary="Get all rows from a table",
)
def get_table_rows(table_name: str, db: Session = Depends(get_db)):
    table = ALLOWED_TABLES.get(table_name.lower())
    if table is None:
        raise HTTPException(
            status_code=400,
            detail="Unknown table. Allowed: " + ", ".join(sorted(ALLOWED_TABLES)),
        )
    return TableRows(items=as_dicts(db.execute(select(table))))
