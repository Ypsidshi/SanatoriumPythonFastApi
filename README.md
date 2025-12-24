# Sanatorium API (FastAPI + OpenAPI)

Python FastAPI backend that exposes CRUD and reporting endpoints for sanatoriums, services, and contracts. Swagger / OpenAPI docs are served by FastAPI out of the box.

## Database choice
- Сейчас проект ориентирован на SQL Server (SSMS): используйте `sql/01_schema_mssql.sql`, `sql/02_operations_mssql.sql`.
- PostgreSQL и MySQL варианты оставлены для справки, но не синхронизированы с текущими атрибутами.

## Running locally
1) Install dependencies (Python 3.11+):
```
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```
2) Set a `DATABASE_URL` env var (MSSQL):
- `set DATABASE_URL=mssql+pyodbc://user:password@localhost:1433/sanatorium?driver=ODBC+Driver+17+for+SQL+Server&TrustServerCertificate=yes`
3) Create database objects:
- SQL Server: выполнить в SSMS `sql/01_schema_mssql.sql`, затем `sql/02_operations_mssql.sql`.
4) Run the API:
```
uvicorn app.main:app --reload
```
Swagger UI will be available at `http://localhost:8000/docs`.

## Repository layout
- `app/main.py` – FastAPI app, routes, and DB wiring.
- `app/models.py` – SQLAlchemy models that mirror the SQL schema.
- `app/schemas.py` – Pydantic request/response DTOs.
- `app/db.py` – DB session factory.
- `sql/01_schema.sql` – tables, indexes, and base constraints.
- `sql/02_operations.sql` – stored procedures/triggers/events for business rules from `ОписаниеСкриптовДляMySQL.md`.
