-- Mass seed for SQL Server based on current schema.
-- Adjust counts as needed.
USE sanatorium;
GO
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
DECLARE @vladenie_count INT = 4000;
DECLARE @provision_count INT = 200000;
DECLARE @using_count INT = 500000;

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
DELETE FROM status_room;
DELETE FROM status_of_contract;
DELETE FROM room_type;
DELETE FROM health_profile;

DBCC CHECKIDENT('administrator', RESEED, 0);
DBCC CHECKIDENT('manager', RESEED, 0);
DBCC CHECKIDENT('health_profile', RESEED, 0);
DBCC CHECKIDENT('status_room', RESEED, 0);
DBCC CHECKIDENT('status_of_contract', RESEED, 0);
DBCC CHECKIDENT('room_type', RESEED, 0);
DBCC CHECKIDENT('pansionat', RESEED, 0);
DBCC CHECKIDENT('room', RESEED, 0);
DBCC CHECKIDENT('resident', RESEED, 0);
DBCC CHECKIDENT('contract', RESEED, 0);
DBCC CHECKIDENT('service', RESEED, 0);

;WITH src AS (
    SELECT profile
    FROM (VALUES
        (N'сердечно-сосудистый'),
        (N'нервная система'),
        (N'опорно-двигательный'),
        (N'дыхательная система'),
        (N'пищеварительная система'),
        (N'эндокринная система'),
        (N'урологический'),
        (N'гинекологический'),
        (N'реабилитационный'),
        (N'общеоздоровительный'),
        (N'кожные заболевания'),
        (N'аллергологический'),
        (N'ЛОР профиль'),
        (N'офтальмологический'),
        (N'психосоматика'),
        (N'неврология'),
        (N'кардиология'),
        (N'ортопедия'),
        (N'метаболический'),
        (N'педиатрический')
    ) v(profile)
)
INSERT INTO health_profile (profile)
SELECT TOP (@health_profile_count) profile
FROM src;

INSERT INTO status_room (status) VALUES (1), (0);
INSERT INTO status_of_contract (status) VALUES (1), (0);

;WITH src AS (
    SELECT type_name
    FROM (VALUES
        (N'Стандарт'),
        (N'Улучшенный'),
        (N'Люкс'),
        (N'Полулюкс'),
        (N'Семейный'),
        (N'С видом на море'),
        (N'Эконом'),
        (N'Бизнес'),
        (N'Апартаменты'),
        (N'Коттедж')
    ) v(type_name)
)
INSERT INTO room_type (type)
SELECT TOP (@type_count) type_name
FROM src;

;WITH male_surnames AS (
    SELECT surname FROM (VALUES
        (N'Иванов'), (N'Петров'), (N'Сидоров'), (N'Кузнецов'), (N'Смирнов'),
        (N'Морозов'), (N'Федоров'), (N'Попов'), (N'Васильев'), (N'Новиков'),
        (N'Орлов'), (N'Соколов'), (N'Николаев'), (N'Волков'), (N'Егоров'),
        (N'Ковалев'), (N'Григорьев'), (N'Зайцев'), (N'Макаров'), (N'Борисов'),
        (N'Лебедев'), (N'Павлов'), (N'Кириллов'), (N'Громов'), (N'Куликов')
    ) v(surname)
),
female_surnames AS (
    SELECT surname FROM (VALUES
        (N'Иванова'), (N'Петрова'), (N'Сидорова'), (N'Кузнецова'), (N'Смирнова'),
        (N'Морозова'), (N'Федорова'), (N'Попова'), (N'Васильева'), (N'Новикова'),
        (N'Орлова'), (N'Соколова'), (N'Николаева'), (N'Волкова'), (N'Егорова'),
        (N'Ковалева'), (N'Григорьева'), (N'Зайцева'), (N'Макарова'), (N'Борисова'),
        (N'Лебедева'), (N'Павлова'), (N'Кириллова'), (N'Громова'), (N'Куликова')
    ) v(surname)
),
male_names AS (
    SELECT name FROM (VALUES
        (N'Иван'), (N'Петр'), (N'Алексей'), (N'Антон'), (N'Дмитрий'),
        (N'Сергей'), (N'Николай'), (N'Руслан'), (N'Михаил'), (N'Андрей'),
        (N'Роман'), (N'Константин'), (N'Павел'), (N'Георгий'), (N'Виктор'),
        (N'Евгений'), (N'Максим'), (N'Илья'), (N'Глеб'), (N'Арсений'),
        (N'Владимир'), (N'Тимофей'), (N'Григорий'), (N'Денис'), (N'Ярослав')
    ) v(name)
),
female_names AS (
    SELECT name FROM (VALUES
        (N'Мария'), (N'Елена'), (N'Анна'), (N'Ольга'), (N'Наталья'),
        (N'Татьяна'), (N'Светлана'), (N'Ирина'), (N'Юлия'), (N'Валерия'),
        (N'Вероника'), (N'Ксения'), (N'Анастасия'), (N'Полина'), (N'Дарья'),
        (N'Алина'), (N'Екатерина'), (N'София'), (N'Елизавета'), (N'Виктория'),
        (N'Александра'), (N'Марина'), (N'Людмила'), (N'Надежда'), (N'Олеся')
    ) v(name)
),
male_otch AS (
    SELECT otchestvo FROM (VALUES
        (N'Иванович'), (N'Петрович'), (N'Алексеевич'), (N'Дмитриевич'), (N'Сергеевич'),
        (N'Николаевич'), (N'Михайлович'), (N'Андреевич'), (N'Романович'), (N'Константинович'),
        (N'Павлович'), (N'Георгиевич'), (N'Викторович'), (N'Евгеньевич'), (N'Максимович'),
        (N'Ильич'), (N'Глебович'), (N'Арсеньевич'), (N'Владимирович'), (N'Тимофеевич'),
        (N'Григорьевич'), (N'Денисович'), (N'Ярославович'), (N'Семенович'), (N'Олегович')
    ) v(otchestvo)
),
female_otch AS (
    SELECT otchestvo FROM (VALUES
        (N'Ивановна'), (N'Петровна'), (N'Алексеевна'), (N'Дмитриевна'), (N'Сергеевна'),
        (N'Николаевна'), (N'Михайловна'), (N'Андреевна'), (N'Романовна'), (N'Константиновна'),
        (N'Павловна'), (N'Георгиевна'), (N'Викторовна'), (N'Евгеньевна'), (N'Максимовна'),
        (N'Ильинична'), (N'Глебовна'), (N'Арсеньевна'), (N'Владимировна'), (N'Тимофеевна'),
        (N'Григорьевна'), (N'Денисовна'), (N'Ярославовна'), (N'Семеновна'), (N'Олеговна')
    ) v(otchestvo)
),
addr AS (
    SELECT adress FROM (VALUES
        (N'ул. Ленина'),
        (N'пр. Мира'),
        (N'ул. Победы'),
        (N'ул. Советская'),
        (N'ул. Гагарина'),
        (N'ул. Центральная'),
        (N'ул. Набережная'),
        (N'ул. Садовая'),
        (N'ул. Молодежная'),
        (N'ул. Школьная'),
        (N'ул. Парковая'),
        (N'ул. Заречная'),
        (N'ул. Полевая'),
        (N'ул. Луговая'),
        (N'ул. Лесная'),
        (N'ул. Кленовая'),
        (N'ул. Сиреневая'),
        (N'ул. Яблоневая'),
        (N'ул. Северная'),
        (N'ул. Южная'),
        (N'пр. Космонавтов'),
        (N'ул. Октябрьская'),
        (N'ул. Первомайская'),
        (N'ул. Солнечная'),
        (N'ул. Пролетарская'),
        (N'ул. Комсомольская'),
        (N'ул. Карла Маркса'),
        (N'ул. Кирова'),
        (N'ул. Пушкина'),
        (N'ул. Чехова')
    ) v(adress)
),
addr_indexed AS (
    SELECT
        adress,
        ROW_NUMBER() OVER (ORDER BY adress) AS rn,
        COUNT(*) OVER () AS addr_count
    FROM addr
),
mail_domains AS (
    SELECT domain FROM (VALUES
        (N'example.com'),
        (N'corp.local'),
        (N'admin.net'),
        (N'staff.org'),
        (N'mail.ru'),
        (N'inbox.ru'),
        (N'yandex.ru'),
        (N'gmail.com'),
        (N'outlook.com'),
        (N'proton.me')
    ) v(domain)
),
mail_tags AS (
    SELECT tag FROM (VALUES
        (N'root'), (N'control'), (N'office'), (N'chief'), (N'helpdesk'),
        (N'hr'), (N'audit'), (N'sec'), (N'ops'), (N'admin')
    ) v(tag)
),
full_names AS (
    SELECT
        fn.surname,
        fn.name,
        fn.otchestvo,
        ROW_NUMBER() OVER (ORDER BY CHECKSUM(fn.surname + fn.name + fn.otchestvo)) AS rn
    FROM (
        SELECT s.surname, n.name, o.otchestvo
        FROM male_surnames s
        CROSS JOIN male_names n
        CROSS JOIN male_otch o
        UNION ALL
        SELECT s.surname, n.name, o.otchestvo
        FROM female_surnames s
        CROSS JOIN female_names n
        CROSS JOIN female_otch o
    ) fn
)
INSERT INTO administrator (surname, name, otchestvo, adress, mail, telephone)
SELECT TOP (@administrator_count)
    fn.surname,
    fn.name,
    fn.otchestvo,
    CONCAT(
        a.adress, N', д. ', (seed.addr_seed % 180) + 1,
        N', корп. ', (seed.addr_seed % 7) + 1,
        N', кв. ', (seed.addr_seed % 200) + 1
    ),
    CONCAT(t.tag, N'.', fn.rn, N'.', (seed.addr_seed % 97) + 2, N'@', d.domain),
    7900000000 + ((fn.rn * 7919) % 1000000000)
FROM full_names fn
CROSS APPLY (SELECT TOP 1 * FROM mail_domains ORDER BY CHECKSUM(NEWID())) d
CROSS APPLY (SELECT TOP 1 * FROM mail_tags ORDER BY CHECKSUM(NEWID())) t
CROSS APPLY (
    SELECT ABS(CHECKSUM(fn.surname + fn.name + fn.otchestvo + CAST(fn.rn AS NVARCHAR(10)))) AS addr_seed
) seed
CROSS APPLY (
    SELECT ai.adress
    FROM addr_indexed ai
    WHERE ai.rn = (seed.addr_seed % ai.addr_count) + 1
) a
ORDER BY fn.rn;

;WITH male_surnames AS (
    SELECT surname FROM (VALUES
        (N'Абрамов'), (N'Антонов'), (N'Белов'), (N'Власов'), (N'Гусев'),
        (N'Давыдов'), (N'Дорохов'), (N'Ермаков'), (N'Жуков'), (N'Захаров'),
        (N'Исаев'), (N'Киселев'), (N'Крылов'), (N'Лазарев'), (N'Мельников'),
        (N'Никитин'), (N'Осипов'), (N'Романов'), (N'Савельев'), (N'Тарасов'),
        (N'Фролов'), (N'Харитонов'), (N'Чистяков'), (N'Шестаков'), (N'Фомин')
    ) v(surname)
),
female_surnames AS (
    SELECT surname FROM (VALUES
        (N'Абрамова'), (N'Антонова'), (N'Белова'), (N'Власова'), (N'Гусева'),
        (N'Давыдова'), (N'Дорохова'), (N'Ермакова'), (N'Жукова'), (N'Захарова'),
        (N'Исаева'), (N'Киселева'), (N'Крылова'), (N'Лазарева'), (N'Мельникова'),
        (N'Никитина'), (N'Осипова'), (N'Романова'), (N'Савельева'), (N'Тарасова'),
        (N'Фролова'), (N'Харитонова'), (N'Чистякова'), (N'Шестакова'), (N'Фомина')
    ) v(surname)
),
male_names AS (
    SELECT name FROM (VALUES
        (N'Игорь'), (N'Глеб'), (N'Никита'), (N'Евгений'), (N'Владислав'),
        (N'Матвей'), (N'Тимофей'), (N'Платон'), (N'Денис'), (N'Ярослав'),
        (N'Степан'), (N'Арсений'), (N'Артемий'), (N'Григорий'), (N'Павел'),
        (N'Руслан'), (N'Сергей'), (N'Константин'), (N'Виктор'), (N'Андрей'),
        (N'Николай'), (N'Максим'), (N'Антон'), (N'Дмитрий'), (N'Роман')
    ) v(name)
),
female_names AS (
    SELECT name FROM (VALUES
        (N'Светлана'), (N'Дарья'), (N'Олеся'), (N'Людмила'), (N'Алина'),
        (N'Надежда'), (N'Валерия'), (N'Вероника'), (N'Марина'), (N'Ева'),
        (N'Инна'), (N'Полина'), (N'Елизавета'), (N'Татьяна'), (N'Ирина'),
        (N'Ольга'), (N'Юлия'), (N'Ксения'), (N'Анастасия'), (N'Наталья'),
        (N'София'), (N'Екатерина'), (N'Анна'), (N'Виктория'), (N'Александра')
    ) v(name)
),
male_otch AS (
    SELECT otchestvo FROM (VALUES
        (N'Сергеевич'), (N'Владимирович'), (N'Олегович'), (N'Андреевич'), (N'Петрович'),
        (N'Ильич'), (N'Дмитриевич'), (N'Васильевич'), (N'Романович'), (N'Алексеевич'),
        (N'Семенович'), (N'Георгиевич'), (N'Игоревич'), (N'Викторович'), (N'Николаевич'),
        (N'Егорович'), (N'Олегович'), (N'Иванович'), (N'Максимович'), (N'Павлович'),
        (N'Арсеньевич'), (N'Глебович'), (N'Денисович'), (N'Ярославович'), (N'Тимофеевич')
    ) v(otchestvo)
),
female_otch AS (
    SELECT otchestvo FROM (VALUES
        (N'Сергеевна'), (N'Владимировна'), (N'Олеговна'), (N'Андреевна'), (N'Петровна'),
        (N'Ильинична'), (N'Дмитриевна'), (N'Васильевна'), (N'Романовна'), (N'Алексеевна'),
        (N'Семеновна'), (N'Георгиевна'), (N'Игоревна'), (N'Викторовна'), (N'Николаевна'),
        (N'Егоровна'), (N'Ивановна'), (N'Максимовна'), (N'Павловна'), (N'Арсеньевна'),
        (N'Глебовна'), (N'Денисовна'), (N'Ярославовна'), (N'Тимофеевна'), (N'Константиновна')
    ) v(otchestvo)
),
addr AS (
    SELECT adress FROM (VALUES
        (N'ул. Ленина'),
        (N'пр. Мира'),
        (N'ул. Победы'),
        (N'ул. Советская'),
        (N'ул. Гагарина'),
        (N'ул. Центральная'),
        (N'ул. Набережная'),
        (N'ул. Садовая'),
        (N'ул. Молодежная'),
        (N'ул. Школьная'),
        (N'ул. Парковая'),
        (N'ул. Заречная'),
        (N'ул. Полевая'),
        (N'ул. Луговая'),
        (N'ул. Лесная'),
        (N'ул. Кленовая'),
        (N'ул. Сиреневая'),
        (N'ул. Яблоневая'),
        (N'ул. Северная'),
        (N'ул. Южная'),
        (N'пр. Космонавтов'),
        (N'ул. Октябрьская'),
        (N'ул. Первомайская'),
        (N'ул. Солнечная'),
        (N'ул. Пролетарская'),
        (N'ул. Комсомольская'),
        (N'ул. Карла Маркса'),
        (N'ул. Кирова'),
        (N'ул. Пушкина'),
        (N'ул. Чехова')
    ) v(adress)
),
addr_indexed AS (
    SELECT
        adress,
        ROW_NUMBER() OVER (ORDER BY adress) AS rn,
        COUNT(*) OVER () AS addr_count
    FROM addr
),
mail_domains AS (
    SELECT domain FROM (VALUES
        (N'example.com'),
        (N'corp.local'),
        (N'admin.net'),
        (N'staff.org'),
        (N'mail.ru'),
        (N'inbox.ru'),
        (N'yandex.ru'),
        (N'gmail.com'),
        (N'outlook.com'),
        (N'proton.me')
    ) v(domain)
),
mail_tags AS (
    SELECT tag FROM (VALUES
        (N'frontdesk'), (N'booking'), (N'service'), (N'sales'), (N'concierge'),
        (N'info'), (N'care'), (N'manager'), (N'ops'), (N'reception')
    ) v(tag)
),
male_full_names AS (
    SELECT
        s.surname,
        n.name,
        o.otchestvo
    FROM male_surnames s
    CROSS JOIN male_names n
    CROSS JOIN male_otch o
),
female_full_names AS (
    SELECT
        s.surname,
        n.name,
        o.otchestvo
    FROM female_surnames s
    CROSS JOIN female_names n
    CROSS JOIN female_otch o
),
full_names AS (
    SELECT
        fn.surname,
        fn.name,
        fn.otchestvo,
        ROW_NUMBER() OVER (ORDER BY CHECKSUM(fn.surname + fn.name + fn.otchestvo)) AS rn
    FROM (
        SELECT * FROM male_full_names
        UNION ALL
        SELECT * FROM female_full_names
    ) fn
)
INSERT INTO manager (surname, name, otchestvo, adress, mail, telephone)
SELECT TOP (@manager_count)
    fn.surname,
    fn.name,
    fn.otchestvo,
    CONCAT(
        a.adress, N', д. ', (seed.addr_seed % 220) + 1,
        N', корп. ', (seed.addr_seed % 9) + 1,
        N', кв. ', (seed.addr_seed % 300) + 1
    ),
    CONCAT(t.tag, N'.', fn.rn, N'.', (seed.addr_seed % 97) + 2, N'@', d.domain),
    7800000000 + ((fn.rn * 3571) % 1000000000)
