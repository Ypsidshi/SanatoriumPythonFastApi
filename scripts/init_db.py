"""Create the Sanatorium database and apply the T-SQL scripts to it.

Runs both locally (`python -m scripts.init_db`) and inside docker compose,
where it executes once before the API container starts.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import time
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError

SQL_DIR = Path(__file__).resolve().parent.parent / "sql"

# Order matters: schema, then CHECK constraints, then demo data, and only then
# the programmable objects - otherwise the price triggers created by
# 02_operations rewrite the prices the seed script just inserted.
DEFAULT_SCRIPTS = (
    "01_schema_mssql.sql",
    "06_constraints_mssql.sql",
    "03_seed_mssql.sql",
    "02_operations_mssql.sql",
)

# T-SQL batch separator: a line containing nothing but GO.
GO_SEPARATOR = re.compile(r"^\s*GO\s*;?\s*$", re.IGNORECASE | re.MULTILINE)

# SQL Server does not allow a bound parameter in DDL, so the database name is
# validated instead of quoted-and-hoped-for.
SAFE_DB_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def split_batches(script: str) -> list[str]:
    return [batch.strip() for batch in GO_SEPARATOR.split(script) if batch.strip()]


def wait_for_server(master_url, timeout: int) -> None:
    """Block until SQL Server accepts connections, or give up after `timeout`."""
    engine = create_engine(master_url, isolation_level="AUTOCOMMIT")
    deadline = time.monotonic() + timeout
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print(f"SQL Server is up at {master_url.host}:{master_url.port or 1433}")
            return
        except DBAPIError as exc:
            last_error = exc
            time.sleep(2)
    raise SystemExit(f"SQL Server did not become available in {timeout}s: {last_error}")


def create_database(master_url, database: str) -> None:
    if not SAFE_DB_NAME.match(database):
        raise SystemExit(f"Refusing to create a database with the name {database!r}")
    engine = create_engine(master_url, isolation_level="AUTOCOMMIT")
    with engine.connect() as conn:
        # Cyrillic collation: the schema stores Russian text in VARCHAR columns,
        # which would turn into '?' under the default Latin1 collation.
        conn.execute(
            text(
                f"IF DB_ID(N'{database}') IS NULL "
                f"CREATE DATABASE [{database}] COLLATE Cyrillic_General_CI_AS;"
            )
        )
    print(f"Database [{database}] is ready")


def apply_script(engine, path: Path) -> None:
    # utf-8-sig also covers the scripts saved from SSMS with a BOM.
    batches = split_batches(path.read_text(encoding="utf-8-sig"))
    with engine.connect() as conn:
        for number, batch in enumerate(batches, start=1):
            try:
                conn.execute(text(batch))
            except DBAPIError as exc:
                raise SystemExit(
                    f"{path.name}: batch {number}/{len(batches)} failed\n"
                    f"{batch[:400]}\n--- {exc.orig}"
                ) from exc
    print(f"Applied {path.name} ({len(batches)} batches)")


def main() -> int:
    load_dotenv()

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--scripts",
        nargs="*",
        default=list(DEFAULT_SCRIPTS),
        help="Script file names inside sql/, applied in the given order.",
    )
    parser.add_argument(
        "--wait",
        type=int,
        default=120,
        help="Seconds to wait for SQL Server to accept connections.",
    )
    args = parser.parse_args()

    dsn = os.getenv("DATABASE_URL")
    if not dsn:
        print("DATABASE_URL is not set - copy .env.example to .env first.", file=sys.stderr)
        return 1

    url = make_url(dsn)
    if not url.database:
        print(f"DATABASE_URL has no database name: {dsn}", file=sys.stderr)
        return 1

    master_url = url.set(database="master")
    wait_for_server(master_url, args.wait)
    create_database(master_url, url.database)

    engine = create_engine(url, isolation_level="AUTOCOMMIT")
    for name in args.scripts:
        path = SQL_DIR / name
        if not path.is_file():
            print(f"Script not found: {path}", file=sys.stderr)
            return 1
        apply_script(engine, path)

    print("Database initialised.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
