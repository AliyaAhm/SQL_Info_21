--1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир поинтов. \
--Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.

DROP FUNCTION IF EXISTS fnc_TransferPoint();
CREATE OR REPLACE FUNCTION fnc_TransferPoint() 
RETURNS TABLE (Peer1 VARCHAR, Peer2 VARCHAR, pointsamount INTEGER)
AS $$
BEGIN
	RETURN query EXECUTE
'WITH tmp_table AS 
(SELECT t.CheckingPeer, t.CheckedPeer, t.PointsAmount 
	FROM TransferredPoints t
		LEFT JOIN TransferredPoints t2 ON t.CheckingPeer = t2.CheckedPeer AND t.CheckedPeer = t2.CheckingPeer
		WHERE t2.ID IS NULL
UNION ALL
SELECT t.CheckingPeer, t.CheckedPeer, t.PointsAmount - t2.PointsAmount as PointsAmount 
FROM TransferredPoints t 
	LEFT JOIN TransferredPoints t2 ON t.CheckingPeer = t2.CheckedPeer 
		AND t.CheckedPeer = t2.CheckingPeer
		WHERE t2.CheckingPeer IS NOT NULL
			AND t.ID > t2.ID)
SELECT CheckingPeer AS Peer1, CheckedPeer AS Peer2, SUM(PointsAmount)::INTEGER AS PointsAmount
	FROM tmp_table
GROUP BY CheckingPeer, CheckedPeer';
END;
$$ LANGUAGE plpgsql;

select * from fnc_TransferPoint();

--2)Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
--В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks). \
--Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.

DROP FUNCTION IF EXISTS fnc_SuccessTask();
CREATE OR REPLACE FUNCTION fnc_SuccessTask()
RETURNS TABLE (Peer VARCHAR, task VARCHAR, xp BIGINT)
AS $$
BEGIN
	RETURN query
	SELECT Checks.Peer, Checks.Task, XP.XPAmount AS xp
		FROM XP
		JOIN Checks ON XP.checks = Checks.ID
		JOIN Verter ON Checks.ID = Verter.checks
		WHERE Verter.State = 'Success';
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fnc_successTask(); 

--3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
DROP FUNCTION IF EXISTS fnc_peer_in_campus(in in_date date);
CREATE OR REPLACE FUNCTION fnc_peer_in_campus(in in_date date)
RETURNS TABLE (name VARCHAR)
AS $$
BEGIN
	RETURN query 
	(SELECT peer FROM TimeTracking
			where "date" = in_date
				GROUP BY Peer
					HAVING SUM(State) = 1);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fnc_peer_in_campus('2023-01-01');


--4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
--Результат вывести отсортированным по изменению числа поинтов. \
--Формат вывода: ник пира, изменение в количество пир поинтов

DROP PROCEDURE IF EXISTS pointschang;  
CREATE OR REPLACE PROCEDURE pointschang(result_data refcursor)
AS $$ 
	BEGIN OPEN result_data FOR
		SELECT tp.CheckingPeer AS Peer, SUM(sum) AS PointsChange FROM
			(SELECT TransferredPoints.CheckingPeer, SUM(TransferredPoints.PointsAmount)
				AS sum
					FROM TransferredPoints
					GROUP BY TransferredPoints.CheckingPeer
					UNION
					SELECT TransferredPoints.CheckedPeer, SUM(-1 * TransferredPoints.PointsAmount)
					FROM TransferredPoints
					GROUP BY TransferredPoints.CheckedPeer) tp
		GROUP BY tp.CheckingPeer
		ORDER BY PointsChange DESC;
END;
$$ LANGUAGE plpgsql;

CALL pointschang('data');
FETCH ALL FROM "data";
CLOSE "data";


