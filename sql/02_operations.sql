-- Stored routines and triggers that implement business rules from ОписаниеСкриптовДляMySQL.md
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_create_pansionat $$
CREATE PROCEDURE sp_create_pansionat(
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_vacation_type VARCHAR(100),
    IN p_medical_profile VARCHAR(100),
    IN p_room_count INT,
    IN p_floor_count INT,
    IN p_year_built SMALLINT
)
BEGIN
    DECLARE new_id BIGINT;
    START TRANSACTION;
    INSERT INTO pansionat(name, description, vacation_type, medical_profile, room_count, floor_count, year_built)
    VALUES (p_name, p_description, p_vacation_type, p_medical_profile, p_room_count, p_floor_count, p_year_built);
    SET new_id = LAST_INSERT_ID();
    COMMIT;
    SELECT new_id AS id;
END $$

DROP PROCEDURE IF EXISTS sp_update_pansionat $$
CREATE PROCEDURE sp_update_pansionat(
    IN p_id BIGINT,
    IN p_description TEXT,
    IN p_vacation_type VARCHAR(100),
    IN p_medical_profile VARCHAR(100),
    IN p_room_count INT,
    IN p_floor_count INT,
    IN p_year_built SMALLINT
)
BEGIN
    UPDATE pansionat
    SET description = IFNULL(p_description, description),
        vacation_type = IFNULL(p_vacation_type, vacation_type),
        medical_profile = IFNULL(p_medical_profile, medical_profile),
        room_count = IFNULL(p_room_count, room_count),
        floor_count = IFNULL(p_floor_count, floor_count),
        year_built = IFNULL(p_year_built, year_built),
        updated_at = NOW()
    WHERE id = p_id AND is_active = 1;
END $$

DROP PROCEDURE IF EXISTS sp_soft_delete_pansionat $$
CREATE PROCEDURE sp_soft_delete_pansionat(IN p_id BIGINT)
BEGIN
    UPDATE pansionat SET is_active = 0 WHERE id = p_id;
    UPDATE service SET is_active = 0 WHERE pansionat_id = p_id;
END $$

-- Analytics: availability of services by type/profile.
DROP VIEW IF EXISTS vw_services_availability $$
CREATE VIEW vw_services_availability AS
SELECT
    p.id AS pansionat_id,
    p.name,
    p.vacation_type,
    p.medical_profile,
    COUNT(s.id) AS service_count,
    SUM(s.price) AS total_service_price
FROM pansionat p
LEFT JOIN service s ON s.pansionat_id = p.id AND s.is_active = 1
WHERE p.is_active = 1
GROUP BY p.id, p.name, p.vacation_type, p.medical_profile;

-- Stats: rooms per year built.
DROP VIEW IF EXISTS vw_pansionat_stats $$
CREATE VIEW vw_pansionat_stats AS
SELECT
    year_built,
    COUNT(*) AS pansionats,
    SUM(room_count) AS rooms,
    AVG(room_count) AS avg_rooms
FROM pansionat
WHERE is_active = 1
GROUP BY year_built;

-- Trigger 6 (Admin): auto-increase price of existing services when a new one is added.
DROP TRIGGER IF EXISTS trg_service_price_bump $$
CREATE TRIGGER trg_service_price_bump
AFTER INSERT ON service
FOR EACH ROW
BEGIN
    -- Increase all other services of the same pansionat by 5% when a new service is introduced.
    UPDATE service
    SET price = price * 1.05
    WHERE pansionat_id = NEW.pansionat_id AND id <> NEW.id;
END $$

-- Trigger 7 (Admin): apply 20% discount to services for medical profile "сердце".
DROP TRIGGER IF EXISTS trg_pansionat_heart_discount $$
CREATE TRIGGER trg_pansionat_heart_discount
AFTER INSERT ON pansionat
FOR EACH ROW
BEGIN
    IF LOWER(NEW.medical_profile) = 'сердце' THEN
        UPDATE service SET price = price * 0.8 WHERE pansionat_id = NEW.id;
    END IF;