FROM full_names fn
CROSS APPLY (SELECT TOP 1 * FROM mail_domains ORDER BY CHECKSUM(NEWID())) d
CROSS APPLY (SELECT TOP 1 * FROM mail_tags ORDER BY CHECKSUM(NEWID())) t
CROSS APPLY (
    SELECT ABS(CHECKSUM(fn.surname + fn.name + fn.otchestvo + CAST(fn.rn AS NVARCHAR(10)))) AS addr_seed
) seed
CROSS APPLY (
    SELECT ai.adress
    FROM addr_indexed ai
    WHERE ai.rn = (seed.addr_seed % ai.addr_count) + 1
) a
ORDER BY fn.rn;

IF NOT EXISTS (SELECT 1 FROM health_profile)
BEGIN
    RAISERROR('health_profile is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;
IF NOT EXISTS (SELECT 1 FROM administrator)
BEGIN
    RAISERROR('administrator is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#health_profiles') IS NOT NULL DROP TABLE #health_profiles;
IF OBJECT_ID('tempdb..#administrators') IS NOT NULL DROP TABLE #administrators;

SELECT ROW_NUMBER() OVER (ORDER BY id_health_profile) AS rn, id_health_profile
INTO #health_profiles
FROM health_profile;

SELECT ROW_NUMBER() OVER (ORDER BY id_administrator) AS rn, id_administrator
INTO #administrators
FROM administrator;

DECLARE @admin_rows INT = (SELECT COUNT(*) FROM #administrators);
DECLARE @health_rows INT = (SELECT COUNT(*) FROM #health_profiles);
DECLARE @type_rows INT;
DECLARE @pansionat_rows INT;

;WITH n AS (
    SELECT TOP (@pansionat_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
base_names AS (
    SELECT
        base_name,
        ROW_NUMBER() OVER (ORDER BY base_name) AS rn,
        COUNT(*) OVER () AS base_count
    FROM (VALUES
        (N'Солнечный'),
        (N'Горный'),
        (N'Зеленый'),
        (N'Лазурный'),
        (N'Морской'),
        (N'Тихий'),
        (N'Родной'),
        (N'Алый'),
        (N'Лесной'),
        (N'Северный'),
        (N'Южный'),
        (N'Прибрежный'),
        (N'Сосновый'),
        (N'Речной'),
        (N'Озерный'),
        (N'Долинный'),
        (N'Холмистый'),
        (N'Полевой'),
        (N'Луговой'),
        (N'Кедровый'),
        (N'Террасный'),
        (N'Ключевой'),
        (N'Береговой'),
        (N'Сияющий'),
        (N'Янтарный'),
        (N'Шелковый'),
        (N'Утренний'),
        (N'Вечерний'),
        (N'Серебряный'),
        (N'Звездный'),
        (N'Каменный'),
        (N'Песчаный'),
        (N'Теплый'),
        (N'Морозный'),
        (N'Глубокий'),
        (N'Высокий'),
        (N'Туманный'),
        (N'Ветреный'),
        (N'Голубой'),
        (N'Медовый')
    ) v(base_name)
),
places AS (
    SELECT
        place_name,
        ROW_NUMBER() OVER (ORDER BY place_name) AS rn,
        COUNT(*) OVER () AS place_count
    FROM (VALUES
        (N'берег'),
        (N'воздух'),
        (N'роща'),
        (N'залив'),
        (N'бриз'),
        (N'гавань'),
        (N'просторы'),
        (N'паруса'),
        (N'озеро'),
        (N'поляна'),
        (N'холмы'),
        (N'исток'),
        (N'долина'),
        (N'ключи'),
        (N'терраса'),
        (N'склон'),
        (N'дюна'),
        (N'сады'),
        (N'луга'),
        (N'каскад'),
        (N'лес'),
        (N'камень'),
        (N'река'),
        (N'родник'),
        (N'сосны'),
        (N'утес'),
        (N'прибой'),
        (N'луч'),
        (N'перевал'),
        (N'гряда'),
        (N'кедры'),
        (N'остров'),
        (N'мыс'),
        (N'терем'),
        (N'сквер'),
        (N'ключ'),
        (N'порог'),
        (N'сафьяны'),
        (N'травы'),
        (N'яблони'),
        (N'березы'),
        (N'ели'),
        (N'дубы'),
        (N'ивы'),
        (N'ручей'),
        (N'берегиня'),
        (N'луговина'),
        (N'территория'),
        (N'палисад'),
        (N'сосенка'),
        (N'грань'),
        (N'стежка'),
        (N'путь'),
        (N'край'),
        (N'квартал'),
        (N'простор'),
        (N'аллея'),
        (N'поля'),
        (N'предел')
    ) v(place_name)
),
pansionat_capacity AS (
    SELECT
        MIN(base_count) AS base_count,
        MIN(place_count) AS place_count
    FROM base_names
    CROSS JOIN places
)
INSERT INTO pansionat (name, photo, buiding_year, administrator, health_profile)
SELECT
    CONCAT(b.base_name, N' ', p.place_name),
    NULL,
    1980 + (n % 40),
    a.id_administrator,
    h.id_health_profile
FROM n
CROSS JOIN pansionat_capacity c
CROSS APPLY (
    SELECT base_name
    FROM base_names
    WHERE rn = ((n - 1) % c.base_count) + 1
) b
CROSS APPLY (
    SELECT place_name
    FROM places
    WHERE rn = (((n - 1) / c.base_count) % c.place_count) + 1
) p
JOIN #administrators a ON a.rn = ((n - 1) % @admin_rows) + 1
JOIN #health_profiles h ON h.rn = ((n - 1) % @health_rows) + 1;

IF OBJECT_ID('tempdb..#room_types') IS NOT NULL DROP TABLE #room_types;
IF OBJECT_ID('tempdb..#pansionats') IS NOT NULL DROP TABLE #pansionats;

SELECT ROW_NUMBER() OVER (ORDER BY id_type) AS rn, id_type
INTO #room_types
FROM room_type;

SELECT ROW_NUMBER() OVER (ORDER BY id_pansionat) AS rn, id_pansionat
INTO #pansionats
FROM pansionat;

SET @type_rows = (SELECT COUNT(*) FROM #room_types);
SET @pansionat_rows = (SELECT COUNT(*) FROM #pansionats);

;WITH n AS (
    SELECT TOP (@service_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
service_base AS (
    SELECT
        base_name,
        CASE
            WHEN LEN(base_name) > 12 THEN LEFT(base_name, 12)
            ELSE base_name
        END AS base_short,
        base_price,
        ROW_NUMBER() OVER (ORDER BY base_name) AS rn,
        COUNT(*) OVER () AS base_count
    FROM (VALUES
        (N'Массаж', 1000),
        (N'Сауна', 800),
        (N'СПА', 1500),
        (N'Грязелеч', 1200),
        (N'Ингаляции', 600),
        (N'ЛФК', 700),
        (N'Физиотерап', 900),
        (N'Косметология', 1100),
        (N'Соляная', 650),
        (N'Бассейн', 500),
        (N'Йога', 600),
        (N'Пилатес', 650),
        (N'Гидромасс', 900),
        (N'Ароматерап', 700),
        (N'Фитобар', 300),
        (N'Аква', 550),
        (N'Диета', 800),
        (N'Психолог', 950),
        (N'Дыхание', 650),
        (N'Релакс', 700),
        (N'Лазер', 1100),
        (N'Магнит', 900),
        (N'УЗТ', 850),
        (N'Кедр', 1000),
        (N'Сон', 600),
        (N'Термальная', 1400),
        (N'Минеральн', 1200),
        (N'Травяная', 700),
        (N'Холод', 900),
        (N'Тепло', 900),
        (N'Тренажер', 800),
        (N'Скандинав', 750),
        (N'Норд', 700),
        (N'Спина', 900),
        (N'Шея', 800),
        (N'Ноги', 800),
        (N'Лицо', 900),
        (N'Тело', 1000),
        (N'Иммунитет', 950),
        (N'Здоровье', 850)
    ) v(base_name, base_price)
),
service_variant AS (
    SELECT
        variant_name,
        CASE
            WHEN LEN(variant_name) > 12 THEN LEFT(variant_name, 12)
            ELSE variant_name
        END AS variant_short,
        ROW_NUMBER() OVER (ORDER BY variant_name) AS rn,
        COUNT(*) OVER () AS variant_count
    FROM (VALUES
        (N'классик'),
        (N'релакс'),
        (N'лимфо'),
        (N'точка'),
        (N'спорт'),
        (N'детокс'),
        (N'антистресс'),
        (N'лазер'),
        (N'ультра'),
        (N'магнит'),
        (N'солевой'),
        (N'травы'),
        (N'минеральн'),
        (N'скраб'),
        (N'маска'),
        (N'пилинг'),
        (N'индивид'),
        (N'группа'),
        (N'утро'),
        (N'вечер'),
        (N'сеанс'),
        (N'курс'),
        (N'уход'),
        (N'практика'),
        (N'баланс'),
        (N'восстановл'),
        (N'мягкий'),
        (N'интенсив'),
        (N'комфорт'),
        (N'здоровье'),
        (N'тонус'),
        (N'энергия'),
        (N'профи'),
        (N'эконом'),
        (N'премиум'),
        (N'стандарт'),
        (N'пакет'),
        (N'плюс'),
        (N'лайт'),
        (N'макс'),
        (N'актив'),
        (N'заряд'),
        (N'вода'),
        (N'ветер'),
        (N'тепло'),
        (N'холод'),
        (N'сила'),
        (N'мир'),
        (N'волна'),
        (N'ритм'),
        (N'пар'),
        (N'дым'),
        (N'лес'),
        (N'дом'),
        (N'свежий'),
        (N'бодрый'),
        (N'спокойн'),
        (N'нежный'),
        (N'глубокий'),
        (N'легкий'),
        (N'сильный'),
        (N'быстрый'),
        (N'медленный'),
        (N'ровный'),
        (N'плавный'),
        (N'чистый'),
        (N'яркий'),
        (N'ясный'),
        (N'теплый'),
        (N'холодный'),
        (N'лето'),
        (N'зима'),
        (N'весна'),
        (N'осень'),
        (N'утренний'),
        (N'дневной'),
        (N'вечерний'),
        (N'ночной'),
        (N'курорт'),
        (N'озеро'),
        (N'море'),
        (N'река'),
        (N'гора'),
        (N'поле'),
        (N'сад'),
        (N'сосна'),
        (N'кедр'),
        (N'липа'),
        (N'ромашка'),
        (N'лаванда'),
        (N'шалфей'),
        (N'чабрец'),
        (N'мята'),
        (N'мед'),
        (N'соль'),
        (N'бриз'),
        (N'прилив'),
        (N'отлив'),
        (N'пульс'),
        (N'дыхание'),
        (N'вдох'),
        (N'выдох'),
        (N'шаг'),
        (N'старт'),
        (N'финиш'),
        (N'центр'),
        (N'край'),
        (N'путь'),
        (N'мост'),
        (N'ключ'),
        (N'исток'),
        (N'долина'),
        (N'склон'),
        (N'тропа'),
        (N'аллея'),
        (N'квартал'),
        (N'простор'),
        (N'импульс'),
        (N'контур'),
        (N'поток'),
        (N'ресурс'),
        (N'свет'),
        (N'тень'),
        (N'цвет'),
        (N'звук'),
        (N'вкус'),
        (N'форма'),
        (N'сфера'),
        (N'канал'),
        (N'модуль'),
        (N'пласт'),
        (N'линия'),
        (N'круг'),
        (N'спектр'),
        (N'гармония'),
        (N'тишина'),
        (N'свобода'),
        (N'настрой'),
        (N'покой'),
        (N'радость'),
        (N'фокус'),
        (N'пауза'),
        (N'ритуал'),
        (N'стихия'),
        (N'солнце'),
        (N'ледник'),
        (N'силавет')
    ) v(variant_name)
),
service_capacity AS (
    SELECT
        MIN(base_count) AS base_count,
        MIN(variant_count) AS variant_count
    FROM service_base
    CROSS JOIN service_variant
)
INSERT INTO service (name, price, time)
SELECT
    CONCAT(b.base_short, N' ', v.variant_short),
    b.base_price + (n.n % 500),
    CONCAT(20 + (n.n % 91), N' мин')
FROM n
CROSS JOIN service_capacity c
CROSS APPLY (
    SELECT base_name, base_short, base_price
    FROM service_base
    WHERE rn = ((n.n - 1) % c.base_count) + 1
) b
CROSS APPLY (
    SELECT variant_name, variant_short
    FROM service_variant
    WHERE rn = (((n.n - 1) / c.base_count) % c.variant_count) + 1
) v;

IF NOT EXISTS (SELECT 1 FROM status_room)
BEGIN
    RAISERROR('status_room is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;
IF NOT EXISTS (SELECT 1 FROM manager)
BEGIN
    RAISERROR('manager is empty after insert. Check permissions or schema.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#status_rooms') IS NOT NULL DROP TABLE #status_rooms;
IF OBJECT_ID('tempdb..#managers') IS NOT NULL DROP TABLE #managers;
IF OBJECT_ID('tempdb..#rooms') IS NOT NULL DROP TABLE #rooms;
IF OBJECT_ID('tempdb..#residents') IS NOT NULL DROP TABLE #residents;
IF OBJECT_ID('tempdb..#status_contracts') IS NOT NULL DROP TABLE #status_contracts;

SELECT ROW_NUMBER() OVER (ORDER BY id_status_room) AS rn, id_status_room
INTO #status_rooms
FROM status_room;

SELECT ROW_NUMBER() OVER (ORDER BY id_manager) AS rn, id_manager
INTO #managers
FROM manager;

SELECT ROW_NUMBER() OVER (ORDER BY id_status_of_contract) AS rn, id_status_of_contract
INTO #status_contracts
FROM status_of_contract;

DECLARE @status_rows INT = (SELECT COUNT(*) FROM #status_rooms);
DECLARE @manager_rows INT = (SELECT COUNT(*) FROM #managers);
DECLARE @status_contract_rows INT = (SELECT COUNT(*) FROM #status_contracts);

;WITH n AS (
    SELECT TOP (@room_count) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO room (price, pansionat, type, status_room)
SELECT
    1500 + (n % 6000),
    p.id_pansionat,
    t.id_type,
    s.id_status_room
FROM n
JOIN #pansionats p ON p.rn = ((n - 1) % @pansionat_rows) + 1
JOIN #room_types t ON t.rn = ((n - 1) % @type_rows) + 1
JOIN #status_rooms s ON s.rn = ((n - 1) % @status_rows) + 1;

;WITH male_surnames AS (
    SELECT surname FROM (VALUES
        (N'Смирнов'), (N'Кузнецов'), (N'Попов'), (N'Васильев'), (N'Федоров'),
        (N'Новиков'), (N'Морозов'), (N'Волков'), (N'Алексеев'), (N'Лебедев'),
        (N'Гордеев'), (N'Мартынов'), (N'Ефимов'), (N'Ильин'), (N'Ларионов'),
        (N'Кузьмин'), (N'Соловьев'), (N'Чернов'), (N'Беляев'), (N'Гришин'),
        (N'Демидов'), (N'Капустин'), (N'Семенов'), (N'Филиппов'), (N'Тимофеев'),
        (N'Захаров'), (N'Журавлев'), (N'Комаров'), (N'Фокин'), (N'Котов')
    ) v(surname)
),
female_surnames AS (
    SELECT surname FROM (VALUES
        (N'Смирнова'), (N'Кузнецова'), (N'Попова'), (N'Васильева'), (N'Федорова'),
        (N'Новикова'), (N'Морозова'), (N'Волкова'), (N'Алексеева'), (N'Лебедева'),
        (N'Гордеева'), (N'Мартынова'), (N'Ефимова'), (N'Ильина'), (N'Ларионова'),
        (N'Кузьмина'), (N'Соловьева'), (N'Чернова'), (N'Беляева'), (N'Гришина'),
        (N'Демидова'), (N'Капустина'), (N'Семенова'), (N'Филиппова'), (N'Тимофеева'),
        (N'Захарова'), (N'Журавлева'), (N'Комарова'), (N'Фокина'), (N'Котова')
    ) v(surname)
),
male_names AS (
    SELECT name FROM (VALUES
        (N'Илья'), (N'Антон'), (N'Кирилл'), (N'Станислав'), (N'Руслан'),
        (N'Глеб'), (N'Максим'), (N'Егор'), (N'Данил'), (N'Александр'),
        (N'Герман'), (N'Матвей'), (N'Артем'), (N'Игорь'), (N'Павел'),
        (N'Сергей'), (N'Владимир'), (N'Дмитрий'), (N'Николай'), (N'Роман'),
        (N'Арсений'), (N'Виктор'), (N'Константин'), (N'Тимофей'), (N'Григорий')
    ) v(name)
),
female_names AS (
    SELECT name FROM (VALUES
        (N'Елена'), (N'Марина'), (N'Полина'), (N'Алёна'), (N'Юлия'),
        (N'Диана'), (N'Арина'), (N'Тамара'), (N'София'), (N'Вероника'),
        (N'Кристина'), (N'Елизавета'), (N'Наталья'), (N'Ольга'), (N'Людмила'),
        (N'Анна'), (N'Дарья'), (N'Ирина'), (N'Татьяна'), (N'Светлана'),
        (N'Ксения'), (N'Анастасия'), (N'Екатерина'), (N'Виктория'), (N'Александра')
    ) v(name)
),
male_otch AS (
    SELECT otchestvo FROM (VALUES
        (N'Алексеевич'), (N'Дмитриевич'), (N'Николаевич'), (N'Петрович'), (N'Михайлович'),
        (N'Владимирович'), (N'Олегович'), (N'Игоревич'), (N'Семенович'), (N'Романович'),
        (N'Егорович'), (N'Иванович'), (N'Станиславович'), (N'Денисович'), (N'Геннадьевич'),
        (N'Сергеевич'), (N'Андреевич'), (N'Викторович'), (N'Георгиевич'), (N'Павлович'),
        (N'Арсеньевич'), (N'Глебович'), (N'Тимофеевич'), (N'Константинович'), (N'Юрьевич')
    ) v(otchestvo)
),
female_otch AS (
    SELECT otchestvo FROM (VALUES
        (N'Алексеевна'), (N'Викторовна'), (N'Сергеевна'), (N'Дмитриевна'), (N'Николаевна'),
        (N'Игоревна'), (N'Олеговна'), (N'Андреевна'), (N'Михайловна'), (N'Владимировна'),
        (N'Павловна'), (N'Анатольевна'), (N'Никитична'), (N'Юрьевна'), (N'Петровна'),
        (N'Романовна'), (N'Георгиевна'), (N'Егоровна'), (N'Ивановна'), (N'Тимофеевна'),
        (N'Константиновна'), (N'Геннадьевна'), (N'Станиславовна'), (N'Денисовна'), (N'Ильинична')
    ) v(otchestvo)
),
full_names AS (
    SELECT
        fn.surname,
        fn.name,
        fn.otchestvo,
        ROW_NUMBER() OVER (ORDER BY CHECKSUM(fn.surname + fn.name + fn.otchestvo)) AS rn
    FROM (
        SELECT s.surname, n.name, o.otchestvo
        FROM male_surnames s
        CROSS JOIN male_names n
        CROSS JOIN male_otch o
        UNION ALL
        SELECT s.surname, n.name, o.otchestvo
        FROM female_surnames s
        CROSS JOIN female_names n
        CROSS JOIN female_otch o
    ) fn
)
INSERT INTO resident (surname, name, otchestvo, mail, telephone, passport, manager)
SELECT TOP (@resident_count)
    fn.surname,
    fn.name,
    fn.otchestvo,
    CONCAT(N'user.', fn.rn, N'.', (seed.seed_value % 97) + 2, N'@', d.domain),
    7500000000 + ((fn.rn * 1543) % 1000000000),
    4000000000 + ((fn.rn * 7919) % 500000000),
    m.id_manager
FROM full_names fn
    CROSS APPLY (
        SELECT ABS(CHECKSUM(fn.surname + fn.name + fn.otchestvo + CAST(fn.rn AS NVARCHAR(10)))) AS seed_value
    ) seed
    CROSS APPLY (
        SELECT TOP 1 domain FROM (VALUES
            (N'example.com'),
            (N'mail.ru'),
            (N'inbox.ru'),
            (N'yandex.ru'),
            (N'gmail.com'),
            (N'outlook.com'),
            (N'proton.me')
        ) v(domain)
        ORDER BY CHECKSUM(NEWID())
    ) d
JOIN #managers m ON m.rn = ((fn.rn - 1) % @manager_rows) + 1
ORDER BY fn.rn;

SELECT ROW_NUMBER() OVER (ORDER BY id_room) AS rn, id_room
INTO #rooms
FROM room;

SELECT ROW_NUMBER() OVER (ORDER BY id_resident) AS rn, id_resident
INTO #residents
FROM resident;

DECLARE @room_rows INT = (SELECT COUNT(*) FROM #rooms);
DECLARE @resident_rows INT = (SELECT COUNT(*) FROM #residents);
DECLARE @contract_limit INT;

SELECT @contract_limit = MIN(val)
FROM (VALUES (@contract_count), (@room_rows), (@resident_rows)) v(val);

;WITH n AS (
    SELECT TOP (@contract_limit) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO contract (
    start_date,
    final_date,
    summa,
    manager,
    room,
    resident,
    status_of_contract
)
SELECT
    DATEADD(DAY, n % 365, '2023-01-01'),
    DATEADD(DAY, 3 + (n % 28), DATEADD(DAY, n % 365, '2023-01-01')),
    10000 + (n % 40000),
    m.id_manager,
    r.id_room,
    res.id_resident,
    s.id_status_of_contract
FROM n
JOIN #rooms r ON r.rn = n
JOIN #residents res ON res.rn = n
JOIN #managers m ON m.rn = ((n - 1) % @manager_rows) + 1
JOIN #status_contracts s ON s.rn = ((n - 1) % @status_contract_rows) + 1;

;WITH pairs AS (
    SELECT TOP (@vladenie_count)
        a.id_administrator AS administrator,
        p.id_pansionat AS pansionat
    FROM administrator a
    CROSS JOIN pansionat p
    ORDER BY a.id_administrator, p.id_pansionat
)
INSERT INTO vladenie (administrator, pansionat)
SELECT administrator, pansionat
FROM pairs;

;WITH pairs AS (
    SELECT TOP (@provision_count)
        s.id_service AS service,
        p.id_pansionat AS pansionat
    FROM service s
    CROSS JOIN pansionat p
    ORDER BY s.id_service, p.id_pansionat
)
INSERT INTO provision_of_services (service, pansionat)
SELECT service, pansionat
FROM pairs;

;WITH pairs AS (
    SELECT TOP (@using_count)
        s.id_service AS service,
        r.id_resident AS resident
    FROM service s
    CROSS JOIN resident r
    ORDER BY s.id_service, r.id_resident
)
INSERT INTO using_service (service, resident)
SELECT service, resident
FROM pairs;

