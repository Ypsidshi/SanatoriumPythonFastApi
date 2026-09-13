"""Administrator workstation: pansionat CRUD."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Administrator, HealthProfile, Pansionat, Service
from ..schemas import PansionatCreate, PansionatCreated, PansionatUpdate, StatusResponse
from .common import load_all, require

router = APIRouter(tags=["Admin: Pansionat"])


@router.post(
    "/api/pansionats",
    response_model=PansionatCreated,
    summary="Create pansionat and link services",
)
def create_pansionat(payload: PansionatCreate, db: Session = Depends(get_db)) -> PansionatCreated:
    profile = require(db, HealthProfile, payload.health_profile_id, "Health profile")

    if not payload.administrator_ids:
        raise HTTPException(status_code=400, detail="administrator_ids is required")
    admins = load_all(
        db, Administrator, Administrator.id_administrator, payload.administrator_ids, "administrators"
    )

    pansionat = Pansionat(
        name=payload.name,
        photo=payload.photo,
        buiding_year=payload.building_year.year,
        health_profile=profile,
        # Main administrator for the FK column; the rest go into `vladenie`.
        administrator_id=admins[0].id_administrator,
    )
    db.add(pansionat)
    db.flush()

    pansionat.administrators.extend(admins)
    if payload.service_ids:
        pansionat.services.extend(
            load_all(db, Service, Service.id_service, payload.service_ids, "services")
        )

    db.commit()
    db.refresh(pansionat)
    return PansionatCreated(id_pansionat=pansionat.id_pansionat)


@router.put(
    "/api/pansionats/{pansionat_id}",
    response_model=StatusResponse,
    summary="Update pansionat info",
)
def update_pansionat(
    pansionat_id: int, payload: PansionatUpdate, db: Session = Depends(get_db)
) -> StatusResponse:
    pansionat = db.get(Pansionat, pansionat_id)
    if pansionat is None:
        raise HTTPException(status_code=404, detail="Pansionat not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        if field == "service_ids":
            pansionat.services.clear()
            if value:
                pansionat.services.extend(
                    load_all(db, Service, Service.id_service, value, "services")
                )
        elif field == "administrator_ids":
            if not value:
                raise HTTPException(status_code=400, detail="administrator_ids cannot be empty")
            admins = load_all(
                db, Administrator, Administrator.id_administrator, value, "administrators"
            )
            pansionat.administrators.clear()
            pansionat.administrators.extend(admins)
            pansionat.administrator_id = admins[0].id_administrator
        elif field == "health_profile_id":
            pansionat.health_profile = require(db, HealthProfile, value, "Health profile")
        elif field == "building_year":
            pansionat.buiding_year = value.year
        else:
            setattr(pansionat, field, value)

    db.commit()
    return StatusResponse(status="ok")


@router.delete(
    "/api/pansionats/{pansionat_id}",
    response_model=StatusResponse,
    summary="Delete pansionat",
)
def delete_pansionat(pansionat_id: int, db: Session = Depends(get_db)) -> StatusResponse:
    pansionat = db.get(Pansionat, pansionat_id)
    if pansionat is None:
        raise HTTPException(status_code=404, detail="Pansionat not found")
    db.delete(pansionat)
    db.commit()
    return StatusResponse(status="deleted")