-- 5) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой [первой функцией из Part 3](#1-написать-функцию-возвращающую-таблицу-transferredpoints-в-более-человекочитаемом-виде)
-- Результат вывести отсортированным по изменению числа поинтов. \
--Формат вывода: ник пира, изменение в количество пир поинтов

DROP PROCEDURE IF exists  pointschang_from_1;

CREATE OR REPLACE PROCEDURE pointschang_from_1(result_data refcursor)
AS $$
	BEGIN OPEN result_data FOR
		SELECT peer1 AS Peer, SUM(pointsamount) AS PointsChange
			FROM ((SELECT peer1, SUM(pointsamount) AS pointsamount 
				FROM fnc_transferpoint() 
				GROUP BY peer1)
				UNION
				(SELECT peer2,
				SUM(-1 * pointsamount) as pointsamount
				FROM fnc_transferpoint() 
				GROUP BY peer2)) tp
		GROUP BY peer1
		ORDER BY PointsChange desc; -- была ошибка исправила
END;
$$ LANGUAGE plpgsql;

CALL pointschang_from_1('data');
FETCH ALL FROM "data";
CLOSE "data";

--##### 6) Определить самое часто проверяемое задание за каждый день
--При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все. \
--Формат вывода: день, название задания

--Пример вывода:
--| Day        | Task |
--|------------|------|
--| 12.05.2022 | A1   |
--| 17.04.2022 | CPP3 |
--| 23.12.2021 | C5   |

DROP PROCEDURE IF EXISTS most_checked;

CREATE OR REPLACE PROCEDURE most_checked(result_data refcursor)
AS $$
	BEGIN OPEN result_data for
WITH tmp_table AS
	(SELECT Date, Checks.Task, COUNT(Task) AS counts 
			FROM Checks 
				GROUP BY Checks.Task, Date)
	SELECT Date AS day, tmp_table2.Task
		FROM (SELECT tmp_table.Task, tmp_table.Date, RANK() OVER 
			(PARTITION BY tmp_table.Date ORDER BY counts DESC) AS rank FROM tmp_table)
				AS tmp_table2
	WHERE rank = 1
		ORDER BY day;
END;
$$ LANGUAGE plpgsql;

CALL most_checked('data');
FETCH ALL FROM "data";
CLOSE "data";

--7) Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
--Параметры процедуры: название блока, например "CPP". 
--Результат вывести отсортированным по дате завершения. 
--Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)

DROP PROCEDURE IF EXISTS finish_block;

CREATE OR REPLACE PROCEDURE finish_block(result_data refcursor, name_block VARCHAR) 
AS $$
	BEGIN OPEN result_data FOR

WITH block_1 AS (SELECT * FROM Tasks
					WHERE Tasks.Title SIMILAR TO CONCAT(name_block, '[0-9]_%')),				
	block_2 AS (SELECT MAX(Title) AS title
					FROM block_1),
	block_3 AS (SELECT Checks.Peer, Checks.Task, checks."date" FROM Checks
		INNER JOIN
		P2P ON checks.id = p2p.сhecks 
			WHERE p2p.state = 'Success'
				GROUP BY Checks.ID)
				
SELECT block_3.Peer, block_3.date AS day
	FROM block_3
		INNER JOIN block_2 ON block_3.Task = block_2.Title;
END;
$$ LANGUAGE plpgsql;

CALL finish_block('data', 'C');
FETCH ALL FROM "data";
CLOSE "data";

--8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
--Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, 
--проверяться у которого рекомендует наибольшее число друзей. 
--Формат вывода: ник пира, ник найденного проверяющего

DROP PROCEDURE IF EXISTS recommen_peer;

CREATE OR REPLACE PROCEDURE recommen_peer(result_data refcursor)
AS $$
	BEGIN OPEN result_data FOR
SELECT DISTINCT ON (peer1) peer1 AS peer,
	RecommendedPeer
FROM (SELECT Friends.peer1, Recommendations.RecommendedPeer,
	COUNT(Recommendations.RecommendedPeer) AS count
FROM Friends
	JOIN Recommendations 
	ON Recommendations.Peer = Friends.peer1
	WHERE Friends.Peer1 != Recommendations.RecommendedPeer
	GROUP BY Friends.Peer1, Recommendations.RecommendedPeer
		ORDER BY Friends.Peer1, count DESC)
	AS recom;
END;
$$ LANGUAGE plpgsql;

CALL recommen_peer('data');
FETCH ALL FROM "data";
CLOSE "data";

--9)Определить процент пиров, которые:
--Приступили только к блоку 1
--Приступили только к блоку 2
--Приступили к обоим
--Не приступили ни к одному
--Пир считается приступившим к блоку, если он проходил хоть одну проверку любого задания из этого блока (по таблице Checks)
--Параметры процедуры: название блока 1, например SQL, название блока 2, например A. 
--Формат вывода: процент приступивших только к первому блоку, процент приступивших только ко второму блоку, процент приступивших к обоим, процент не приступивших ни к одному

