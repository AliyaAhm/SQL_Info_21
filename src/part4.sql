-- creating db and fill it with tables and data
CREATE DATABASE part4;
CREATE SCHEMA IF NOT EXISTS public;

DROP TABLE IF EXISTS TableNamecountries CASCADE;
CREATE TABLE tablenamecountries
(id BIGSERIAL PRIMARY KEY,
country_name VARCHAR NOT NULL);

DROP TABLE IF EXISTS TableNameCities CASCADE;
CREATE TABLE tablenameCities
(id BIGSERIAL PRIMARY KEY,
city_name VARCHAR NOT NULL,
region VARCHAR NOT NULL);

DROP TABLE IF EXISTS people CASCADE;
CREATE TABLE people
(id BIGSERIAL PRIMARY KEY,
name VARCHAR NOT NULL,
bday DATE NOT NULL);

DROP TABLE IF EXISTS companies CASCADE;
CREATE TABLE companies
(id BIGSERIAL PRIMARY KEY,
company_name VARCHAR NOT NULL,
city_name VARCHAR NOT NULL);

DROP TABLE IF EXISTS NTableNameschools CASCADE;
CREATE TABLE ntablenameschools
(id BIGSERIAL PRIMARY KEY,
school_name VARCHAR NOT NULL,
school_city VARCHAR NOT NULL);


INSERT INTO tablenamecountries (country_name)
VALUES	('Russia'),
		('Belorus'),
		('Kazakhstan'),
		('Norway'),
		('Switzerland');

INSERT INTO tablenameCities (city_name, region)
VALUES	('Tobolsk', 'Tyumen'),
		('Brest', 'Brest'),
		('Petropavlovsk', 'Severo-Kazakhstan'),
		('Kirkenes', 'Finnmark'),
		('Losanne', 'Vo');

INSERT INTO people (name, bday)
VALUES	('faglanti fagl', '1988-03-18'),
		('oshelba osh', '1989-04-01'),
		('wbungo wbun', '1990-09-19'),
		('jerlenem jerl', '2002-06-30'),
		('gopal gop', '2003-08-06');

INSERT INTO companies (company_name, city_name)
VALUES	('super company', 'Losanne'),
		('first company', 'Tobolsk'),
		('leader company', 'Kirkenes'),
		('exclusive company', 'Brest'),
		('1 company', 'Petropavlovsk');

INSERT INTO ntablenameschools (school_name, school_city)
VALUES	('first school', 'Losanne'),
		('second school', 'Tobolsk'),
		('third school', 'Kirkenes'),
		('fourth school', 'Brest'),
		('fifth school', 'Petropavlovsk');


-- 1) Создать хранимую процедуру, которая, не уничтожая базу данных, 
-- 	уничтожает все те таблицы текущей базы данных, имена которых 
-- 	начинаются с фразы 'TableName'.

DROP PROCEDURE IF EXISTS delete_tables();

CREATE OR REPLACE PROCEDURE delete_tables(t_name VARCHAR DEFAULT 'tablename')
AS $$
DECLARE
	for_del TEXT;
BEGIN
	FOR for_del IN(
		SELECT table_name FROM information_schema.tables
		WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
			AND table_schema IN('public', 'myschema')
			AND table_name LIKE concat(t_name, '%'))
	LOOP
		EXECUTE 'DROP TABLE IF EXISTS ' || for_del || ' CASCADE';
	END LOOP;
END;
$$ LANGUAGE plpgsql;


--Проверка
--01. deleting the tables calling procedure
-- CALL delete_tables()
-- 02. Check if everything is deleted
-- SELECT table_name FROM information_schema.tables
-- 		WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
-- 			AND table_schema IN('public', 'myschema')
-- 			AND table_name LIKE concat('tablename', '%');


-- 2) Создать хранимую процедуру с выходным параметром, которая выводит 
-- 	список имен и параметров всех скалярных SQL функций пользователя 
-- 	в текущей базе данных. Имена функций без параметров не выводить. 
-- 	Имена и список параметров должны выводиться в одну строку. 
-- 	Выходной параметр возвращает количество найденных функций.

-- 3) Создать хранимую процедуру с выходным параметром, которая уничтожает 
-- 	все SQL DML триггеры в текущей базе данных. Выходной параметр возвращает 
-- 	количество уничтоженных триггеров.

-- 4) Создать хранимую процедуру с входным параметром, которая выводит имена 
-- 	и описания типа объектов (только хранимых процедур и скалярных функций), 
-- 	в тексте которых на языке SQL встречается строка, задаваемая параметром процедуры.





