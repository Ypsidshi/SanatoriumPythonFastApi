"""Pydantic DTOs for requests and responses.

Response models exist so the OpenAPI schema documents the shape of every
payload instead of showing a bare `{}` for each endpoint.
"""

from __future__ import annotations

from datetime import date
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class Items(BaseModel, Generic[T]):
    """Envelope used by every collection endpoint."""

    items: list[T]


# --------------------------------------------------------------------------- #
# Requests
# --------------------------------------------------------------------------- #


class PansionatCreate(BaseModel):
    name: str = Field(..., max_length=255)
    photo: str | None = Field(None, max_length=255)
    building_year: date
    health_profile_id: int
    administrator_ids: list[int] = Field(default_factory=list)
    service_ids: list[int] = Field(default_factory=list)


class PansionatUpdate(BaseModel):
    name: str | None = Field(None, max_length=255)
    photo: str | None = Field(None, max_length=255)
    building_year: date | None = None
    health_profile_id: int | None = None
    administrator_ids: list[int] | None = None
    service_ids: list[int] | None = None


class ContractCreate(BaseModel):
    start_date: date
    final_date: date
    summa: int
    manager_id: int
    room_id: int
    resident_id: int
    status_of_contract_id: int


class ContractUpdate(BaseModel):
    start_date: date | None = None
    final_date: date | None = None
    summa: int | None = None
    manager_id: int | None = None
    room_id: int | None = None
    resident_id: int | None = None
    status_of_contract_id: int | None = None


# --------------------------------------------------------------------------- #
# Responses
# --------------------------------------------------------------------------- #


class PansionatCreated(BaseModel):
    id_pansionat: int


class ContractCreated(BaseModel):
    id_contract: int


class StatusResponse(BaseModel):
    status: str


class AvailabilityItem(BaseModel):
    id_pansionat: int
    name: str
    service_count: int


class PansionatYearStat(BaseModel):
    year: int
    pansionats: int


class AdminSummary(BaseModel):
    administrator_id: int
    pansionats: int
    rooms: int
    residents: int
    services: int


class AdminRevenueItem(BaseModel):
    pansionat_id: int
    name: str
    contracts: int
    total_revenue: int | None = None
    # SQL Server returns an integer average for an INT column; SQLite returns a
    # float. Widening to float keeps both backends valid.
    avg_check: float | None = None


class TopServiceItem(BaseModel):
    service_id: int
    name: str
    pansionat_count: int


class OccupancyItem(BaseModel):
    pansionat_id: int
    name: str
    contracts: int


class RevenueItem(BaseModel):
    pansionat_id: int
    name: str
    total_revenue: int | None = None
    avg_check: float | None = None


class ContractStatusItem(BaseModel):
    status: bool
    contracts: int
    total_revenue: int | None = None


class ManagerPeriodTotals(BaseModel):
    contracts: int
    total_revenue: int | None = None
    avg_check: float | None = None


class RoomTypeItem(BaseModel):
    room_type: str
    contracts: int
    total_revenue: int | None = None


class TableRows(BaseModel):
    """Raw rows of a whitelisted table; the columns depend on the table."""

    items: list[dict[str, Any]]