DROP PROCEDURE IF EXISTS started_block_percent(result_data refcursor, name_block_1 VARCHAR, name_block_2 VARCHAR);

CREATE OR REPLACE PROCEDURE started_block_percent(result_data refcursor, name_block_1 VARCHAR, name_block_2 VARCHAR)
AS $$
BEGIN OPEN result_data FOR
WITH StartedBlock1 AS 
	(SELECT DISTINCT Peer FROM Peers LEFT JOIN Checks ON Peers.Nickname = Checks.Peer
		WHERE Checks.Task SIMILAR TO CONCAT('C','[0-9_]%')),
	StartedBlock2 AS
	(SELECT DISTINCT Checks.Peer FROM Checks
		WHERE Checks.Task SIMILAR TO CONCAT('DO', '[0-9_]%')),
	StartedBothBlocks as 
	(SELECT DISTINCT StartedBlock1.Peer FROM StartedBlock1
		INNER JOIN StartedBlock2 ON StartedBlock1.Peer = StartedBlock2.Peer),
	Startedoneof AS
	(SELECT DISTINCT Peer FROM ((SELECT * FROM StartedBlock1)
		UNION (SELECT * FROM StartedBlock2)) AS tmp), 
	
	count_startedblock1 AS (SELECT COUNT(*) AS count_StartedBlock1 FROM StartedBlock1),
	count_startedblock2 AS (SELECT COUNT(*) AS count_StartedBlock2 FROM StartedBlock2),
	count_StartedBothBlocks AS (SELECT COUNT(*) AS count_StartedBothBlocks FROM StartedBothBlocks),
	count_Startedoneof AS (SELECT COUNT(*) AS count_Startedoneof FROM Startedoneof)

SELECT ((SELECT count_startedblock1::bigint FROM count_StartedBlock1) * 100 / (SELECT COUNT(Peers.Nickname) FROM peers)) AS StartedBlock1,
		((SELECT count_startedblock2::bigint FROM count_StartedBlock2) * 100 / (SELECT COUNT(Peers.Nickname) FROM peers)) AS StartedBlock2,
		((SELECT count_StartedBothBlocks::bigint FROM count_StartedBothBlocks) * 100 / (SELECT COUNT(Peers.Nickname) FROM Peers)) AS StartedBothBlocks,
		((SELECT (SELECT COUNT(Peers.Nickname) FROM Peers) - count_Startedoneof::bigint FROM count_Startedoneof) * 100 / (SELECT COUNT(Peers.Nickname) FROM Peers)) AS DidntStartAnyBlock;

END;
$$ LANGUAGE plpgsql;

CALL started_block_percent('data', 'C', 'DO');
FETCH ALL FROM "data";
CLOSE "data";

--10) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
--Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения. 
--Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения

DROP PROCEDURE IF EXISTS checks_bithday();

CREATE OR REPLACE PROCEDURE checks_bithday(result_data refcursor)
AS $$
	BEGIN
		OPEN result_data FOR
WITH date_bithday AS 
	(SELECT 
	COUNT(Peer)	FILTER(WHERE P2P.State <> 'Failure' AND Verter.State <> 'Failure')
			AS success, 
	COUNT(Peer)	FILTER (WHERE (P2P.State = 'Success' AND Verter.State = 'Failure')
			OR P2P.State = 'Failure') AS failing,
	COUNT(Peer) AS alls
		FROM Checks
			JOIN P2P ON Checks.ID = p2p.сhecks 
			JOIN Verter ON Checks.ID = Verter.Checks
			JOIN Peers ON Peers.Nickname = Checks.Peer
		WHERE extract(month FROM Checks.Date) =
			extract(month FROM Peers.Birthday)
		AND
			extract(day FROM Checks.Date) = extract(day FROM Peers.Birthday))
SELECT ((success::NUMERIC / alls::NUMERIC) * 100)::INT as SuccessfulChecks,
	((failing::NUMERIC /alls::NUMERIC) * 100)::INT as UnsuccessfulChecks
	FROM date_bithday;
END;
$$ LANGUAGE plpgsql;

CALL checks_bithday('data');
FETCH ALL FROM "data";
CLOSE "data";

--11)Определите всех сверхстников, которые выполнили задания 1 и 2,
--но не выполнили задание 3

DROP PROCEDURE IF EXISTS peer_checker();

