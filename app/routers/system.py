"""Liveness endpoint."""

from fastapi import APIRouter

from ..schemas import StatusResponse

router = APIRouter(tags=["System"])


@router.get("/health", response_model=StatusResponse, summary="Health")
def health() -> StatusResponse:
    return StatusResponse(status="ok")
