-- T-SQL routines/triggers aligned to current schema

-- Drop existing programmable objects
IF OBJECT_ID('trg_pos_price_bump', 'TR') IS NOT NULL DROP TRIGGER trg_pos_price_bump;
IF OBJECT_ID('trg_pos_heart_discount', 'TR') IS NOT NULL DROP TRIGGER trg_pos_heart_discount;
IF OBJECT_ID('trg_contract_early_discount', 'TR') IS NOT NULL DROP TRIGGER trg_contract_early_discount;
IF OBJECT_ID('trg_contract_auto_close', 'TR') IS NOT NULL DROP TRIGGER trg_contract_auto_close;
IF OBJECT_ID('vw_services_availability', 'V') IS NOT NULL DROP VIEW vw_services_availability;
IF OBJECT_ID('vw_pansionat_stats', 'V') IS NOT NULL DROP VIEW vw_pansionat_stats;
IF OBJECT_ID('vw_contract_occupancy', 'V') IS NOT NULL DROP VIEW vw_contract_occupancy;
IF OBJECT_ID('vw_contract_revenue', 'V') IS NOT NULL DROP VIEW vw_contract_revenue;
IF OBJECT_ID('sp_create_pansionat', 'P') IS NOT NULL DROP PROCEDURE sp_create_pansionat;
IF OBJECT_ID('sp_update_pansionat', 'P') IS NOT NULL DROP PROCEDURE sp_update_pansionat;
IF OBJECT_ID('sp_delete_pansionat', 'P') IS NOT NULL DROP PROCEDURE sp_delete_pansionat;
IF OBJECT_ID('sp_create_contract', 'P') IS NOT NULL DROP PROCEDURE sp_create_contract;
IF OBJECT_ID('sp_update_contract', 'P') IS NOT NULL DROP PROCEDURE sp_update_contract;
IF OBJECT_ID('sp_delete_contract', 'P') IS NOT NULL DROP PROCEDURE sp_delete_contract;
IF OBJECT_ID('sp_close_finished_contracts', 'P') IS NOT NULL DROP PROCEDURE sp_close_finished_contracts;
IF OBJECT_ID('sp_admin_pansionat_summary', 'P') IS NOT NULL DROP PROCEDURE sp_admin_pansionat_summary;
IF OBJECT_ID('sp_admin_contracts_revenue', 'P') IS NOT NULL DROP PROCEDURE sp_admin_contracts_revenue;
IF OBJECT_ID('sp_admin_top_services', 'P') IS NOT NULL DROP PROCEDURE sp_admin_top_services;
IF OBJECT_ID('sp_admin_table_rows', 'P') IS NOT NULL DROP PROCEDURE sp_admin_table_rows;
IF OBJECT_ID('sp_manager_contracts_status', 'P') IS NOT NULL DROP PROCEDURE sp_manager_contracts_status;
IF OBJECT_ID('sp_manager_contracts_period', 'P') IS NOT NULL DROP PROCEDURE sp_manager_contracts_period;
IF OBJECT_ID('sp_manager_room_type_stats', 'P') IS NOT NULL DROP PROCEDURE sp_manager_room_type_stats;
GO

CREATE PROCEDURE sp_create_pansionat
    @p_name VARCHAR(255),
    @p_photo VARCHAR(255) = NULL,
    @p_buiding_year INT,
    @p_administrator INT,
    @p_health_profile INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;
        INSERT INTO pansionat(name, photo, buiding_year, administrator, health_profile)
        VALUES (@p_name, @p_photo, @p_buiding_year, @p_administrator, @p_health_profile);
        SELECT SCOPE_IDENTITY() AS id_pansionat;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_update_pansionat
    @p_id INT,
    @p_name VARCHAR(255) = NULL,
    @p_photo VARCHAR(255) = NULL,
    @p_buiding_year INT = NULL,
    @p_administrator INT = NULL,
    @p_health_profile INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE pansionat
    SET name = ISNULL(@p_name, name),
        photo = ISNULL(@p_photo, photo),
        buiding_year = ISNULL(@p_buiding_year, buiding_year),
        administrator = ISNULL(@p_administrator, administrator),
        health_profile = ISNULL(@p_health_profile, health_profile)
    WHERE id_pansionat = @p_id;
END
GO

CREATE PROCEDURE sp_delete_pansionat
    @p_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM pansionat WHERE id_pansionat = @p_id;
END
GO

-- Analytics views
CREATE VIEW vw_services_availability AS
SELECT
    p.id_pansionat,
    p.name,
    COUNT(pos.service) AS service_count
FROM pansionat p
LEFT JOIN provision_of_services pos ON pos.pansionat = p.id_pansionat
GROUP BY p.id_pansionat, p.name;
GO

CREATE VIEW vw_pansionat_stats AS
SELECT
    buiding_year,
    COUNT(*) AS pansionats
FROM pansionat
GROUP BY buiding_year;
GO

CREATE VIEW vw_contract_occupancy AS
SELECT
    p.id_pansionat,
    p.name,
    COUNT(c.id_contract) AS contracts
