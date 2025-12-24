-- Mass seed for SQL Server based on current schema.
-- Adjust counts as needed.
SET NOCOUNT ON;

DECLARE @administrator_count INT = 200;
DECLARE @manager_count INT = 2000;
DECLARE @health_profile_count INT = 20;
DECLARE @status_room_count INT = 2;
DECLARE @status_of_contract_count INT = 2;
DECLARE @type_count INT = 10;
DECLARE @pansionat_count INT = 2000;
DECLARE @room_count INT = 80000;
DECLARE @resident_count INT = 200000;
DECLARE @contract_count INT = 300000;
DECLARE @service_count INT = 5000;
DECLARE @vladenie_count INT = 4000;
DECLARE @provision_count INT = 200000;
DECLARE @using_count INT = 500000;

DELETE FROM using_service;
DELETE FROM provision_of_services;
DELETE FROM vladenie;
DELETE FROM contract;
DELETE FROM resident;
DELETE FROM room;
DELETE FROM service;
DELETE FROM pansionat;
DELETE FROM manager;
DELETE FROM administrator;
DELETE FROM status_room;
DELETE FROM status_of_contract;
DELETE FROM room_type;
DELETE FROM health_profile;

DBCC CHECKIDENT('administrator', RESEED, 0);
DBCC CHECKIDENT('manager', RESEED, 0);
DBCC CHECKIDENT('health_profile', RESEED, 0);
DBCC CHECKIDENT('status_room', RESEED, 0);
DBCC CHECKIDENT('status_of_contract', RESEED, 0);
DBCC CHECKIDENT('room_type', RESEED, 0);
DBCC CHECKIDENT('pansionat', RESEED, 0);
DBCC CHECKIDENT('room', RESEED, 0);
DBCC CHECKIDENT('resident', RESEED, 0);
DBCC CHECKIDENT('contract', RESEED, 0);
DBCC CHECKIDENT('service', RESEED, 0);

