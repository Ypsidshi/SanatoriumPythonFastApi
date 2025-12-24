-- T-SQL schema for SQL Server based on provided attributes/relations
-- Run in SSMS on target database.

IF OBJECT_ID('using_service', 'U') IS NOT NULL DROP TABLE using_service;
IF OBJECT_ID('provision_of_services', 'U') IS NOT NULL DROP TABLE provision_of_services;
IF OBJECT_ID('contract', 'U') IS NOT NULL DROP TABLE contract;
IF OBJECT_ID('resident', 'U') IS NOT NULL DROP TABLE resident;
IF OBJECT_ID('room', 'U') IS NOT NULL DROP TABLE room;
IF OBJECT_ID('service', 'U') IS NOT NULL DROP TABLE service;
IF OBJECT_ID('pansionat', 'U') IS NOT NULL DROP TABLE pansionat;
IF OBJECT_ID('administrator', 'U') IS NOT NULL DROP TABLE administrator;
IF OBJECT_ID('manager', 'U') IS NOT NULL DROP TABLE manager;
IF OBJECT_ID('health_profile', 'U') IS NOT NULL DROP TABLE health_profile;
IF OBJECT_ID('status_room', 'U') IS NOT NULL DROP TABLE status_room;
IF OBJECT_ID('status_of_contract', 'U') IS NOT NULL DROP TABLE status_of_contract;
IF OBJECT_ID('room_type', 'U') IS NOT NULL DROP TABLE room_type;
GO

CREATE TABLE manager (
    id_manager INT IDENTITY(1,1) PRIMARY KEY,
    surname VARCHAR(30) NOT NULL,
    name VARCHAR(30) NOT NULL,
    otchestvo VARCHAR(30) NOT NULL,
    adress VARCHAR(255) NOT NULL,
    mail VARCHAR(255) NOT NULL UNIQUE,
    telephone BIGINT NOT NULL
);
GO

CREATE TABLE administrator (
    id_administrator INT IDENTITY(1,1) PRIMARY KEY,
    surname VARCHAR(30) NOT NULL,
    name VARCHAR(30) NOT NULL,
    otchestvo VARCHAR(30) NOT NULL,
    adress VARCHAR(255) NOT NULL,
    mail VARCHAR(255) NOT NULL UNIQUE,
    telephone BIGINT NOT NULL
);
GO

CREATE TABLE health_profile (
    id_health_profile INT IDENTITY(1,1) PRIMARY KEY,
    profile VARCHAR(255) NOT NULL
);
GO

CREATE TABLE status_room (
    id_status_room INT IDENTITY(1,1) PRIMARY KEY,
    status BIT NOT NULL
);
GO

CREATE TABLE status_of_contract (
    id_status_of_contract INT IDENTITY(1,1) PRIMARY KEY,
    status BIT NOT NULL
);
GO

CREATE TABLE room_type (
    id_type INT IDENTITY(1,1) PRIMARY KEY,
    type VARCHAR(255) NOT NULL
);
GO

CREATE TABLE pansionat (
    id_pansionat INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    photo VARCHAR(255) NULL,
    buiding_year INT NOT NULL,
    administrator INT NOT NULL,
    health_profile INT NOT NULL,
    CONSTRAINT fk_pansionat_admin
        FOREIGN KEY (administrator) REFERENCES administrator(id_administrator)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT fk_pansionat_health
        FOREIGN KEY (health_profile) REFERENCES health_profile(id_health_profile)
        ON DELETE NO ACTION ON UPDATE CASCADE
);
GO

CREATE TABLE service (
    id_service INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    price INT NOT NULL,
    time VARCHAR(255) NOT NULL
);
GO

CREATE TABLE room (
    id_room INT IDENTITY(1,1) PRIMARY KEY,
    price INT NOT NULL,
    pansionat INT NOT NULL,
    type INT NOT NULL,
    status_room INT NOT NULL,
    CONSTRAINT fk_room_pansionat
        FOREIGN KEY (pansionat) REFERENCES pansionat(id_pansionat)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT fk_room_type
        FOREIGN KEY (type) REFERENCES room_type(id_type)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT fk_room_status
        FOREIGN KEY (status_room) REFERENCES status_room(id_status_room)
        ON DELETE NO ACTION ON UPDATE CASCADE
);
GO

CREATE TABLE resident (
    id_resident INT IDENTITY(1,1) PRIMARY KEY,
    surname VARCHAR(30) NOT NULL,
    name VARCHAR(30) NOT NULL,
    otchestvo VARCHAR(30) NOT NULL,
    mail VARCHAR(255) NOT NULL UNIQUE,
    telephone BIGINT NOT NULL,
    passport BIGINT NOT NULL UNIQUE,
    manager INT NOT NULL,
    pansionat INT NULL,
    CONSTRAINT fk_resident_manager
        FOREIGN KEY (manager) REFERENCES manager(id_manager)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT fk_resident_pansionat
        FOREIGN KEY (pansionat) REFERENCES pansionat(id_pansionat)
        ON DELETE SET NULL ON UPDATE CASCADE
);
GO

CREATE TABLE contract (
    id_dogovor INT IDENTITY(1,1) PRIMARY KEY,
    start_date DATE NOT NULL,
    final_date DATE NOT NULL,
    summa INT NOT NULL,
    manager INT NOT NULL,
    room INT NOT NULL,
    resident INT NOT NULL,
    status_of_contract INT NOT NULL,
    CONSTRAINT fk_contract_manager
        FOREIGN KEY (manager) REFERENCES manager(id_manager)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT fk_contract_room
        FOREIGN KEY (room) REFERENCES room(id_room)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT fk_contract_resident
        FOREIGN KEY (resident) REFERENCES resident(id_resident)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_contract_status
        FOREIGN KEY (status_of_contract) REFERENCES status_of_contract(id_status_of_contract)
        ON DELETE NO ACTION ON UPDATE CASCADE
);
GO

CREATE INDEX idx_contract_start_date ON contract(start_date);
CREATE INDEX idx_contract_final_date ON contract(final_date);
GO

CREATE TABLE provision_of_services (
    service INT NOT NULL,
    pansionat INT NOT NULL,
    CONSTRAINT pk_provision_of_services PRIMARY KEY CLUSTERED (service, pansionat),
    CONSTRAINT fk_pos_service
        FOREIGN KEY (service) REFERENCES service(id_service)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pos_pansionat
        FOREIGN KEY (pansionat) REFERENCES pansionat(id_pansionat)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

CREATE TABLE using_service (
    service INT NOT NULL,
    resident INT NOT NULL,
    CONSTRAINT pk_using_service PRIMARY KEY CLUSTERED (service, resident),
    CONSTRAINT fk_using_service_service
        FOREIGN KEY (service) REFERENCES service(id_service)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_using_service_resident
        FOREIGN KEY (resident) REFERENCES resident(id_resident)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO
