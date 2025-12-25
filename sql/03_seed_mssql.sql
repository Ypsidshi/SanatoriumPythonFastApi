-- Seed test data for MSSQL schema.
-- WARNING: This script clears existing data in the listed tables.
USE sanatorium;
GO

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
DELETE FROM health_profile;
DELETE FROM status_room;
DELETE FROM status_of_contract;
DELETE FROM room_type;

INSERT INTO administrator (surname, name, otchestvo, adress, mail, telephone)
VALUES ('Иванов', 'Иван', 'Иванович', 'Адрес 1', 'admin1@example.com', 79000000001);

INSERT INTO manager (surname, name, otchestvo, adress, mail, telephone)
VALUES ('Петров', 'Петр', 'Петрович', 'Адрес 2', 'manager1@example.com', 79000000002);

INSERT INTO health_profile (profile)
VALUES ('сердце'), ('нервы'), ('опорно-двигательный');

INSERT INTO status_room (status)
VALUES (1), (0);

INSERT INTO status_of_contract (status)
VALUES (1), (0);

INSERT INTO room_type (type)
VALUES ('Стандарт'), ('Люкс');

INSERT INTO service (name, price, time)
VALUES ('Массаж', 1000, '60 мин'),
       ('Бассейн', 500, '30 мин'),
       ('Сауна', 800, '45 мин');

INSERT INTO pansionat (name, photo, buiding_year, administrator, health_profile)
VALUES ('Пансионат 1', NULL, 2010, 1, 1),
       ('Пансионат 2', NULL, 2015, 1, 2);

INSERT INTO vladenie (administrator, pansionat)
VALUES (1, 1), (1, 2);

INSERT INTO room (price, pansionat, type, status_room)
VALUES (2000, 1, 1, 1),
       (3500, 1, 2, 1),
       (1800, 2, 1, 1);

INSERT INTO resident (surname, name, otchestvo, mail, telephone, passport, manager)
VALUES ('Сидоров', 'Сидор', 'Сидорович', 'res1@example.com', 79000000003, 1234567890, 1),
       ('Ильина', 'Анна', 'Павловна', 'res2@example.com', 79000000004, 2345678901, 1);

INSERT INTO provision_of_services (service, pansionat)
VALUES (1, 1), (2, 1), (3, 1),
       (2, 2);

INSERT INTO using_service (service, resident)
VALUES (1, 1), (2, 1), (2, 2);

INSERT INTO contract (start_date, final_date, summa, manager, room, resident, status_of_contract)
VALUES ('2025-01-10', '2025-01-20', 20000, 1, 1, 1, 1),
       ('2025-02-05', '2025-02-15', 18000, 1, 3, 2, 1);
