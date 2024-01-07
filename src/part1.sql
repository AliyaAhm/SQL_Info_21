DROP TABLE IF EXISTS Peers CASCADE;

CREATE TABLE Peers
(Nickname	VARCHAR NOT NULL PRIMARY KEY,
Birthday	DATE NOT NULL);

DROP TABLE IF EXISTS TimeTracking CASCADE;

CREATE TABLE TimeTracking
(ID		BIGINT NOT NULL PRIMARY KEY,
Peer	VARCHAR NOT NULL,
Date	DATE NOT NULL,
Time	TIME NOT NULL,
State	INTEGER NOT NULL CHECK (State IN (1, 2)),
FOREIGN KEY (Peer) REFERENCES Peers(Nickname));

DROP TABLE IF EXISTS Recommendations CASCADE;

CREATE TABLE Recommendations
(ID				BIGINT NOT NULL PRIMARY KEY,
Peer			VARCHAR NOT NULL,
RecommendedPeer	VARCHAR NOT NULL,
FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname));

DROP TABLE IF EXISTS Friends CASCADE;

CREATE TABLE Friends
(ID		BIGINT NOT NULL PRIMARY KEY,
Peer1	VARCHAR NOT NULL,
Peer2	VARCHAR NOT NULL,
FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
FOREIGN KEY (Peer2) REFERENCES Peers(Nickname));

DROP TABLE IF EXISTS TransferredPoints CASCADE;

CREATE TABLE TransferredPoints
(ID				BIGINT NOT NULL PRIMARY KEY,
CheckingPeer	VARCHAR NOT NULL,
CheckedPeer		VARCHAR NOT NULL,
PointsAmount	INTEGER NOT NULL DEFAULT 1,
FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname));

DROP TABLE IF EXISTS Tasks CASCADE;

CREATE TABLE Tasks
(Title		VARCHAR NOT NULL PRIMARY KEY,
ParentTask	VARCHAR,
MaxXP		BIGINT NOT NULL,
FOREIGN KEY (ParentTask) REFERENCES Tasks(Title));

DROP TABLE IF EXISTS Checks CASCADE;

CREATE TABLE Checks
(ID		BIGINT NOT NULL PRIMARY KEY,
Peer	VARCHAR NOT NULL,
Task	VARCHAR NOT NULL,
Date	DATE NOT NULL,
FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
FOREIGN KEY (Task) REFERENCES Tasks(Title));

CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

DROP TABLE IF EXISTS P2P CASCADE;

CREATE TABLE P2P
(ID				BIGINT NOT NULL PRIMARY KEY,
сhecks			BIGINT NOT NULL,
CheckingPeer	VARCHAR NOT NULL,
State 			check_status NOT NULL,
Time			TIME NOT NULL,
FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
FOREIGN KEY (сhecks) REFERENCES Checks(ID));

DROP TABLE IF EXISTS Verter CASCADE;

CREATE TABLE Verter
(ID		BIGINT NOT NULL PRIMARY KEY,
"checks"	BIGINT NOT NULL,
State	check_status NOT NULL,
Time	TIME NOT NULL,
FOREIGN KEY (checks) REFERENCES Checks(ID));

DROP TABLE IF EXISTS XP CASCADE;

CREATE TABLE XP
(
ID			BIGINT NOT NULL PRIMARY KEY,
"checks"		BIGINT NOT NULL,
XPAmount	BIGINT NOT NULL,
FOREIGN KEY (checks) REFERENCES Checks(ID));

--INSERTS INTO TABLES

