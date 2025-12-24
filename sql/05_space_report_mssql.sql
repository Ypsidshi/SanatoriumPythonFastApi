-- Space usage report for all user tables
-- Run in SSMS: USE sanatorium; then execute this script.

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#space') IS NOT NULL DROP TABLE #space;
CREATE TABLE #space (
    name SYSNAME,
    rows VARCHAR(50),
    reserved VARCHAR(50),
    data VARCHAR(50),
    index_size VARCHAR(50),
    unused VARCHAR(50)
);

DECLARE @tbl SYSNAME;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT t.name
FROM sys.tables t
WHERE t.is_ms_shipped = 0
ORDER BY t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #space
    EXEC sp_spaceused @tbl;
    FETCH NEXT FROM cur INTO @tbl;
END
CLOSE cur;
DEALLOCATE cur;

SELECT *
FROM #space
ORDER BY name;
