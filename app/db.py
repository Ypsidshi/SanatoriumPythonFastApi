import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load environment variables from a local .env if present.
load_dotenv()

# Default now targets SQL Server; override with DATABASE_URL env var.
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mssql+pyodbc://user:password@localhost:1433/sanatorium"
    "?driver=ODBC+Driver+17+for+SQL+Server&TrustServerCertificate=yes",
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    future=True,
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


def get_db():
    """FastAPI dependency that yields a DB session and guarantees cleanup."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
