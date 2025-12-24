from datetime import date
from typing import List, Optional

from pydantic import BaseModel, Field


class PansionatCreate(BaseModel):
    name: str = Field(..., max_length=255)
    photo: Optional[str] = Field(None, max_length=255)
    building_year: date
    health_profile_id: int
    administrator_ids: List[int] = Field(default_factory=list)
    service_ids: List[int] = Field(default_factory=list)


class PansionatUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    photo: Optional[str] = Field(None, max_length=255)
    building_year: Optional[date] = None
    health_profile_id: Optional[int] = None
    administrator_ids: Optional[List[int]] = None
    service_ids: Optional[List[int]] = None


class ContractCreate(BaseModel):
    start_date: date
    final_date: date
    summa: int
    manager_id: int
    room_id: int
    resident_id: int
    status_of_contract_id: int


class ContractUpdate(BaseModel):
    start_date: Optional[date] = None
    final_date: Optional[date] = None
    summa: Optional[int] = None
    manager_id: Optional[int] = None
    room_id: Optional[int] = None
    resident_id: Optional[int] = None
    status_of_contract_id: Optional[int] = None
