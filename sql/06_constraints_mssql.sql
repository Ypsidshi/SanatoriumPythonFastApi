-- Additional integrity constraints (CHECK) for MSSQL
-- Run after sql/01_schema_mssql.sql. If existing data violates constraints, the ALTER will fail.

-- Manager
ALTER TABLE manager ADD CONSTRAINT ck_manager_mail
CHECK (mail LIKE '%@%.%');
ALTER TABLE manager ADD CONSTRAINT ck_manager_telephone
CHECK (telephone BETWEEN 1000000000 AND 99999999999);
ALTER TABLE manager ADD CONSTRAINT ck_manager_surname_not_empty
CHECK (LEN(LTRIM(RTRIM(surname))) > 0);
ALTER TABLE manager ADD CONSTRAINT ck_manager_name_not_empty
CHECK (LEN(LTRIM(RTRIM(name))) > 0);
ALTER TABLE manager ADD CONSTRAINT ck_manager_otch_not_empty
CHECK (LEN(LTRIM(RTRIM(otchestvo))) > 0);
ALTER TABLE manager ADD CONSTRAINT ck_manager_adress_not_empty
CHECK (LEN(LTRIM(RTRIM(adress))) > 0);
ALTER TABLE manager ADD CONSTRAINT ck_manager_surname_cyr
CHECK (
    surname COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND surname COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);
ALTER TABLE manager ADD CONSTRAINT ck_manager_name_cyr
CHECK (
    name COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND name COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);
ALTER TABLE manager ADD CONSTRAINT ck_manager_otch_cyr
CHECK (
    otchestvo COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND otchestvo COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);

-- Administrator
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_mail
CHECK (mail LIKE '%@%.%');
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_telephone
CHECK (telephone BETWEEN 1000000000 AND 99999999999);
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_surname_not_empty
CHECK (LEN(LTRIM(RTRIM(surname))) > 0);
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_name_not_empty
CHECK (LEN(LTRIM(RTRIM(name))) > 0);
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_otch_not_empty
CHECK (LEN(LTRIM(RTRIM(otchestvo))) > 0);
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_adress_not_empty
CHECK (LEN(LTRIM(RTRIM(adress))) > 0);
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_surname_cyr
CHECK (
    surname COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND surname COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_name_cyr
CHECK (
    name COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND name COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);
ALTER TABLE administrator ADD CONSTRAINT ck_administrator_otch_cyr
CHECK (
    otchestvo COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND otchestvo COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);

-- Health profile
ALTER TABLE health_profile ADD CONSTRAINT ck_health_profile_not_empty
CHECK (LEN(LTRIM(RTRIM(profile))) > 0);

-- Pansionat
ALTER TABLE pansionat ADD CONSTRAINT ck_pansionat_name_not_empty
CHECK (LEN(LTRIM(RTRIM(name))) > 0);
ALTER TABLE pansionat ADD CONSTRAINT ck_pansionat_building_year
CHECK (buiding_year BETWEEN 1900 AND YEAR(GETDATE()));

-- Service
ALTER TABLE service ADD CONSTRAINT ck_service_name_not_empty
CHECK (LEN(LTRIM(RTRIM(name))) > 0);
ALTER TABLE service ADD CONSTRAINT ck_service_price_positive
CHECK (price > 0);
ALTER TABLE service ADD CONSTRAINT ck_service_time_not_empty
CHECK (LEN(LTRIM(RTRIM(time))) > 0);

-- Status checks
ALTER TABLE status_room ADD CONSTRAINT ck_status_room_bit
CHECK (status IN (0, 1));
ALTER TABLE status_of_contract ADD CONSTRAINT ck_status_contract_bit
CHECK (status IN (0, 1));

-- Room type
ALTER TABLE room_type ADD CONSTRAINT ck_room_type_not_empty
CHECK (LEN(LTRIM(RTRIM(type))) > 0);

-- Room
ALTER TABLE room ADD CONSTRAINT ck_room_price_positive
CHECK (price > 0);

-- Resident
ALTER TABLE resident ADD CONSTRAINT ck_resident_mail
CHECK (mail LIKE '%@%.%');
ALTER TABLE resident ADD CONSTRAINT ck_resident_telephone
CHECK (telephone BETWEEN 1000000000 AND 99999999999);
ALTER TABLE resident ADD CONSTRAINT ck_resident_passport
CHECK (passport BETWEEN 1000000000 AND 99999999999);
ALTER TABLE resident ADD CONSTRAINT ck_resident_surname_not_empty
CHECK (LEN(LTRIM(RTRIM(surname))) > 0);
ALTER TABLE resident ADD CONSTRAINT ck_resident_name_not_empty
CHECK (LEN(LTRIM(RTRIM(name))) > 0);
ALTER TABLE resident ADD CONSTRAINT ck_resident_otch_not_empty
CHECK (LEN(LTRIM(RTRIM(otchestvo))) > 0);
ALTER TABLE resident ADD CONSTRAINT ck_resident_surname_cyr
CHECK (
    surname COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND surname COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);
ALTER TABLE resident ADD CONSTRAINT ck_resident_name_cyr
CHECK (
    name COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND name COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);
ALTER TABLE resident ADD CONSTRAINT ck_resident_otch_cyr
CHECK (
    otchestvo COLLATE Cyrillic_General_CI_AS LIKE '[А-ЯЁ]%'
    AND otchestvo COLLATE Cyrillic_General_CI_AS NOT LIKE '%[^А-ЯЁа-яё- ]%'
);

-- Contract
ALTER TABLE contract ADD CONSTRAINT ck_contract_summa_positive
CHECK (summa > 0);
ALTER TABLE contract ADD CONSTRAINT ck_contract_dates
CHECK (start_date <= final_date);
