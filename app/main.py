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
    Service,
    StatusOfContract,
    provision_of_services,
)
from .schemas import ContractCreate, ContractUpdate, PansionatCreate, PansionatUpdate

app = FastAPI(
    title="Sanatorium API",
    description="Queries against MSSQL with Swagger UI (FastAPI).",
    version="0.2.0",
)


@app.on_event("startup")
def ensure_tables():
    Base.metadata.create_all(bind=engine)


@app.post("/api/pansionats", summary="Create pansionat and link services")
def create_pansionat(payload: PansionatCreate, db: Session = Depends(get_db)):
    try:
        admin = db.get(Administrator, payload.administrator_id)
        if not admin:
            raise HTTPException(status_code=400, detail="Administrator not found")
        profile = db.get(HealthProfile, payload.health_profile_id)
        if not profile:
            raise HTTPException(status_code=400, detail="Health profile not found")

        pansionat = Pansionat(
            name=payload.name,
            photo=payload.photo,
            buiding_year=payload.buiding_year,
            administrator=admin,
            health_profile=profile,
        )
        db.add(pansionat)
        db.flush()

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


@app.put("/api/pansionats/{pansionat_id}", summary="Update pansionat info")
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
        elif field == "administrator_id":
            admin = db.get(Administrator, value)
            if not admin:
                raise HTTPException(status_code=400, detail="Administrator not found")
            pansionat.administrator = admin
        elif field == "health_profile_id":
            profile = db.get(HealthProfile, value)
            if not profile:
                raise HTTPException(status_code=400, detail="Health profile not found")
            pansionat.health_profile = profile
        else:
            setattr(pansionat, field, value)

    db.commit()
    return {"status": "ok"}


@app.delete("/api/pansionats/{pansionat_id}", summary="Delete pansionat")
def delete_pansionat(pansionat_id: int, db: Session = Depends(get_db)):
    pansionat = db.get(Pansionat, pansionat_id)
    if not pansionat:
        raise HTTPException(status_code=404, detail="Pansionat not found")
    db.delete(pansionat)
    db.commit()
    return {"status": "deleted"}


@app.get("/api/pansionats/availability", summary="Aggregated services availability")
def availability_report(db: Session = Depends(get_db)):
    stmt = (
        select(
            Pansionat.id_pansionat,
            Pansionat.name,
            func.count(provision_of_services.c.service).label("service_count"),
        )
        .join(provision_of_services, provision_of_services.c.pansionat == Pansionat.id_pansionat, isouter=True)
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    rows = db.execute(stmt).mappings().all()
    return {"items": rows}


@app.get("/api/pansionats/stats", summary="Technical characteristics stats")
def pansionat_stats(db: Session = Depends(get_db)):
    stmt = select(
        Pansionat.buiding_year.label("year"),
        func.count().label("pansionats"),
    ).group_by(Pansionat.buiding_year)
    return {"items": db.execute(stmt).mappings().all()}


@app.post("/api/contracts", summary="Create contract")
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
    return {"id_dogovor": contract.id_dogovor}


@app.put("/api/contracts/{contract_id}", summary="Update contract fields")
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


@app.delete("/api/contracts/{contract_id}", summary="Delete contract")
def delete_contract(contract_id: int, db: Session = Depends(get_db)):
    contract = db.get(Contract, contract_id)
    if not contract:
        raise HTTPException(status_code=404, detail="Contract not found")
    db.delete(contract)
    db.commit()
    return {"status": "deleted"}


@app.get("/api/contracts/occupancy", summary="Occupancy analytics")
def occupancy_report(
    date_from: date = Query(...),
    date_to: date = Query(...),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            Pansionat.id_pansionat.label("pansionat_id"),
            Pansionat.name,
            func.count(Contract.id_dogovor).label("contracts"),
        )
        .join(Room, Room.pansionat == Pansionat.id_pansionat)
        .join(Contract, Contract.room == Room.id_room)
        .where(
            Contract.start_date <= date_to,
            Contract.final_date >= date_from,
        )
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return {"items": db.execute(stmt).mappings().all()}


@app.get("/api/contracts/revenue", summary="Revenue analytics")
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
        .join(Room, Room.pansionat == Pansionat.id_pansionat)
        .join(Contract, Contract.room == Room.id_room)
        .where(
            Contract.start_date >= date_from,
            Contract.final_date <= date_to,
        )
        .group_by(Pansionat.id_pansionat, Pansionat.name)
    )
    return {"items": db.execute(stmt).mappings().all()}


@app.get("/health")
def health():
    return {"status": "ok"}
