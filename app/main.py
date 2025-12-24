from datetime import date

from fastapi import Depends, FastAPI, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .db import engine, get_db
from .models import (
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
    StatusRoom,
    StatusOfContract,
    provision_of_services,
    using_service,
    vladenie,
)
from .schemas import ContractCreate, ContractUpdate, PansionatCreate, PansionatUpdate

openapi_tags = [
    {
        "name": "Admin: Pansionat",
        "description": "CRUD for pansionats.",
    },
    {
        "name": "Admin: Analytics",
        "description": "Analytics for availability, stats, revenue, and service usage.",
    },
    {
        "name": "Admin: Triggers",
        "description": (
            "DB triggers (informational): price bump for all services when adding a new service to a pansionat, "
            "and 20% discount for services when health profile is 'сердечно-сосудистый'."
        ),
    },
    {
        "name": "Manager: Contracts",
        "description": "Create/update/delete contracts.",
    },
    {
        "name": "Manager: Analytics",
        "description": "Analytics for occupancy and revenue by manager.",
    },
    {
        "name": "Manager: Triggers",
        "description": (
            "DB triggers (informational): early booking discount and auto-close finished contracts."
        ),
    },
    {
        "name": "System",
        "description": "Health check.",
    },
]

app = FastAPI(
    title="Sanatorium API",
    description="Queries against MSSQL with Swagger UI (FastAPI).",
    version="0.3.0",
    openapi_tags=openapi_tags,
)

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


@app.on_event("startup")
def ensure_tables():
    Base.metadata.create_all(bind=engine)


@app.post("/api/pansionats", summary="Create pansionat and link services", tags=["Admin: Pansionat"])
def create_pansionat(payload: PansionatCreate, db: Session = Depends(get_db)):
    try:
        profile = db.get(HealthProfile, payload.health_profile_id)
        if not profile:
            raise HTTPException(status_code=400, detail="Health profile not found")

        if not payload.administrator_ids:
            raise HTTPException(status_code=400, detail="administrator_ids is required")
        admins = db.query(Administrator).filter(Administrator.id_administrator.in_(payload.administrator_ids)).all()
        if len(admins) != len(set(payload.administrator_ids)):
            raise HTTPException(status_code=400, detail="One or more administrators not found")

        pansionat = Pansionat(
            name=payload.name,
            photo=payload.photo,
            buiding_year=payload.building_year.year,
            health_profile=profile,
        )
        # Main administrator for FK column.
        pansionat.administrator_id = admins[0].id_administrator

        db.add(pansionat)
        db.flush()

        for admin in admins:
            pansionat.administrators.append(admin)

        if payload.service_ids:
            services = db.query(Service).filter(Service.id_service.in_(payload.service_ids)).all()
            if len(services) != len(set(payload.service_ids)):
                raise HTTPException(status_code=400, detail="One or more services not found")
            for svc in services:
                pansionat.services.append(svc)

        db.commit()
        db.refresh(pansionat)
        return {"id_pansionat": pansionat.id_pansionat}
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Integrity error: {exc.orig}") from exc