END $$

-- Also ensure any new service under a "сердце" pansionat is discounted.
DROP TRIGGER IF EXISTS trg_service_heart_discount $$
CREATE TRIGGER trg_service_heart_discount
BEFORE INSERT ON service
FOR EACH ROW
BEGIN
    DECLARE profile_val VARCHAR(100);
    SELECT medical_profile INTO profile_val FROM pansionat WHERE id = NEW.pansionat_id;
    IF LOWER(profile_val) = 'сердце' THEN
        SET NEW.price = NEW.price * 0.8;
    END IF;
END $$

-- Manager 1: create contract with transaction.
DROP PROCEDURE IF EXISTS sp_create_contract $$
CREATE PROCEDURE sp_create_contract(
    IN p_pansionat_id BIGINT,
    IN p_client_id BIGINT,
    IN p_check_in DATE,
    IN p_check_out DATE,
    IN p_room_type VARCHAR(120),
    IN p_base_cost DECIMAL(12,2)
)
BEGIN
    START TRANSACTION;
    INSERT INTO contract(pansionat_id, client_id, check_in, check_out, room_type, base_cost, final_cost, status)
    VALUES (p_pansionat_id, p_client_id, p_check_in, p_check_out, p_room_type, p_base_cost, p_base_cost, 'active');
    COMMIT;
    SELECT LAST_INSERT_ID() AS id;
END $$

DROP PROCEDURE IF EXISTS sp_update_contract $$
CREATE PROCEDURE sp_update_contract(
    IN p_id BIGINT,
    IN p_check_in DATE,
    IN p_check_out DATE,
    IN p_room_type VARCHAR(120),
    IN p_base_cost DECIMAL(12,2),
    IN p_status VARCHAR(30)
)
BEGIN
    UPDATE contract
    SET check_in = IFNULL(p_check_in, check_in),
        check_out = IFNULL(p_check_out, check_out),
        room_type = IFNULL(p_room_type, room_type),
        base_cost = IFNULL(p_base_cost, base_cost),
        final_cost = IFNULL(p_base_cost, final_cost),
        status = IFNULL(p_status, status),
        updated_at = NOW()
    WHERE id = p_id AND status NOT IN ('deleted', 'cancelled');
END $$

DROP PROCEDURE IF EXISTS sp_soft_delete_contract $$
CREATE PROCEDURE sp_soft_delete_contract(IN p_id BIGINT)
BEGIN
    UPDATE contract SET status = 'deleted' WHERE id = p_id;
END $$

-- Manager analytics views
DROP VIEW IF EXISTS vw_contract_occupancy $$
CREATE VIEW vw_contract_occupancy AS
SELECT
    p.id AS pansionat_id,
    p.name,
    COUNT(c.id) AS contracts
FROM pansionat p
JOIN contract c ON c.pansionat_id = p.id
WHERE c.status = 'active'
GROUP BY p.id, p.name;

DROP VIEW IF EXISTS vw_contract_revenue $$
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

-- Manager 6: early booking discount (e.g., 10% if booked 30+ days before check-in).
DROP TRIGGER IF EXISTS trg_contract_early_discount $$
CREATE TRIGGER trg_contract_early_discount
BEFORE INSERT ON contract
FOR EACH ROW
BEGIN
    IF DATEDIFF(NEW.check_in, CURRENT_DATE()) >= 30 THEN
        SET NEW.final_cost = NEW.base_cost * 0.9;
    ELSE
        SET NEW.final_cost = NEW.base_cost;
    END IF;
END $$

-- Manager 7: auto-close finished contracts (daily event at 02:00).
DROP EVENT IF EXISTS ev_close_finished_contracts $$
CREATE EVENT ev_close_finished_contracts
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE, '02:00:00'))
DO
    UPDATE contract
    SET status = 'completed'
    WHERE status = 'active' AND check_out < CURRENT_DATE();
$$

DELIMITER ;