INSERT INTO Tasks(Title, ParentTask, MaxXP)
VALUES  ('C2_SimpleBashUtils', null, 250),
		('C3_s21_string+', 'C2_SimpleBashUtils', 500),
		('C4_s21_math', 'C3_s21_string+', 300),
		('C5_s21_decimal', 'C4_s21_math', 350),
		('C6_s21_matrix', 'C5_s21_decimal', 200),
		('C7_SmartCalc_v1.0', 'C6_s21_matrix', 500),
		('C8_3DViewer_v1.0', 'C7_SmartCalc_v1.0', 750),
		('CPP1_s21_matrix+', 'C8_3DViewer_v1.0', 300),
		('CPP2_s21_containers', 'CPP1_s21_matrix+', 350),
		('CPP3_SmartCalc_v2.0', 'CPP2_s21_containers', 600),
		('CPP4_3DViewer_v2.0', 'CPP3_SmartCalc_v2.0', 750),
		('CPP5_3DViewer_v2.1', 'CPP4_3DViewer_v2.0', 600),
		('CPP6_3DViewer_v2.2', 'CPP5_3DViewer_v2.1', 800),
		('CPP7_MLP', 'CPP6_3DViewer_v2.2', 700),
		('CPP8_PhotoLab_v1.0', 'CPP7_MLP', 450),
		('CPP9_MonitoringSystem', 'CPP8_PhotoLab_v1.0', 1000),
		('A1_Maze', 'CPP9_MonitoringSystem', 300),
		('A2_SimpleNavigator_v1.0', 'A1_Maze', 400),
		('A3_Parallels', 'A2_SimpleNavigator_v1.0', 300),
		('A4_Crypto', 'A3_Parallels', 350),
		('A5_s21_memory', 'A4_Crypto', 400),
		('A6_Transactions', 'A5_s21_memory', 700),
		('A7_DNA_Analyzer', 'A6_Transactions', 800),
		('A8_Algorithmic_trading', 'A7_DNA_Analyzer', 800);

INSERT INTO Peers (Nickname, Birthday)
VALUES	('faglanti', '1988-03-18'),
		('oshelba', '1989-04-01'),
		('wbungo', '1990-09-19'),
		('lpuddy', '1995-01-01'),
		('gabriela', '1997-07-06'),
		('milkfist', '2000-12-17'),
		('stevenso', '2001-02-28'),
		('azathotp', '2001-05-11'),
		('jerlenem', '2002-06-30'),
		('gopal', '2003-08-06');

INSERT INTO Friends(ID, Peer1, Peer2)
VALUES	(1, 'faglanti', 'oshelba'),
		(2, 'oshelba', 'wbungo'),
		(3, 'lpuddy', 'gopal'),
		(4, 'wbungo', 'stevenso'),
		(5, 'stevenso', 'gopal');

INSERT INTO Recommendations(ID, Peer, RecommendedPeer)
VALUES	(1, 'faglanti', 'jerlenem'),
		(2, 'lpuddy', 'azathotp'),
		(3, 'oshelba', 'milkfist'),
		(4, 'gabriela', 'wbungo'),
		(5, 'gopal', 'stevenso');

INSERT INTO TimeTracking(ID, Peer, Date, Time, State)
VALUES	(1, 'faglanti', '2023-01-01', '08:09:09', 1),
		(2, 'oshelba', '2023-01-01', '08:57:57', 1),
		(3, 'oshelba', '2023-01-01', '09:05:02', 2),
		(4, 'wbungo', '2023-01-01', '09:02:01', 1),
		(5, 'faglanti', '2023-01-01', '10:30:45', 2),
		(6, 'wbungo', '2023-01-01', '19:15:06', 2),
		(7, 'stevenso', '2023-01-01', '19:15:06', 1),
		(8, 'faglanti', '2023-01-01', '09:09:09', 1),
		(9, 'oshelba', '2023-01-01', '08:57:57', 1),
		(10, 'oshelba', '2023-01-01', '09:05:02', 2),
		(11, 'wbungo', '2023-01-01', '09:02:01', 1),
		(12, 'faglanti', '2023-01-01', '10:30:45', 2),
		(13, 'wbungo', '2023-01-01', '19:15:06', 2),
		(14, 'wbungo', '2023-08-01', '17:15:06', 1),
		(15, 'wbungo', '2023-08-01', '19:15:06', 2),
		(16, 'gopal', '2023-08-01', '09:09:09', 1),
		(17, 'oshelba', '2023-04-01', '18:09:09', 1);


INSERT INTO Checks(ID, Peer, Task, Date)
VALUES	(1, 'wbungo', 'CPP5_3DViewer_v2.1', '2023-02-02'),
		(2, 'oshelba', 'A1_Maze', '2023-03-01'),
		(3, 'gopal', 'C8_3DViewer_v1.0', '2023-01-01'),
		(4, 'wbungo', 'C4_s21_math', '2023-02-08'),
		(5, 'stevenso', 'A7_DNA_Analyzer', '2023-03-05'),
		(6, 'wbungo', 'CPP7_MLP', '2023-02-02'),
		(7, 'faglanti', 'CPP7_MLP', '2023-03-18'),
		(8, 'wbungo', 'CPP7_MLP', '2023-09-19'),
		(9, 'oshelba', 'CPP7_MLP', '2023-04-01'),
		(10, 'faglanti', 'CPP5_3DViewer_v2.1', '2023-02-02');