@app.put("/api/pansionats/{pansionat_id}", summary="Update pansionat info", tags=["Admin: Pansionat"])
def update_pansionat(pansionat_id: int, payload: PansionatUpdate, db: Session = Depends(get_db)):
    pansionat = db.get(Pansionat, pansionat_id)
    if not pansionat:
        raise HTTPException(status_code=404, detail="Pansionat not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        if field == "service_ids":
            pansionat.services.clear()
            if value:
                services = db.query(Service).filter(Service.id_service.in_(value)).all()
                if len(services) != len(set(value)):
                    raise HTTPException(status_code=400, detail="One or more services not found")
                for svc in services:
                    pansionat.services.append(svc)
        elif field == "administrator_ids":
            pansionat.administrators.clear()
            if value:
                admins = db.query(Administrator).filter(Administrator.id_administrator.in_(value)).all()
                if len(admins) != len(set(value)):
                    raise HTTPException(status_code=400, detail="One or more administrators not found")
                for admin in admins:
                    pansionat.administrators.append(admin)
                pansionat.administrator_id = admins[0].id_administrator
            else:
                raise HTTPException(status_code=400, detail="administrator_ids cannot be empty")
        elif field == "health_profile_id":
            profile = db.get(HealthProfile, value)
            if not profile:
                raise HTTPException(status_code=400, detail="Health profile not found")
            pansionat.health_profile = profile
        elif field == "building_year":
            pansionat.buiding_year = value.year
        else:
            setattr(pansionat, field, value)

    db.commit()
    return {"status": "ok"}


@app.delete("/api/pansionats/{pansionat_id}", summary="Delete pansionat", tags=["Admin: Pansionat"])
def delete_pansionat(pansionat_id: int, db: Session = Depends(get_db)):
    pansionat = db.get(Pansionat, pansionat_id)
    if not pansionat:
        raise HTTPException(status_code=404, detail="Pansionat not found")
    db.delete(pansionat)
    db.commit()
    return {"status": "deleted"}


@app.get("/api/pansionats/availability", summary="Aggregated services availability", tags=["Admin: Analytics"])
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
    rows = db.execute(stmt).mappings().all()
    return {"items": rows}


@app.get("/api/pansionats/stats", summary="Technical characteristics stats", tags=["Admin: Analytics"])
def pansionat_stats(db: Session = Depends(get_db)):
    stmt = select(
        Pansionat.buiding_year.label("year"),
        func.count().label("pansionats"),
    ).group_by(Pansionat.buiding_year)
    return {"items": db.execute(stmt).mappings().all()}


@app.post("/api/contracts", summary="Create contract", tags=["Manager: Contracts"])
def create_contract(payload: ContractCreate, db: Session = Depends(get_db)):
    manager = db.get(Manager, payload.manager_id)
    if not manager:
        raise HTTPException(status_code=400, detail="Manager not found")
    room = db.get(Room, payload.room_id)
    if not room:
        raise HTTPException(status_code=400, detail="Room not found")
    resident = db.get(Resident, payload.resident_id)
    if not resident:
        raise HTTPException(status_code=400, detail="Resident not found")
    status = db.get(StatusOfContract, payload.status_of_contract_id)
    if not status:
        raise HTTPException(status_code=400, detail="Status_of_contract not found")

    contract = Contract(
        start_date=payload.start_date,
        final_date=payload.final_date,
        summa=payload.summa,
        manager=manager,
        room=room,
        resident=resident,
        status_of_contract=status,
    )
    db.add(contract)
    db.commit()
    db.refresh(contract)
    return {"id_contract": contract.id_contract}


@app.put("/api/contracts/{contract_id}", summary="Update contract fields", tags=["Manager: Contracts"])
def update_contract(contract_id: int, payload: ContractUpdate, db: Session = Depends(get_db)):
    contract = db.get(Contract, contract_id)
    if not contract:
        raise HTTPException(status_code=404, detail="Contract not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        if field == "manager_id":
            manager = db.get(Manager, value)
            if not manager:
                raise HTTPException(status_code=400, detail="Manager not found")
            contract.manager = manager
        elif field == "room_id":
            room = db.get(Room, value)
            if not room:
                raise HTTPException(status_code=400, detail="Room not found")
            contract.room = room
        elif field == "resident_id":
            resident = db.get(Resident, value)
            if not resident:
                raise HTTPException(status_code=400, detail="Resident not found")
            contract.resident = resident
        elif field == "status_of_contract_id":
            status = db.get(StatusOfContract, value)
            if not status:
                raise HTTPException(status_code=400, detail="Status_of_contract not found")
            contract.status_of_contract = status
        else:
            setattr(contract, field, value)

    db.commit()
    return {"status": "ok"}


@app.delete("/api/contracts/{contract_id}", summary="Delete contract", tags=["Manager: Contracts"])
def delete_contract(contract_id: int, db: Session = Depends(get_db)):
    contract = db.get(Contract, contract_id)
    if not contract:
        raise HTTPException(status_code=404, detail="Contract not found")
    db.delete(contract)
    db.commit()
    return {"status": "deleted"}


@app.get("/api/contracts/occupancy", summary="Occupancy analytics", tags=["Manager: Analytics"])
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
        .where(
            Contract.start_date <= date_to,
            Contract.final_date >= date_from,
        )
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return {"items": db.execute(stmt).mappings().all()}


@app.get("/api/contracts/revenue", summary="Revenue analytics", tags=["Manager: Analytics"])
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
        .where(
            Contract.start_date >= date_from,
            Contract.final_date <= date_to,
        )
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return {"items": db.execute(stmt).mappings().all()}


@app.get(
    "/api/admin/pansionats/summary",
    summary="Admin summary: pansionats, rooms, residents, services",
    tags=["Admin: Analytics"],
)
def admin_summary(
    administrator_id: int = Query(...),
    db: Session = Depends(get_db),
):
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
        .join(Resident, Resident.pansionat_id == Pansionat.id_pansionat, isouter=True)
        .join(
            provision_of_services,
            provision_of_services.c.pansionat == Pansionat.id_pansionat,
            isouter=True,
        )
        .join(Service, Service.id_service == provision_of_services.c.service, isouter=True)
        .where(Administrator.id_administrator == administrator_id)
        .group_by(Administrator.id_administrator)
    )
    row = db.execute(stmt).mappings().first()
    if not row:
        raise HTTPException(status_code=404, detail="Administrator not found or no pansionats")
    return row


@app.get(
    "/api/admin/contracts/revenue",
    summary="Admin revenue by pansionat in period",
    tags=["Admin: Analytics"],
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
    return {"items": db.execute(stmt).mappings().all()}


@app.get(
    "/api/admin/services/top",
    summary="Top services used in admin pansionats",
    tags=["Admin: Analytics"],
)
def admin_top_services(
    administrator_id: int = Query(...),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            Service.id_service.label("service_id"),
            Service.name,
            func.count(using_service.c.resident).label("usage_count"),
        )
        .join(using_service, using_service.c.service == Service.id_service)
        .join(Resident, Resident.id_resident == using_service.c.resident)
        .join(Pansionat, Pansionat.id_pansionat == Resident.pansionat_id)
        .join(vladenie, vladenie.c.pansionat == Pansionat.id_pansionat)
        .where(vladenie.c.administrator == administrator_id)
        .group_by(Service.id_service, Service.name)
        .order_by(func.count(using_service.c.resident).desc())
        .limit(limit)
    )
    return {"items": db.execute(stmt).mappings().all()}


@app.get(
    "/api/admin/table/{table_name}",
    summary="Get all rows from a table",
    tags=["Admin: Analytics"],
)
def get_table_rows(table_name: str, db: Session = Depends(get_db)):
    table = ALLOWED_TABLES.get(table_name.lower())
    if table is None:
        raise HTTPException(
            status_code=400,
            detail="Unknown table. Allowed: " + ", ".join(sorted(ALLOWED_TABLES.keys())),
        )
    rows = db.execute(select(table)).mappings().all()
    return {"items": rows}


@app.get(
    "/api/manager/contracts/status",
    summary="Manager contracts grouped by status",
    tags=["Manager: Analytics"],
)
def manager_contract_status(
    manager_id: int = Query(...),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            StatusOfContract.status.label("status"),
            func.count(Contract.id_contract).label("contracts"),
            func.sum(Contract.summa).label("total_revenue"),
        )
        .join(Contract, Contract.status_of_contract_id == StatusOfContract.id_status_of_contract)
        .where(Contract.manager_id == manager_id)
        .group_by(StatusOfContract.status)
        .order_by(StatusOfContract.status.desc())
    )
    return {"items": db.execute(stmt).mappings().all()}


@app.get(
    "/api/manager/contracts/period",
    summary="Manager contracts in period",
    tags=["Manager: Analytics"],
)
def manager_contract_period(
    manager_id: int = Query(...),
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            func.count(Contract.id_contract).label("contracts"),
            func.sum(Contract.summa).label("total_revenue"),
            func.avg(Contract.summa).label("avg_check"),
        )
        .where(
            Contract.manager_id == manager_id,
            Contract.start_date >= date_from,
            Contract.final_date <= date_to,
        )
    )
    return db.execute(stmt).mappings().first()


@app.get(
    "/api/manager/rooms/types",
    summary="Manager contracts by room type in period",
    tags=["Manager: Analytics"],
)
def manager_room_type_stats(
    manager_id: int = Query(...),
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            RoomType.type.label("room_type"),
            func.count(Contract.id_contract).label("contracts"),
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
        .order_by(func.count(Contract.id_contract).desc())
    )
    return {"items": db.execute(stmt).mappings().all()}


@app.get("/health", tags=["System"])
def health():
    return {"status": "ok"}
