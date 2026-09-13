"""Manager workstation: residence contract CRUD."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Contract, Manager, Resident, Room, StatusOfContract
from ..schemas import ContractCreate, ContractCreated, ContractUpdate, StatusResponse
from .common import require

router = APIRouter(tags=["Manager: Contracts"])

# Payload field -> (model, label) for the foreign keys a contract points at.
RELATIONS = {
    "manager_id": (Manager, "manager", "Manager"),
    "room_id": (Room, "room", "Room"),
    "resident_id": (Resident, "resident", "Resident"),
    "status_of_contract_id": (StatusOfContract, "status_of_contract", "Status_of_contract"),
}


@router.post("/api/contracts", response_model=ContractCreated, summary="Create contract")
def create_contract(payload: ContractCreate, db: Session = Depends(get_db)) -> ContractCreated:
    related = {
        attribute: require(db, model, getattr(payload, field), label)
        for field, (model, attribute, label) in RELATIONS.items()
    }

    contract = Contract(
        start_date=payload.start_date,
        final_date=payload.final_date,
        summa=payload.summa,
        **related,
    )
    db.add(contract)
    db.commit()
    db.refresh(contract)
    return ContractCreated(id_contract=contract.id_contract)


@router.put(
    "/api/contracts/{contract_id}",
    response_model=StatusResponse,
    summary="Update contract fields",
)
def update_contract(
    contract_id: int, payload: ContractUpdate, db: Session = Depends(get_db)
) -> StatusResponse:
    contract = db.get(Contract, contract_id)
    if contract is None:
        raise HTTPException(status_code=404, detail="Contract not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        if field in RELATIONS:
            model, attribute, label = RELATIONS[field]
            setattr(contract, attribute, require(db, model, value, label))
        else:
            setattr(contract, field, value)

    db.commit()
    return StatusResponse(status="ok")


@router.delete(
    "/api/contracts/{contract_id}",
    response_model=StatusResponse,
    summary="Delete contract",
)
def delete_contract(contract_id: int, db: Session = Depends(get_db)) -> StatusResponse:
    contract = db.get(Contract, contract_id)
    if contract is None:
        raise HTTPException(status_code=404, detail="Contract not found")
    db.delete(contract)
    db.commit()
    return StatusResponse(status="deleted")
