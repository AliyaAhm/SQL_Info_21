-- Task 1
-- procedure for adding P2P check

CREATE OR REPLACE PROCEDURE add_p2p(nick VARCHAR, checker VARCHAR, 
			task_name VARCHAR, status_p2p VARCHAR, check_time TIME) 
AS $$
DECLARE id_checks BIGINT;
BEGIN
	IF status_p2p = 'Start' AND THEN
		id_checks = (SELECT MAX(ID) FROM Checks) + 1;
		INSERT INTO checks(id, peer, task, "date") VALUES(id_checks, nick, task_name, (SELECT current_date)); 
		id_checks = (SELECT MAX(ID) FROM Checks);
	ELSE
		id_checks = (SELECT MAX(checks.id) FROM P2P JOIN checks ON checks.id = p2p.сhecks 
			WHERE checkingpeer = checker AND peer = nick AND task = task_name);
	END IF;
	IF (id_checks IS NOT NULL) THEN
		INSERT INTO P2P VALUES((SELECT MAX(ID) + 1 FROM P2P)::BIGINT, id_checks, checker, status_p2p::check_status, check_time);
	END IF;
END;
$$ LANGUAGE plpgsql;

-- -- TEST CASES
SELECT * FROM P2P;
-- -- FAIL
CALL add_p2p('stevenso', 'faglanti', 'CPP5_3DViewer_v2.1', 'Start', '12:12');
CALL add_p2p('stevenso', 'faglanti', 'CPP9_MonitoringSystem', 'Success', '12:20');
SELECT * FROM P2P;
-- -- SUCCESS
CALL add_p2p('stevenso', 'faglanti', 'CPP7_MLP', 'Start', '12:55');
CALL add_p2p('stevenso', 'faglanti', 'CPP7_MLP', 'Success', '13:00');
CALL add_p2p('stevenso', 'faglanti', 'CPP8_PhotoLab_v1.0', 'Start', '14:55');
CALL add_p2p('stevenso', 'faglanti', 'CPP8_PhotoLab_v1.0', 'Failure', '15:00');
SELECT * FROM P2P;


-- TASK 2
-- procedure for adding Verter's check

DROP PROCEDURE IF EXISTS add_verter(nick VARCHAR, task_name VARCHAR,
			status_verter VARCHAR, check_time TIME);

CREATE OR REPLACE PROCEDURE add_verter(nick VARCHAR, task_name VARCHAR,
			status_verter VARCHAR, check_time TIME)
AS $$
DECLARE id_checks BIGINT;
BEGIN
	id_checks = (SELECT p2p.сhecks FROM p2p
			JOIN checks ON p2p.сhecks = checks.id 
			WHERE p2p.state = 'Success' 
			AND checks.peer = nick AND checks.task = task_name
			ORDER BY checks.date DESC, p2p.time DESC, p2p.сhecks DESC LIMIT 1)::BIGINT;
	IF (id_checks IS NOT NULL) THEN
			INSERT INTO verter VALUES((SELECT MAX(id) + 1 FROM verter)::BIGINT, id_checks,
					status_verter::check_status, check_time);
	END IF;
END;
$$ LANGUAGE plpgsql;

-- -- TEST CASES
SELECT * FROM Verter;
-- -- FAIL
CALL add_verter('oshelba', 'CPP7_MLP1', 'Start', '15:12');
SELECT * FROM Verter;
-- -- SUCCESS
call add_verter('stevenso', 'CPP7_MLP', 'Start', '17:12');
call add_verter('stevenso', 'CPP7_MLP', 'Success', '18:12');
SELECT * FROM Verter;


-- TASK 3
-- CREATE TRIGGER: WHEN STARTING P2P CHECK, CHANGE TransferredPoints

DROP FUNCTION IF EXISTS fnc_trg_add_points_transfer() CASCADE;

CREATE OR REPLACE FUNCTION fnc_trg_add_points_transfer() 
RETURNS trigger 
AS $trg_add_points_transfer$
DECLARE
	checked VARCHAR;
	points INT;
	id_t BIGINT;
	BEGIN
		IF (new.state = 'Start') THEN 
			checked = (SELECT peer FROM checks WHERE checks.id = new.сhecks);
			points = (SELECT pointsamount FROM transferredpoints WHERE checkingpeer = new.checkingpeer AND checkedpeer = checked);
			id_t = ((SELECT MAX(id) FROM transferredpoints) + 1);
			IF points IS NULL THEN
				INSERT INTO TransferredPoints(ID, checkingpeer, checkedpeer, pointsamount)
				VALUES(id_t, new.checkingpeer, checked, 1);
			ELSE
				UPDATE transferredpoints 
				SET pointsamount = points + 1
				WHERE checkingpeer = new.checkingpeer
				AND checkedpeer = checked;
			END IF;
		END IF;
		RETURN NULL;
	END;
$trg_add_points_transfer$ 
LANGUAGE plpgsql;

-- DROP TRIGGER IF EXISTS trg_add_points_transfer ON p2p;
CREATE OR REPLACE TRIGGER trg_add_points_transfer
AFTER INSERT ON P2P FOR EACH ROW
EXECUTE PROCEDURE fnc_trg_add_points_transfer();


-- -- TEST CASES
SELECT PointsAmount FROM TransferredPoints WHERE CheckingPeer = 'faglanti' AND CheckedPeer = 'oshelba';
CALL add_p2p('oshelba', 'faglanti', 'CPP1_s21_matrix+', 'Start', '15:12');
CALL add_p2p('oshelba', 'faglanti', 'CPP1_s21_matrix+',  'Success', '15:12');
SELECT PointsAmount FROM TransferredPoints WHERE CheckingPeer = 'faglanti' AND CheckedPeer = 'oshelba';


-- TASK 4
-- CREATE TRIGGER: CHECK XP AMOUNT BEFORE ADDIND DATA TO TABLE XP

CREATE OR REPLACE FUNCTION fnc_trg_xp_check()
RETURNS TRIGGER AS $trg_xp_check$
	BEGIN
		IF (NEW.XPAmount > (SELECT MaxXP FROM Tasks JOIN Checks ON Tasks.Title = Checks.Task WHERE NEW.checks = Checks.ID))
			THEN RAISE EXCEPTION 'Error: XP is more MAX';
		ELSEIF ((SELECT State FROM P2P WHERE P2P.сhecks = NEW.checks ORDER BY Time DESC LIMIT 1) != 'Success')
			THEN RAISE EXCEPTION 'Error: P2P check is not finished successfully';
		ELSEIF ((SELECT State FROM Verter WHERE Verter.checks = NEW.checks ORDER BY Time DESC LIMIT 1) != 'Success')
			THEN RAISE EXCEPTION 'Error: Verter check is not finished successfully';
		END IF;
	RETURN (new);
	END;
$trg_xp_check$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_xp_check
BEFORE INSERT ON XP FOR EACH ROW
EXECUTE PROCEDURE fnc_trg_xp_check();

-- -- TEST CASES
-- -- FAIL
INSERT INTO XP(id, checks, XPAmount)
VALUES(9, 3, 1000);
INSERT INTO XP(id, checks, XPAmount)
VALUES(10, 2, 100);
INSERT INTO XP(id, checks, XPAmount)
VALUES(11, 4, 100);
--SUCCESS
INSERT INTO XP(id, checks, XPAmount)
 VALUES(9, 3, 100);