FROM pansionat p
JOIN room r ON r.pansionat = p.id_pansionat
JOIN contract c ON c.room = r.id_room
GROUP BY p.id_pansionat, p.name;
GO

CREATE VIEW vw_contract_revenue AS
SELECT
    p.id_pansionat,
    p.name,
    SUM(c.summa) AS total_revenue,
    AVG(CAST(c.summa AS DECIMAL(18,2))) AS avg_check
FROM pansionat p
JOIN room r ON r.pansionat = p.id_pansionat
JOIN contract c ON c.room = r.id_room
GROUP BY p.id_pansionat, p.name;
GO

-- Trigger: bump price of all services for a pansionat when a new service link appears
CREATE TRIGGER trg_pos_price_bump
ON provision_of_services
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE s
    SET s.price = s.price * 1.05
    FROM service s
    JOIN provision_of_services pos ON pos.service = s.id_service
    JOIN (SELECT DISTINCT pansionat FROM inserted) i ON i.pansionat = pos.pansionat;
END
GO

-- Trigger: if health profile is 'сердечно-сосудистый', discount services linked to that pansionat
CREATE TRIGGER trg_pos_heart_discount
ON provision_of_services
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE s
    SET s.price = s.price * 0.8
    FROM service s
    JOIN inserted i ON s.id_service = i.service
    JOIN pansionat p ON p.id_pansionat = i.pansionat
    JOIN health_profile hp ON hp.id_health_profile = p.health_profile
    WHERE LOWER(hp.profile) = N'сердечно-сосудистый';
END
GO

-- Trigger: early booking discount by start_date (30+ days -> 10% off)
CREATE TRIGGER trg_contract_early_discount
ON contract
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
    SET c.summa = CASE WHEN DATEDIFF(DAY, GETDATE(), c.start_date) >= 30 THEN c.summa * 0.9 ELSE c.summa END
    FROM contract c
    JOIN inserted i ON c.id_contract = i.id_contract;
END
GO

-- Trigger: auto-close finished contracts (status = 0) when inserted/updated
CREATE TRIGGER trg_contract_auto_close
ON contract
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    DECLARE @closed_status_id INT;
    SELECT TOP 1 @closed_status_id = id_status_of_contract FROM status_of_contract WHERE status = 0;
    IF @closed_status_id IS NULL
        RETURN;

    UPDATE c
    SET c.status_of_contract = @closed_status_id
    FROM contract c
    JOIN inserted i ON c.id_contract = i.id_contract
    WHERE c.final_date < CAST(GETDATE() AS DATE)
      AND c.status_of_contract <> @closed_status_id;
END
GO

-- Contract procedures
CREATE PROCEDURE sp_create_contract
    @p_start_date DATE,
    @p_final_date DATE,
    @p_summa INT,
    @p_manager INT,
    @p_room INT,
    @p_resident INT,
    @p_status_of_contract INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;
        INSERT INTO contract(start_date, final_date, summa, manager, room, resident, status_of_contract)
        VALUES (@p_start_date, @p_final_date, @p_summa, @p_manager, @p_room, @p_resident, @p_status_of_contract);
        SELECT SCOPE_IDENTITY() AS id_contract;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_update_contract
    @p_id INT,
    @p_start_date DATE = NULL,
    @p_final_date DATE = NULL,
    @p_summa INT = NULL,
    @p_manager INT = NULL,
    @p_room INT = NULL,
    @p_resident INT = NULL,
    @p_status_of_contract INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE contract
    SET start_date = ISNULL(@p_start_date, start_date),
        final_date = ISNULL(@p_final_date, final_date),
        summa = ISNULL(@p_summa, summa),
        manager = ISNULL(@p_manager, manager),
        room = ISNULL(@p_room, room),
        resident = ISNULL(@p_resident, resident),
        status_of_contract = ISNULL(@p_status_of_contract, status_of_contract)
    WHERE id_contract = @p_id;
END
GO

CREATE PROCEDURE sp_delete_contract
    @p_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM contract WHERE id_contract = @p_id;
END
GO

-- Auto-close finished contracts: sets status_of_contract to first row with status = 0
CREATE PROCEDURE sp_close_finished_contracts
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @closed_status_id INT;
    SELECT TOP 1 @closed_status_id = id_status_of_contract FROM status_of_contract WHERE status = 0;
    IF @closed_status_id IS NULL
        RETURN;
    UPDATE contract
    SET status_of_contract = @closed_status_id
    WHERE final_date < CAST(GETDATE() AS DATE);
END
GO

