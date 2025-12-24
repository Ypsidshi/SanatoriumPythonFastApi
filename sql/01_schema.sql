-- Schema for MySQL 8+. Adjust data types slightly if switching to PostgreSQL.
CREATE TABLE IF NOT EXISTS pansionat (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NULL,
    vacation_type VARCHAR(100) NULL,
    medical_profile VARCHAR(100) NULL,
    room_count INT NULL,
    floor_count INT NULL,
    year_built SMALLINT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS service (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    pansionat_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_service_pansionat FOREIGN KEY (pansionat_id) REFERENCES pansionat(id),
    CONSTRAINT uq_service_name_per_pansionat UNIQUE (pansionat_id, name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS client (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(255) NOT NULL,
    passport VARCHAR(50) NOT NULL,
    phone VARCHAR(50) NULL,
    email VARCHAR(120) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_client_passport UNIQUE (passport)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS contract (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    pansionat_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    room_type VARCHAR(120) NULL,
    base_cost DECIMAL(12,2) NOT NULL,
    final_cost DECIMAL(12,2) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'active', -- draft, active, completed, cancelled, deleted
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_contract_pansionat FOREIGN KEY (pansionat_id) REFERENCES pansionat(id),
    CONSTRAINT fk_contract_client FOREIGN KEY (client_id) REFERENCES client(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS contract_service (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    contract_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price_at_booking DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_contract_service_contract FOREIGN KEY (contract_id) REFERENCES contract(id),
    CONSTRAINT fk_contract_service_service FOREIGN KEY (service_id) REFERENCES service(id),
    CONSTRAINT uq_contract_service UNIQUE (contract_id, service_id)
) ENGINE=InnoDB;

CREATE INDEX idx_contract_status_dates ON contract(status, check_in, check_out);
CREATE INDEX idx_service_active ON service(is_active);