INSERT INTO Verter (ID, checks, State, "time")
VALUES	(1, 1, 'Start', '12:31'),
		(2, 1, 'Success', '12:35'),

		(3, 2, 'Start', '15:00'),
		(4, 2, 'Failure', '15:05'),

		(5, 3, 'Start', '10:00'),
		(6, 3, 'Success', '10:05'),

		(7, 5, 'Start', '11:00'),
		(8, 5, 'Success', '11:05'),

		(9, 6, 'Start', '13:00'),
		(10, 6, 'Success', '13:05'),

		(11, 7, 'Start', '16:00'),
		(12, 7, 'Success', '16:05'),

		(13, 9, 'Start', '19:00'),
		(14, 9, 'Success', '19:05'),

		(15, 10, 'Start', '20:00'),
		(16, 10, 'Success', '21:05');


INSERT INTO P2P (id, сhecks, checkingpeer, state, "time")
VALUES	(1, 1, 'faglanti', 'Start', '12:00'),
		(2, 1, 'faglanti', 'Success', '12:20'),

		(3, 2,  'stevenso', 'Start', '12:00'),
		(4, 2, 'stevenso', 'Success', '13:05'),--не прошел вертер

		(5, 3, 'stevenso', 'Start', '10:00'),
		(6, 3, 'stevenso', 'Success', '10:05'),

		(7, 4, 'faglanti', 'Start', '8:00'),
		(8, 4, 'faglanti', 'Failure', '9:00'),--не прошел

		(9, 5, 'wbungo', 'Start', '12:00'),
		(10, 5, 'wbungo', 'Success', '12:45'),

		(11, 6, 'oshelba', 'Start', '11:00'),
		(12, 6, 'oshelba', 'Success', '13:00'),

		(13, 7, 'oshelba', 'Start', '15:30'),
		(14, 7, 'oshelba', 'Success', '16:00'),

		(15, 8, 'faglanti', 'Start', '17:45'),
		(16, 8, 'faglanti', 'Failure', '18:00'),--не прошел

		(17, 9, 'stevenso', 'Start', '18:00'),
		(18, 9, 'stevenso', 'Success', '18:45'),

		(19, 10, 'stevenso', 'Start', '19:00'),
		(20, 10, 'stevenso', 'Failure', '19:55');

INSERT INTO xp (id, checks, xpamount)
VALUES	(1, 1, 600),
		(2, 3, 750),
		(3, 5, 800),
		(4, 6, 700),
		(5, 7, 700),
		(6, 8, 700),
		(7, 9, 700),
		(8, 10, 600);

INSERT INTO TransferredPoints (ID, CheckingPeer, CheckedPeer, PointsAmount)
VALUES	(1, 'faglanti', 'wbungo', 3),
		(2,'stevenso', 'oshelba', 2),
		(3, 'stevenso', 'gopal', 1),
		(4, 'faglanti', 'wbungo', 1),
		(5, 'wbungo', 'stevenso', 1),
		(6, 'oshelba', 'wbungo', 1),
		(7, 'oshelba', 'faglanti', 1),
		(8, 'stevenso', 'faglanti', 1);


-- PROCEDURES FOR CSV
--DROP PROCEDURE IF EXISTS import() CASCADE;

CREATE OR REPLACE PROCEDURE import(IN table_name VARCHAR, IN path TEXT, IN separator CHAR)
AS $$
	BEGIN
		EXECUTE format('COPY %I FROM %L DELIMITER %L CSV HEADER;', table_name, path, separator);
	END;
$$ LANGUAGE plpgsql;

--DROP PROCEDURE IF EXISTS export() CASCADE;

CREATE OR REPLACE PROCEDURE export_csv(IN table_name VARCHAR, IN path TEXT, IN separator CHAR)
AS $$
	BEGIN
		EXECUTE format('COPY %I TO %L DELIMITER %L CSV HEADER;', table_name, path, separator);
	END;
$$ LANGUAGE plpgsql;



-- --FOR TESTING PROCEDURES FOR CSV
-- CALL export('peers', '/Users/iarovaia/Documents/platforma/sql2/final/pr.csv', ',');
-- CALL export('peers', '/Users/iarovaia/Documents/platforma/sql2/final/for_git/pr.csv', ',');