;WITH n AS (
    SELECT TOP (@health_profile_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO health_profile (profile)
SELECT CONCAT('Profile ', n) FROM n;

INSERT INTO status_room (status) VALUES (1), (0);
INSERT INTO status_of_contract (status) VALUES (1), (0);

;WITH n AS (
    SELECT TOP (@type_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO room_type (type)
SELECT CONCAT('Type ', n) FROM n;

;WITH n AS (
    SELECT TOP (@administrator_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO administrator (surname, name, otchestvo, adress, mail, telephone)
SELECT
    CONCAT('AdminSurname', n),
    CONCAT('AdminName', n),
    CONCAT('AdminOtch', n),
    CONCAT('Street ', n),
    CONCAT('admin', n, '@example.com'),
    7000000000 + n
FROM n;

;WITH n AS (
    SELECT TOP (@manager_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO manager (surname, name, otchestvo, adress, mail, telephone)
SELECT
    CONCAT('ManagerSurname', n),
    CONCAT('ManagerName', n),
    CONCAT('ManagerOtch', n),
    CONCAT('Street ', n),
    CONCAT('manager', n, '@example.com'),
    7100000000 + n
FROM n;

IF NOT EXISTS (SELECT 1 FROM health_profile)
BEGIN
    RAISERROR('health_profile is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;
IF NOT EXISTS (SELECT 1 FROM administrator)
BEGIN
    RAISERROR('administrator is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#health_profiles') IS NOT NULL DROP TABLE #health_profiles;
IF OBJECT_ID('tempdb..#administrators') IS NOT NULL DROP TABLE #administrators;

SELECT ROW_NUMBER() OVER (ORDER BY id_health_profile) AS rn, id_health_profile
INTO #health_profiles
FROM health_profile;

SELECT ROW_NUMBER() OVER (ORDER BY id_administrator) AS rn, id_administrator
INTO #administrators
FROM administrator;

DECLARE @admin_rows INT = (SELECT COUNT(*) FROM #administrators);
DECLARE @health_rows INT = (SELECT COUNT(*) FROM #health_profiles);
DECLARE @type_rows INT;
DECLARE @pansionat_rows INT;

;WITH n AS (
    SELECT TOP (@pansionat_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO pansionat (name, photo, buiding_year, administrator, health_profile)
SELECT
    CONCAT('Pansionat ', n),
    NULL,
    1980 + (n % 40),
    a.id_administrator,
    h.id_health_profile
FROM n, #administrators a, #health_profiles h
WHERE a.rn = ((n - 1) % @admin_rows) + 1
  AND h.rn = ((n - 1) % @health_rows) + 1;

IF OBJECT_ID('tempdb..#room_types') IS NOT NULL DROP TABLE #room_types;
IF OBJECT_ID('tempdb..#pansionats') IS NOT NULL DROP TABLE #pansionats;

SELECT ROW_NUMBER() OVER (ORDER BY id_type) AS rn, id_type
INTO #room_types
FROM room_type;

SELECT ROW_NUMBER() OVER (ORDER BY id_pansionat) AS rn, id_pansionat
INTO #pansionats
FROM pansionat;

SET @type_rows = (SELECT COUNT(*) FROM #room_types);
SET @pansionat_rows = (SELECT COUNT(*) FROM #pansionats);

;WITH n AS (
    SELECT TOP (@service_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO service (name, price, time)
SELECT
    CONCAT('Service ', n),
    500 + (n % 5000),
    CONCAT(30 + (n % 91), ' min')
FROM n;

IF NOT EXISTS (SELECT 1 FROM status_room)
BEGIN
    RAISERROR('status_room is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;
IF NOT EXISTS (SELECT 1 FROM manager)
BEGIN
    RAISERROR('manager is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#status_rooms') IS NOT NULL DROP TABLE #status_rooms;
IF OBJECT_ID('tempdb..#managers') IS NOT NULL DROP TABLE #managers;
IF OBJECT_ID('tempdb..#rooms') IS NOT NULL DROP TABLE #rooms;
IF OBJECT_ID('tempdb..#residents') IS NOT NULL DROP TABLE #residents;
IF OBJECT_ID('tempdb..#status_contracts') IS NOT NULL DROP TABLE #status_contracts;

SELECT ROW_NUMBER() OVER (ORDER BY id_status_room) AS rn, id_status_room
INTO #status_rooms
FROM status_room;

SELECT ROW_NUMBER() OVER (ORDER BY id_manager) AS rn, id_manager
INTO #managers
FROM manager;

SELECT ROW_NUMBER() OVER (ORDER BY id_status_of_contract) AS rn, id_status_of_contract
INTO #status_contracts
FROM status_of_contract;

DECLARE @status_rows INT = (SELECT COUNT(*) FROM #status_rooms);
DECLARE @manager_rows INT = (SELECT COUNT(*) FROM #managers);
DECLARE @status_contract_rows INT = (SELECT COUNT(*) FROM #status_contracts);

;WITH n AS (
    SELECT TOP (@room_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO room (price, pansionat, type, status_room)
SELECT
    1500 + (n % 6000),
    p.id_pansionat,
    t.id_type,
    s.id_status_room
FROM n
JOIN #pansionats p ON p.rn = ((n - 1) % @pansionat_rows) + 1
JOIN #room_types t ON t.rn = ((n - 1) % @type_rows) + 1
JOIN #status_rooms s ON s.rn = ((n - 1) % @status_rows) + 1;

;WITH n AS (
    SELECT TOP (@resident_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO resident (surname, name, otchestvo, mail, telephone, passport, manager, pansionat)
SELECT
    CONCAT('ResidentSurname', n),
    CONCAT('ResidentName', n),
    CONCAT('ResidentOtch', n),
    CONCAT('resident', n, '@example.com'),
    7200000000 + n,
    1000000000 + n,
    m.id_manager,
    p.id_pansionat
FROM n
JOIN #managers m ON m.rn = ((n - 1) % @manager_rows) + 1
JOIN #pansionats p ON p.rn = ((n - 1) % @pansionat_rows) + 1;

SELECT ROW_NUMBER() OVER (ORDER BY id_room) AS rn, id_room
INTO #rooms
FROM room;

SELECT ROW_NUMBER() OVER (ORDER BY id_resident) AS rn, id_resident
INTO #residents
FROM resident;

DECLARE @room_rows INT = (SELECT COUNT(*) FROM #rooms);
DECLARE @resident_rows INT = (SELECT COUNT(*) FROM #residents);

;WITH n AS (
    SELECT TOP (@contract_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO contract (
    start_date,
    final_date,
    summa,
    manager,
    room,
    resident,
    status_of_contract
)
SELECT
    DATEADD(DAY, n % 365, '2023-01-01'),
    DATEADD(DAY, 3 + (n % 28), DATEADD(DAY, n % 365, '2023-01-01')),
    10000 + (n % 40000),
    m.id_manager,
    r.id_room,
    res.id_resident,
    s.id_status_of_contract
FROM n
JOIN #rooms r ON r.rn = ((n - 1) % @room_rows) + 1
JOIN #residents res ON res.rn = ((n - 1) % @resident_rows) + 1
JOIN #managers m ON m.rn = ((n - 1) % @manager_rows) + 1
JOIN #status_contracts s ON s.rn = ((n - 1) % @status_contract_rows) + 1;

;WITH pairs AS (
    SELECT TOP (@vladenie_count)
        a.id_administrator AS administrator,
        p.id_pansionat AS pansionat
    FROM administrator a
    CROSS JOIN pansionat p
    ORDER BY a.id_administrator, p.id_pansionat
)
INSERT INTO vladenie (administrator, pansionat)
SELECT administrator, pansionat
FROM pairs;

;WITH pairs AS (
    SELECT TOP (@provision_count)
        s.id_service AS service,
        p.id_pansionat AS pansionat
    FROM service s
    CROSS JOIN pansionat p
    ORDER BY s.id_service, p.id_pansionat
)
INSERT INTO provision_of_services (service, pansionat)
SELECT service, pansionat
FROM pairs;

;WITH pairs AS (
    SELECT TOP (@using_count)
        s.id_service AS service,
        r.id_resident AS resident
    FROM service s
    CROSS JOIN resident r
    ORDER BY s.id_service, r.id_resident
)
INSERT INTO using_service (service, resident)
SELECT service, resident
FROM pairs;