CREATE OR REPLACE PROCEDURE peer_checker(IN ref refcursor, IN task1 VARCHAR, task2 VARCHAR, task3 VARCHAR)
AS $$ 
BEGIN
	OPEN ref FOR
	WITH tmp_task_1 AS (SELECT Peer FROM Checks WHERE Checks.Task = task1 GROUP BY Peer),
	tmp_task_2 AS (SELECT Peer FROM Checks WHERE Checks.Task = task2 GROUP BY Peer), 
	tmp_task_3 AS (SELECT Peer FROM Checks WHERE Checks.Task != task3 GROUP BY Peer)
	SELECT * FROM ((SELECT Peer FROM tmp_task_1) 
		intersect (SELECT Peer FROM tmp_task_2) 
			intersect (SELECT Peer FROM tmp_task_3)) AS result_table;
END;
$$ LANGUAGE plpgsql;

CALL peer_checker('data', 'CPP7_MLP', 'C4_s21_math', 'A1_Maze');
FETCH ALL FROM "data";
CLOSE "data";

--12) Используя рекурсивное общее табличное выражение, выведите количество предыдущих задач для каждой задачи.
--т. е. Сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей.
--Формат вывода: имя задачи, количество предшествующих задач

DROP PROCEDURE IF EXISTS recursive_table_expression();

CREATE OR REPLACE PROCEDURE recursive_table_expression(in ref refcursor)
AS $$
BEGIN
	OPEN ref FOR 
	WITH RECURSIVE table_recursive AS (
	SELECT title AS task, parenttask,
	(CASE 
		WHEN parenttask IS NOT NULL
		THEN 1
			ELSE 0
				END) AS cnt
	FROM tasks
	UNION ALL
	SELECT tasks2.Title as task, previos.Task as parenttask,
	(CASE 
		WHEN tasks2.parenttask IS NOT NULL
		THEN cnt + 1 
			ELSE cnt END) 
				AS cnt
		FROM tasks AS tasks2
	CROSS JOIN table_recursive AS previos
		WHERE previos.task = tasks2.parenttask)
	
	SELECT task, MAX(cnt) AS prevcount FROM table_recursive
	GROUP BY task;
	
END;
$$ LANGUAGE plpgsql;

CALL recursive_table_expression('data');
FETCH ALL FROM "data";
CLOSE "data";

--13) Найдите «счастливые» дни для проверок. День считается «счастливым», если в нем не менее N 
-- последовательных успешных проверок.
--Параметры процедуры: N количество последовательных успешных проверок.
--Время проверки является временем начала шага P2P.
--Успешные последовательные проверки — это проверки без неудачных проверок между ними.
--Сумма XP за каждую из этих проверок должна быть не менее 80% от максимальной.
--Формат вывода: список дней

DROP PROCEDURE IF EXISTS lucky_days_for_checks();

CREATE OR REPLACE PROCEDURE lucky_days_for_checks(IN ref refcursor, IN N INTEGER)
AS $$
BEGIN
	OPEN ref FOR 
WITH tmp_1 AS
(SELECT time, Checks."date", 
	CASE WHEN (XP.XPAmount IS NULL) OR (Tasks.MaxXP IS NULL) THEN false
	WHEN XP.XPAmount *100 / Tasks.MaxXP >= 80 THEN true
		ELSE false 
			END AS success
	FROM P2P JOIN checks ON p2p.id = checks.id
		JOIN XP
			ON checks.id = xp.checks 
		JOIN tasks
				on checks.task = tasks.title
		ORDER BY 1, 2),
tmp_2 as
(SELECT  time, "date", success, CASE WHEN success THEN row_number() over() --номер текущей строки в её разделе, начиная с 1
	ELSE NULL
		END AS num FROM tmp_1),
tmp_3 AS
(SELECT time, "date", success, 
CASE WHEN num IS NOT NULL AND 
	((LAG(num, 1, NULL) over()) IS NULL OR (LAG(date, 1, NULL) over()) != date) THEN num--LAG()обеспечивает доступ к строке, которая предшествует текущей строке б б т
--с указанным физическим смещением. Другими словами, из текущей строки LAG()функция может получить доступ 
--к данным предыдущей строки или строки перед предыдущей строкой и так далее.
	WHEN num IS NOT NULL AND
		((LAG(num, 1, NULL) OVER()) IS NOT NULL OR
		(LAG(date, 1, NULL) OVER()) = date) THEN LAG(num, 1, 1) OVER()
	ELSE NULL
END AS Rank
FROM tmp_2)
	
