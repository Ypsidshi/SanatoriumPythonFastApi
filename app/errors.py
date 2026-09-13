"""Translate database exceptions into clean HTTP responses.

Endpoints used to wrap every query in `except Exception` and return the driver
message verbatim, which leaked ODBC internals to the client and turned every
failure into a 400. Handlers registered here classify the error once, log the
detail server-side and return a short message instead.
"""

from __future__ import annotations

import logging
import re

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

logger = logging.getLogger(__name__)

# "Violation of UNIQUE KEY constraint 'uq_contract_resident'"  (SQL Server)
_QUOTED_CONSTRAINT = re.compile(r"constraint ['\"]([^'\"]+)['\"]", re.IGNORECASE)
# "UNIQUE constraint failed: contract.resident"                (SQLite)
_SQLITE_CONSTRAINT = re.compile(r"constraint failed: ([\w.]+)", re.IGNORECASE)


def constraint_name(exc: IntegrityError) -> str | None:
    """Best-effort extraction of the violated constraint from a driver message."""
    message = str(getattr(exc, "orig", exc))
    for pattern in (_QUOTED_CONSTRAINT, _SQLITE_CONSTRAINT):
        match = pattern.search(message)
        if match:
            return match.group(1)
    return None


async def integrity_error_handler(request: Request, exc: IntegrityError) -> JSONResponse:
    name = constraint_name(exc)
    logger.warning("Integrity error on %s %s: %s", request.method, request.url.path, exc.orig)
    detail = (
        f"The request violates the database constraint {name!r}."
        if name
        else "The request violates a database constraint."
    )
    return JSONResponse(status_code=409, content={"detail": detail})


async def database_error_handler(request: Request, exc: SQLAlchemyError) -> JSONResponse:
    logger.exception("Database error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=503,
        content={"detail": "The database is unavailable or rejected the query."},
    )


def register_error_handlers(app: FastAPI) -> None:
    # Starlette walks the exception's MRO, so the IntegrityError handler wins
    # over the SQLAlchemyError one for integrity violations.
    app.add_exception_handler(IntegrityError, integrity_error_handler)
    app.add_exception_handler(SQLAlchemyError, database_error_handler)
