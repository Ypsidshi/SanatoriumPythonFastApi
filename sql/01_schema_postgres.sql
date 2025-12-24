-- Schema for PostgreSQL
-- Run: psql -U user -d sanatorium -f sql/01_schema_postgres.sql

DROP TABLE IF EXISTS contract_service CASCADE;
DROP TABLE IF EXISTS contract CASCADE;
DROP TABLE IF EXISTS service CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS pansionat CASCADE;

CREATE TABLE pansionat (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NULL,
    vacation_type VARCHAR(100) NULL,
    medical_profile VARCHAR(100) NULL,
    room_count INT NULL,
    floor_count INT NULL,
    year_built SMALLINT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE service (
    id BIGSERIAL PRIMARY KEY,
    pansionat_id BIGINT NOT NULL REFERENCES pansionat(id),
    name VARCHAR(150) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_service_name_per_pansionat UNIQUE (pansionat_id, name)
);

CREATE TABLE client (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    passport VARCHAR(50) NOT NULL,
    phone VARCHAR(50) NULL,
    email VARCHAR(120) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_client_passport UNIQUE (passport)
);

CREATE TABLE contract (
    id BIGSERIAL PRIMARY KEY,
    pansionat_id BIGINT NOT NULL REFERENCES pansionat(id),
    client_id BIGINT NOT NULL REFERENCES client(id),
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    room_type VARCHAR(120) NULL,
    base_cost NUMERIC(12,2) NOT NULL,
    final_cost NUMERIC(12,2) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'active', -- draft, active, completed, cancelled, deleted
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE contract_service (
    id BIGSERIAL PRIMARY KEY,
    contract_id BIGINT NOT NULL REFERENCES contract(id),
    service_id BIGINT NOT NULL REFERENCES service(id),
    quantity INT NOT NULL DEFAULT 1,
    price_at_booking NUMERIC(10,2) NOT NULL,
    CONSTRAINT uq_contract_service UNIQUE (contract_id, service_id)
);

CREATE INDEX idx_contract_status_dates ON contract(status, check_in, check_out);
CREATE INDEX idx_service_active ON service(is_active);