SELECT date FROM tmp_3 GROUP BY date, RANK HAVING COUNT(rank) >= N;
END;
$$ LANGUAGE plpgsql;

CALL lucky_days_for_checks('data', 1);
FETCH ALL FROM "data";
CLOSE "data";

--##### 14) Определить пира с наибольшим количеством XP
--Формат вывода: ник пира, количество XP

--Пример вывода:
--| Peer   | XP    |
--|--------|-------|
--| Amogus | 15000 |

DROP PROCEDURE IF EXISTS peer_highest_XP();

CREATE OR REPLACE PROCEDURE peer_highest_XP(IN ref refcursor)
AS $$
BEGIN
	OPEN ref FOR 
SELECT Peer, SUM(XPAmount) as XP
FROM Checks
JOIN XP ON Checks.ID = XP.ID
GROUP BY Peer
ORDER BY XP DESC
LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CALL peer_highest_XP('data');
FETCH ALL FROM "data";
CLOSE "data";

--##### 15) Определить пиров, приходивших раньше заданного времени не менее *N* раз за всё время
--Параметры процедуры: время, количество раз *N*. \
--Формат вывода: список пиров

DROP PROCEDURE IF EXISTS peers_come_before();

CREATE OR REPLACE PROCEDURE peers_come_before(in ref refcursor, in time_tracing time, in N integer)
AS $$
BEGIN
	OPEN ref FOR
SELECT Peer
FROM TimeTracking
WHERE State = 1 AND Time < time_tracing
GROUP BY Peer
HAVING COUNT(peer) >= N;
END;
$$ LANGUAGE plpgsql;

CALL peers_come_before('data', '20:00:00', 2);
FETCH ALL FROM "data";
CLOSE "data";

--##### 16) Определить пиров, выходивших за последние *N* дней из кампуса больше *M* раз
--Параметры процедуры: количество дней *N*, количество раз *M*. \
--Формат вывода: список пиров

DROP PROCEDURE IF EXISTS peers_out_cumpus();

CREATE OR REPLACE PROCEDURE peers_out_cumpus(IN ref refcursor, IN N INTEGER, IN M INTEGER)
AS $$
BEGIN
	OPEN ref FOR
WITH tmp_table AS (SELECT Peer, COUNT(Peer) AS count
	FROM TimeTracking
		WHERE State = 2 AND Date > (current_date - N) 
			GROUP BY Peer)
SELECT Peer FROM tmp_table
	WHERE count > M;
END;
$$ LANGUAGE plpgsql;

CALL peers_out_cumpus('data', 1000, 1);
FETCH ALL FROM "data";
CLOSE "data";

--##### 17) Определить для каждого месяца процент ранних входов
--Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус за всё время (будем называть это общим числом входов). \
--Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус раньше 12:00 за всё время (будем называть это числом ранних входов). \
--Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов. \
--Формат вывода: месяц, процент ранних входов

--Пример вывода:
--| Month    | EarlyEntries |  
--| -------- | -------------- |
--| January  | 15           |
--| February | 35           |
--| March    | 45           |


DROP PROCEDURE IF EXISTS percentage_early_entries();

CREATE OR REPLACE PROCEDURE percentage_early_entries(IN ref refcursor)
AS $$
BEGIN
	OPEN ref FOR
WITH tmp_table AS (SELECT time, extract(month FROM birthday) AS m_e 
	FROM TimeTracking 
		JOIN Peers
	ON TimeTracking.Peer = Peers.Nickname AND State = 1),
number_entries AS (SELECT m_e, COUNT(time) AS numb
	FROM tmp_table GROUP BY m_e),
early_entries AS (SELECT m_e, COUNT(time) AS early
	FROM tmp_table WHERE time < '12:00' GROUP BY m_e)
	
SELECT to_char(to_timestamp(number_entries.m_e::TEXT, 'MM'), 'MONTH') AS month, 
	ROUND(early * 100/ numb)
	FROM number_entries
	JOIN early_entries
	ON number_entries.m_e=early_entries.m_e
	ORDER BY number_entries.m_e;
END;
$$ LANGUAGE plpgsql;

CALL percentage_early_entries('data');
FETCH ALL FROM "data";
CLOSE "data";
