-- Routines/triggers for PostgreSQL
-- Run: psql -U user -d sanatorium -f sql/02_operations_postgres.sql

-- Drop objects if exist
DROP VIEW IF EXISTS vw_services_availability;
DROP VIEW IF EXISTS vw_pansionat_stats;
DROP VIEW IF EXISTS vw_contract_occupancy;
DROP VIEW IF EXISTS vw_contract_revenue;
DROP FUNCTION IF EXISTS trg_service_price_bump();
DROP FUNCTION IF EXISTS trg_pansionat_heart_discount();
DROP FUNCTION IF EXISTS trg_service_heart_discount();
DROP FUNCTION IF EXISTS trg_contract_early_discount();
DROP FUNCTION IF EXISTS close_finished_contracts();

-- Views
CREATE VIEW vw_services_availability AS
SELECT
    p.id AS pansionat_id,
    p.name,
    p.vacation_type,
    p.medical_profile,
    COUNT(s.id) AS service_count,
    SUM(s.price) AS total_service_price
FROM pansionat p
LEFT JOIN service s ON s.pansionat_id = p.id AND s.is_active = TRUE
WHERE p.is_active = TRUE
GROUP BY p.id, p.name, p.vacation_type, p.medical_profile;

CREATE VIEW vw_pansionat_stats AS
SELECT
    year_built,
    COUNT(*) AS pansionats,
    SUM(room_count) AS rooms,
    AVG(room_count) AS avg_rooms
FROM pansionat
WHERE is_active = TRUE
GROUP BY year_built;

CREATE VIEW vw_contract_occupancy AS
SELECT
    p.id AS pansionat_id,
    p.name,
    COUNT(c.id) AS contracts
FROM pansionat p
JOIN contract c ON c.pansionat_id = p.id
WHERE c.status = 'active'
GROUP BY p.id, p.name;

CREATE VIEW vw_contract_revenue AS
SELECT
    p.id AS pansionat_id,
    p.name,
    SUM(c.final_cost) AS total_revenue,
    AVG(c.final_cost) AS avg_check
FROM pansionat p
JOIN contract c ON c.pansionat_id = p.id
WHERE c.status = 'active'
GROUP BY p.id, p.name;

-- Trigger: bump existing service prices by 5% when new service is added
CREATE OR REPLACE FUNCTION trg_service_price_bump() RETURNS TRIGGER AS $$
BEGIN
    UPDATE service
    SET price = price * 1.05
    WHERE pansionat_id = NEW.pansionat_id AND id <> NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_service_price_bump
AFTER INSERT ON service
FOR EACH ROW EXECUTE FUNCTION trg_service_price_bump();

-- Trigger: apply 20% discount to services when pansionat medical_profile = 'сердце'
CREATE OR REPLACE FUNCTION trg_pansionat_heart_discount() RETURNS TRIGGER AS $$
BEGIN
    IF lower(NEW.medical_profile) = 'сердце' THEN
        UPDATE service SET price = price * 0.8 WHERE pansionat_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pansionat_heart_discount
AFTER INSERT ON pansionat
FOR EACH ROW EXECUTE FUNCTION trg_pansionat_heart_discount();

-- Trigger: discount new service under heart profile
CREATE OR REPLACE FUNCTION trg_service_heart_discount() RETURNS TRIGGER AS $$
DECLARE
    profile_val VARCHAR(100);
BEGIN
    SELECT medical_profile INTO profile_val FROM pansionat WHERE id = NEW.pansionat_id;
    IF lower(profile_val) = 'сердце' THEN
        NEW.price := NEW.price * 0.8;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_service_heart_discount
BEFORE INSERT ON service
FOR EACH ROW EXECUTE FUNCTION trg_service_heart_discount();

-- Trigger: early booking discount (10% if check_in 30+ days from today)
CREATE OR REPLACE FUNCTION trg_contract_early_discount() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.check_in >= CURRENT_DATE + INTERVAL '30 days' THEN
        NEW.final_cost := NEW.base_cost * 0.9;
    ELSE
        NEW.final_cost := NEW.base_cost;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contract_early_discount
BEFORE INSERT ON contract
FOR EACH ROW EXECUTE FUNCTION trg_contract_early_discount();

-- Function to close finished contracts (call from cron/pgAgent/pg_cron)
CREATE OR REPLACE FUNCTION close_finished_contracts() RETURNS void AS $$
BEGIN
    UPDATE contract
    SET status = 'completed'
    WHERE status = 'active' AND check_out < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- To schedule with pg_cron (if extension is installed):
-- SELECT cron.schedule('close-contracts-daily', '0 2 * * *', $$SELECT close_finished_contracts();$$);
