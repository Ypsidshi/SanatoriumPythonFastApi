-- Mass seed for SQL Server (SSMS). Adjust counts as needed.
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
DECLARE @provision_count INT = 200000;
DECLARE @using_count INT = 500000;

-- Clear data (child tables first)
DELETE FROM [using_service];
DELETE FROM [provision_of_services];
DELETE FROM [Contract];
DELETE FROM [Room];
DELETE FROM [Service];
DELETE FROM [Pansionat];
DELETE FROM [Resident];
DELETE FROM [Manager];
DELETE FROM [Administrator];
DELETE FROM [Status_room];
DELETE FROM [Status_of_contract];
DELETE FROM [room_type];
DELETE FROM [Health_profile];

-- Reset identities
DBCC CHECKIDENT('[Administrator]', RESEED, 0);
DBCC CHECKIDENT('[Manager]', RESEED, 0);
DBCC CHECKIDENT('[Health_profile]', RESEED, 0);
DBCC CHECKIDENT('[Status_room]', RESEED, 0);
DBCC CHECKIDENT('[Status_of_contract]', RESEED, 0);
DBCC CHECKIDENT('[room_type]', RESEED, 0);
DBCC CHECKIDENT('[Pansionat]', RESEED, 0);
DBCC CHECKIDENT('[Room]', RESEED, 0);
DBCC CHECKIDENT('[Resident]', RESEED, 0);
DBCC CHECKIDENT('[Contract]', RESEED, 0);
DBCC CHECKIDENT('[Service]', RESEED, 0);

;WITH n AS (
    SELECT TOP (@health_profile_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Health_profile] ([Profile])
SELECT CONCAT('Profile ', n) FROM n;

INSERT INTO [Status_room] ([Status]) VALUES (1), (0);
INSERT INTO [Status_of_contract] ([Status]) VALUES (1), (0);

;WITH n AS (
    SELECT TOP (@type_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [room_type] ([type])
SELECT CONCAT('Type ', n) FROM n;

;WITH n AS (
    SELECT TOP (@administrator_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Administrator] ([Surname], [Name], [Otchestvo], [Adress], [Mail], [Telephone])
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
INSERT INTO [Manager] ([Surname], [Name], [Otchestvo], [Adress], [Mail], [Telephone])
SELECT
    CONCAT('ManagerSurname', n),
    CONCAT('ManagerName', n),
    CONCAT('ManagerOtch', n),
    CONCAT('Street ', n),
    CONCAT('manager', n, '@example.com'),
    7100000000 + n
FROM n;

;WITH n AS (
    SELECT TOP (@pansionat_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Pansionat] ([Name], [Photo], [buiding_year], [administrator], [health_profile])
SELECT
    CONCAT('Pansionat ', n),
    NULL,
    1980 + (n % 40),
    ((n - 1) % @administrator_count) + 1,
    ((n - 1) % @health_profile_count) + 1
FROM n;

;WITH n AS (
    SELECT TOP (@service_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Service] ([Name], [Price], [Time])
SELECT
    CONCAT('Service ', n),
    500 + (n % 5000),
    CONCAT(30 + (n % 91), ' min')
FROM n;

;WITH n AS (
    SELECT TOP (@room_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Room] ([Price], [pansionat], [status_room], [type])
SELECT
    1500 + (n % 6000),
    ((n - 1) % @pansionat_count) + 1,
    ((n - 1) % @status_room_count) + 1,
    ((n - 1) % @type_count) + 1
FROM n;

;WITH n AS (
    SELECT TOP (@resident_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Resident] ([Surname], [Name], [Otchestvo], [Mail], [Telephone], [Passport], [manager], [pansionat])
SELECT
    CONCAT('ResidentSurname', n),
    CONCAT('ResidentName', n),
    CONCAT('ResidentOtch', n),
    CONCAT('resident', n, '@example.com'),
    7200000000 + n,
    1000000000 + n,
    ((n - 1) % @manager_count) + 1,
    CASE WHEN n % 10 = 0 THEN NULL ELSE ((n - 1) % @pansionat_count) + 1 END
FROM n;

;WITH n AS (
    SELECT TOP (@contract_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Contract] (
    [start_date],
    [final_date],
    [summa],
    [room],
    [manager],
    [status_of_contract],
    [resident]
)
SELECT
    DATEADD(DAY, n % 365, '2023-01-01'),
    DATEADD(DAY, 3 + (n % 28), DATEADD(DAY, n % 365, '2023-01-01')),
    10000 + (n % 40000),
    ((n - 1) % @room_count) + 1,
    ((n - 1) % @manager_count) + 1,
    ((n - 1) % @status_of_contract_count) + 1,
    ((n - 1) % @resident_count) + 1
FROM n;

;WITH pairs AS (
    SELECT TOP (@provision_count)
        s.id_service AS service_id,
        p.id_pansionat AS pansionat_id
    FROM [service] s
    CROSS JOIN [pansionat] p
    ORDER BY CHECKSUM(NEWID())
)
INSERT INTO [provision_of_services] ([service], [pansionat])
SELECT service_id, pansionat_id
FROM pairs;

;WITH pairs AS (
    SELECT TOP (@using_count)
        r.id_resident AS resident_id,
        s.id_service AS service_id
    FROM [resident] r
    CROSS JOIN [service] s
    ORDER BY CHECKSUM(NEWID())
)
INSERT INTO [using_service] ([resident], [service])
SELECT resident_id, service_id
FROM pairs;
