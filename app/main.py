"""FastAPI application for the Sanatorium API.

Routes live in `app/routers`, grouped the way Swagger groups them: the
administrator workstation, the manager workstation, and a liveness probe.
"""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI

from .db import engine
from .errors import register_error_handlers
from .models import Base
from .routers import (
    admin_analytics,
    admin_pansionats,
    manager_analytics,
    manager_contracts,
    system,
)

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
            "DB triggers (informational): price bump for all services when adding a new service "
            "to a pansionat, and 20% discount for services when health profile is "
            "'сердечно-сосудистый'."
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


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Convenience for a database that has not had sql/01_schema_mssql.sql applied
    # yet; a no-op once the tables exist. It does not create the CHECK
    # constraints, triggers or procedures - run scripts/init_db.py for those.
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Sanatorium API",
    description=(
        "REST API over a SQL Server database for a sanatorium network: pansionat and "
        "contract management plus occupancy and revenue analytics."
    ),
    version="0.4.0",
    openapi_tags=openapi_tags,
    lifespan=lifespan,
)

register_error_handlers(app)

app.include_router(admin_pansionats.router)
app.include_router(admin_analytics.router)
app.include_router(manager_contracts.router)
app.include_router(manager_analytics.router)
app.include_router(system.router)
