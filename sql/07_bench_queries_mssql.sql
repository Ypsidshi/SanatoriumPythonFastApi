-- Benchmark queries for optimization checks (SQL Server)
-- Run in SSMS. Review STATISTICS IO/TIME and the Actual Execution Plan.

SET NOCOUNT ON;
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @date_from DATE = '2025-01-01';
DECLARE @date_to DATE = '2025-12-31';
DECLARE @administrator_id INT = 1;
DECLARE @manager_id INT = 1;

-- Availability report
SELECT
    p.id_pansionat,
    p.name,
    COUNT(pos.service) AS service_count
FROM pansionat p
LEFT JOIN provision_of_services pos ON pos.pansionat = p.id_pansionat
GROUP BY p.id_pansionat, p.name;

-- Pansionat stats by year
SELECT
    buiding_year,
    COUNT(*) AS pansionats
FROM pansionat
GROUP BY buiding_year;

-- Occupancy report (contracts intersecting range)
SELECT
    p.id_pansionat,
    p.name,
    COUNT(c.id_contract) AS contracts
FROM pansionat p
JOIN room r ON r.pansionat = p.id_pansionat
JOIN contract c ON c.room = r.id_room
WHERE c.start_date <= @date_to
  AND c.final_date >= @date_from
GROUP BY p.id_pansionat, p.name;

-- Revenue report (contracts fully inside range)
SELECT
    p.id_pansionat,
    p.name,
    SUM(c.summa) AS total_revenue,
    AVG(CAST(c.summa AS DECIMAL(18,2))) AS avg_check
FROM pansionat p
JOIN room r ON r.pansionat = p.id_pansionat
JOIN contract c ON c.room = r.id_room
WHERE c.start_date >= @date_from
  AND c.final_date <= @date_to
GROUP BY p.id_pansionat, p.name;

-- Admin summary (pansionats, rooms, residents, services)
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

-- Manager contracts by status
SELECT
    soc.status,
    COUNT(c.id_contract) AS contracts,
    SUM(c.summa) AS total_revenue
FROM status_of_contract soc
JOIN contract c ON c.status_of_contract = soc.id_status_of_contract
WHERE c.manager = @manager_id
GROUP BY soc.status
ORDER BY soc.status DESC;
