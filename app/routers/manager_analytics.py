"""Manager workstation: occupancy and revenue reports."""

from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Contract, Pansionat, Room, RoomType, StatusOfContract
from ..schemas import (
    ContractStatusItem,
    Items,
    ManagerPeriodTotals,
    OccupancyItem,
    RevenueItem,
    RoomTypeItem,
)
from .common import first_dict, items

router = APIRouter(tags=["Manager: Analytics"])


@router.get(
    "/api/contracts/occupancy",
    response_model=Items[OccupancyItem],
    summary="Occupancy analytics",
)
def occupancy_report(
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            Pansionat.id_pansionat.label("pansionat_id"),
            Pansionat.name,
            func.count(Contract.id_contract).label("contracts"),
        )
        .join(Room, Room.pansionat_id == Pansionat.id_pansionat)
        .join(Contract, Contract.room_id == Room.id_room)
        # Overlap, not containment: a contract counts if it touches the period.
        .where(Contract.start_date <= date_to, Contract.final_date >= date_from)
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return items(db.execute(stmt))


@router.get(
    "/api/contracts/revenue",
    response_model=Items[RevenueItem],
    summary="Revenue analytics",
)
def revenue_report(
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            Pansionat.id_pansionat.label("pansionat_id"),
            Pansionat.name,
            func.sum(Contract.summa).label("total_revenue"),
            func.avg(Contract.summa).label("avg_check"),
        )
        .join(Room, Room.pansionat_id == Pansionat.id_pansionat)
        .join(Contract, Contract.room_id == Room.id_room)
        .where(Contract.start_date >= date_from, Contract.final_date <= date_to)
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return items(db.execute(stmt))


@router.get(
    "/api/manager/contracts/status",
    response_model=Items[ContractStatusItem],
    summary="Manager contracts grouped by status",
)
def manager_contract_status(manager_id: int = Query(...), db: Session = Depends(get_db)):
    stmt = (
        select(
            StatusOfContract.status.label("status"),
            func.count(Contract.id_contract).label("contracts"),
            func.sum(Contract.summa).label("total_revenue"),
        )
        .join(
            Contract,
            Contract.status_of_contract_id == StatusOfContract.id_status_of_contract,
        )
        .where(Contract.manager_id == manager_id)
        .group_by(StatusOfContract.status)
        .order_by(StatusOfContract.status.desc())
    )
    return items(db.execute(stmt))


@router.get(
    "/api/manager/contracts/period",
    response_model=ManagerPeriodTotals,
    summary="Manager contracts in period",
)
def manager_contract_period(
    manager_id: int = Query(...),
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    stmt = select(
        func.count(Contract.id_contract).label("contracts"),
        func.sum(Contract.summa).label("total_revenue"),
        func.avg(Contract.summa).label("avg_check"),
    ).where(
        Contract.manager_id == manager_id,
        Contract.start_date >= date_from,
        Contract.final_date <= date_to,
    )
    return first_dict(db.execute(stmt))


@router.get(
    "/api/manager/rooms/types",
    response_model=Items[RoomTypeItem],
    summary="Manager contracts by room type in period",
)
def manager_room_type_stats(
    manager_id: int = Query(...),
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    contract_count = func.count(Contract.id_contract)
    stmt = (
        select(
            RoomType.type.label("room_type"),
            contract_count.label("contracts"),
            func.sum(Contract.summa).label("total_revenue"),
        )
        .join(Room, Room.type_id == RoomType.id_type)
        .join(Contract, Contract.room_id == Room.id_room)
        .where(
            Contract.manager_id == manager_id,
            Contract.start_date >= date_from,
            Contract.final_date <= date_to,
        )
        .group_by(RoomType.type)
        .order_by(contract_count.desc())
    )
    return items(db.execute(stmt))
