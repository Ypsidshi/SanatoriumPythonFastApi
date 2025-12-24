-- Manager analytics queries (run-only, no DDL)

SET NOCOUNT ON;
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @date_from DATE = '2025-01-01';
DECLARE @date_to DATE = '2025-12-31';
DECLARE @manager_id INT = 1;
DECLARE @repeat INT = 50;

-- Manager contracts grouped by status
DECLARE @i INT = 0;
DECLARE @t DATETIME2 = SYSDATETIME();
WHILE @i < @repeat
BEGIN
    SELECT
        soc.status,
        COUNT(c.id_contract) AS contracts,
        SUM(c.summa) AS total_revenue
    FROM status_of_contract soc
    JOIN contract c ON c.status_of_contract = soc.id_status_of_contract
    WHERE c.manager = @manager_id
    GROUP BY soc.status
    ORDER BY soc.status DESC;

    SET @i += 1;
END
SELECT 'manager_status' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;

-- Manager contracts in period
SET @i = 0;
SET @t = SYSDATETIME();
WHILE @i < @repeat
BEGIN
    SELECT
        COUNT(c.id_contract) AS contracts,
        SUM(c.summa) AS total_revenue,
        AVG(CAST(c.summa AS DECIMAL(18,2))) AS avg_check
    FROM contract c
    WHERE c.manager = @manager_id
      AND c.start_date >= @date_from
      AND c.final_date <= @date_to;

    SET @i += 1;
END
SELECT 'manager_period' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;

-- Manager contracts by room type in period
SET @i = 0;
SET @t = SYSDATETIME();
WHILE @i < @repeat
BEGIN
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

    SET @i += 1;
END
SELECT 'manager_room_types' AS metric, DATEDIFF(ms, @t, SYSDATETIME()) AS elapsed_ms;
