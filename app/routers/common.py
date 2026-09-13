"""Small helpers shared by the routers."""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from typing import Any, TypeVar

from fastapi import HTTPException
from sqlalchemy import Result
from sqlalchemy.orm import InstrumentedAttribute, Session

M = TypeVar("M")


def require(db: Session, model: type[M], pk: Any, label: str) -> M:
    """Load a row by primary key or fail with 400 and a readable message."""
    obj = db.get(model, pk)
    if obj is None:
        raise HTTPException(status_code=400, detail=f"{label} not found")
    return obj


def load_all(
    db: Session,
    model: type[M],
    id_column: InstrumentedAttribute,
    ids: Iterable[int],
    label: str,
) -> list[M]:
    """Load every row named by `ids`, or fail if any of them is missing."""
    wanted = set(ids)
    rows = db.query(model).filter(id_column.in_(wanted)).all()
    if len(rows) != len(wanted):
        raise HTTPException(status_code=400, detail=f"One or more {label} not found")
    return rows


def as_dicts(result: Result) -> list[dict[str, Any]]:
    """Materialise a result set as plain dicts so Pydantic can validate it."""
    return [dict(row) for row in result.mappings().all()]


def first_dict(result: Result) -> dict[str, Any] | None:
    row = result.mappings().first()
    return dict(row) if row is not None else None


def items(result: Result) -> dict[str, Sequence[dict[str, Any]]]:
    """Wrap a result set in the `{"items": [...]}` envelope every list endpoint uses."""
    return {"items": as_dicts(result)}
