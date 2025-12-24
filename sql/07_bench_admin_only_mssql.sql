-- Admin analytics queries (run-only, no DDL)

SET NOCOUNT ON;
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @date_from DATE = '2025-01-01';
DECLARE @date_to DATE = '2025-12-31';
DECLARE @administrator_id INT = 1;
DECLARE @repeat INT = 50;

-- Admin summary (pansionats, rooms, residents, services)
DECLARE @i INT = 0;
DECLARE @t DATETIME2 = SYSDATETIME();
WHILE @i < @repeat
BEGIN
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
    GROUP BY a.id_administrator;

    SET @i += 1;
END
SELECT 'admin_summary' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;

-- Admin revenue by pansionat in period
SET @i = 0;
SET @t = SYSDATETIME();
WHILE @i < @repeat
BEGIN
    SELECT
        p.id_pansionat,
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

    SET @i += 1;
END
SELECT 'admin_revenue' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;

-- Admin top services (offered across admin pansionats)
SET @i = 0;
SET @t = SYSDATETIME();
WHILE @i < @repeat
BEGIN
    SELECT
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

    SET @i += 1;
END
SELECT 'admin_top_services' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;

-- Availability report
SET @i = 0;
SET @t = SYSDATETIME();
WHILE @i < @repeat
BEGIN
    SELECT
        p.id_pansionat,
        p.name,
        COUNT(pos.service) AS service_count
    FROM pansionat p
    LEFT JOIN provision_of_services pos ON pos.pansionat = p.id_pansionat
    GROUP BY p.id_pansionat, p.name;

    SET @i += 1;
END
SELECT 'availability' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;

-- Pansionat stats by year
SET @i = 0;
SET @t = SYSDATETIME();
WHILE @i < @repeat
BEGIN
    SELECT
        buiding_year,
        COUNT(*) AS pansionats
    FROM pansionat
    GROUP BY buiding_year;

    SET @i += 1;
END
SELECT 'pansionat_stats' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;

-- Complex admin analytics: per-pansionat KPIs with service usage, revenue, and occupancy
SET @i = 0;
SET @t = SYSDATETIME();
WHILE @i < @repeat
BEGIN
    ;WITH admin_pansionats AS (
        SELECT p.id_pansionat, p.name
        FROM pansionat p
        JOIN vladenie v ON v.pansionat = p.id_pansionat
        WHERE v.administrator = @administrator_id
    ),
    contracts_base AS (
        SELECT
            p.id_pansionat,
            c.id_contract,
            c.summa,
            c.start_date,
            c.final_date,
            DATEDIFF(DAY, c.start_date, c.final_date) + 1 AS days_count
        FROM admin_pansionats p
        JOIN room r ON r.pansionat = p.id_pansionat
        JOIN contract c ON c.room = r.id_room
        WHERE c.start_date <= @date_to
          AND c.final_date >= @date_from
    ),
    service_usage AS (
        SELECT
            p.id_pansionat,
            s.id_service,
            COUNT(*) AS usage_count
        FROM admin_pansionats p
        JOIN resident res ON res.pansionat = p.id_pansionat
        JOIN using_service us ON us.resident = res.id_resident
        JOIN service s ON s.id_service = us.service
        GROUP BY p.id_pansionat, s.id_service
    ),
    top_services AS (
        SELECT
            su.id_pansionat,
            su.id_service,
            su.usage_count,
            ROW_NUMBER() OVER (PARTITION BY su.id_pansionat ORDER BY su.usage_count DESC, su.id_service) AS rn
        FROM service_usage su
    ),
    rooms_total AS (
        SELECT r.pansionat AS id_pansionat, COUNT(*) AS rooms_total
        FROM room r
        GROUP BY r.pansionat
    ),
    contract_kpis AS (
        SELECT
            cb.id_pansionat,
            COUNT(DISTINCT cb.id_contract) AS contracts_total,
            SUM(cb.summa) AS revenue_total,
            AVG(CAST(cb.summa AS DECIMAL(18,2))) AS avg_check,
            SUM(cb.days_count) AS occupied_days
        FROM contracts_base cb
        GROUP BY cb.id_pansionat
    )
    SELECT
        ap.id_pansionat,
        ap.name,
        ck.contracts_total,
        ck.revenue_total,
        ck.avg_check,
        rt.rooms_total,
        ck.occupied_days,
        CAST(ck.occupied_days AS DECIMAL(18,2)) / NULLIF(rt.rooms_total, 0) AS occupancy_load,
        ts.id_service AS top_service_id,
        ts.usage_count AS top_service_usage
    FROM admin_pansionats ap
    LEFT JOIN contract_kpis ck ON ck.id_pansionat = ap.id_pansionat
    LEFT JOIN rooms_total rt ON rt.id_pansionat = ap.id_pansionat
    LEFT JOIN top_services ts ON ts.id_pansionat = ap.id_pansionat AND ts.rn = 1
    ORDER BY ck.revenue_total DESC, ap.id_pansionat;

    SET @i += 1;
END
SELECT 'admin_complex' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;