-- Admin summary: pansionats, rooms, residents, services
CREATE PROCEDURE sp_admin_pansionat_summary
    @administrator_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    IF COL_LENGTH('resident', 'pansionat') IS NOT NULL
    BEGIN
        SET @sql = N'
            SELECT
                a.id_administrator AS administrator_id,
                COUNT(DISTINCT p.id_pansionat) AS pansionats,
                COUNT(DISTINCT r.id_room) AS rooms,
                COUNT(DISTINCT res.id_resident) AS residents,
                COUNT(DISTINCT s.id_service) AS services
            FROM administrator a
            JOIN vladenie v ON v.administrator = a.id_administrator
            JOIN pansionat p ON p.id_pansionat = v.pansionat
            LEFT JOIN room r ON r.pansionat = p.id_pansionat
            LEFT JOIN resident res ON res.pansionat = p.id_pansionat
            LEFT JOIN provision_of_services pos ON pos.pansionat = p.id_pansionat
            LEFT JOIN service s ON s.id_service = pos.service
            WHERE a.id_administrator = @administrator_id
            GROUP BY a.id_administrator';
    END
    ELSE
    BEGIN
        SET @sql = N'
            SELECT
                a.id_administrator AS administrator_id,
                COUNT(DISTINCT p.id_pansionat) AS pansionats,
                COUNT(DISTINCT r.id_room) AS rooms,
                COUNT(DISTINCT res.id_resident) AS residents,
                COUNT(DISTINCT s.id_service) AS services
            FROM administrator a
            JOIN vladenie v ON v.administrator = a.id_administrator
            JOIN pansionat p ON p.id_pansionat = v.pansionat
            LEFT JOIN room r ON r.pansionat = p.id_pansionat
            LEFT JOIN contract c ON c.room = r.id_room
            LEFT JOIN resident res ON res.id_resident = c.resident
            LEFT JOIN provision_of_services pos ON pos.pansionat = p.id_pansionat
            LEFT JOIN service s ON s.id_service = pos.service
            WHERE a.id_administrator = @administrator_id
            GROUP BY a.id_administrator';
    END

    EXEC sp_executesql @sql, N'@administrator_id INT', @administrator_id = @administrator_id;
END
GO

-- Admin revenue by pansionat in period
CREATE PROCEDURE sp_admin_contracts_revenue
    @administrator_id INT,
    @date_from DATE,
    @date_to DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.id_pansionat AS pansionat_id,
        p.name,
        COUNT(c.id_contract) AS contracts,
        SUM(c.summa) AS total_revenue,
        AVG(CAST(c.summa AS DECIMAL(18,2))) AS avg_check
    FROM pansionat p
    JOIN vladenie v ON v.pansionat = p.id_pansionat
    JOIN room r ON r.pansionat = p.id_pansionat
    JOIN contract c ON c.room = r.id_room
    WHERE v.administrator = @administrator_id
      AND c.start_date >= @date_from
      AND c.final_date <= @date_to
    GROUP BY p.id_pansionat, p.name;
END
GO

-- Top services offered in admin pansionats
CREATE PROCEDURE sp_admin_top_services
    @administrator_id INT,
    @limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@limit)
        s.id_service AS service_id,
        s.name,
        COUNT(DISTINCT pos.pansionat) AS pansionat_count
    FROM service s
    JOIN provision_of_services pos ON pos.service = s.id_service
    JOIN pansionat p ON p.id_pansionat = pos.pansionat
    JOIN vladenie v ON v.pansionat = p.id_pansionat
    WHERE v.administrator = @administrator_id
    GROUP BY s.id_service, s.name
    ORDER BY COUNT(DISTINCT pos.pansionat) DESC;
END
GO

-- Safe table dump for admin
CREATE PROCEDURE sp_admin_table_rows
    @table_name VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    IF @table_name NOT IN (
        'manager', 'administrator', 'health_profile', 'status_room', 'status_of_contract',
        'room_type', 'pansionat', 'service', 'room', 'resident', 'contract',
        'provision_of_services', 'using_service', 'vladenie'
    )
    BEGIN
        RAISERROR('Unknown table name', 16, 1);
        RETURN;
    END

    DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM ' + QUOTENAME(@table_name) + N';';
    EXEC sp_executesql @sql;
END
GO

-- Manager contracts grouped by status
CREATE PROCEDURE sp_manager_contracts_status
    @manager_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        s.status,
        COUNT(c.id_contract) AS contracts,
        SUM(c.summa) AS total_revenue
    FROM status_of_contract s
    JOIN contract c ON c.status_of_contract = s.id_status_of_contract
    WHERE c.manager = @manager_id
    GROUP BY s.status
    ORDER BY s.status DESC;
END
GO

-- Manager contracts in period
CREATE PROCEDURE sp_manager_contracts_period
    @manager_id INT,
    @date_from DATE,
    @date_to DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        COUNT(c.id_contract) AS contracts,
        SUM(c.summa) AS total_revenue,
        AVG(CAST(c.summa AS DECIMAL(18,2))) AS avg_check
    FROM contract c
    WHERE c.manager = @manager_id
      AND c.start_date >= @date_from
      AND c.final_date <= @date_to;
END
GO

-- Manager contracts by room type in period
CREATE PROCEDURE sp_manager_room_type_stats
    @manager_id INT,
    @date_from DATE,
    @date_to DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        rt.type AS room_type,
        COUNT(c.id_contract) AS contracts,
        SUM(c.summa) AS total_revenue
    FROM room_type rt
    JOIN room r ON r.type = rt.id_type
    JOIN contract c ON c.room = r.id_room
    WHERE c.manager = @manager_id
      AND c.start_date >= @date_from
      AND c.final_date <= @date_to
    GROUP BY rt.type
    ORDER BY COUNT(c.id_contract) DESC;
END
GO
