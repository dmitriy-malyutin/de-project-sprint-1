--Создадим витрину
CREATE TABLE analysis.dm_rfm_segments (user_id Int, recency Int, frequency Int, monetary_value Int);

--Узнаем количество пользователей на одну категорию (5 категорий)
SELECT (COUNT(DISTINCT(user_id))/5)
FROM analysis.orders
WHERE status = 4;

--Расставим клиентов по категориям 'monetary_value', создадим представление
CREATE VIEW analysis.monetary_view AS
WITH monetary AS (
	SELECT user_id, SUM(payment) as total_payment
	FROM analysis.orders
	WHERE status = 4
	GROUP BY user_id
	ORDER BY total_payment desc
) 
SELECT *,
	CASE 
		WHEN ROW_NUMBER() OVER() > 0 AND ROW_NUMBER() OVER() < 198 THEN 5
		WHEN ROW_NUMBER() OVER() > 197 AND ROW_NUMBER() OVER() < 395 THEN 4
		WHEN ROW_NUMBER() OVER() > 394 AND ROW_NUMBER() OVER() < 593 THEN 3
		WHEN ROW_NUMBER() OVER() > 592 AND ROW_NUMBER() OVER() < 790 THEN 2
		WHEN ROW_NUMBER() OVER() > 789 THEN 1
		END monetary_value
FROM monetary;

--Посчитаем категории для frequency, создадим представление
CREATE VIEW analysis.frequncy_view AS
WITH frequncy AS (
	SELECT user_id, COUNT(order_id) as freq
	FROM analysis.orders
	WHERE status = 4
	GROUP BY user_id
	ORDER BY freq desc
)
SELECT *, 
	CASE 
	WHEN ROW_NUMBER() OVER() > 0 AND ROW_NUMBER() OVER() < 198 THEN 5
	WHEN ROW_NUMBER() OVER() > 197 AND ROW_NUMBER() OVER() < 395 THEN 4
	WHEN ROW_NUMBER() OVER() > 394 AND ROW_NUMBER() OVER() < 593 THEN 3
	WHEN ROW_NUMBER() OVER() > 592 AND ROW_NUMBER() OVER() < 790 THEN 2
	WHEN ROW_NUMBER() OVER() > 789 THEN 1
	END frequency
FROM frequncy;

--Посчитаем для категории Recency, создадим представление
CREATE VIEW analysis.recency_view AS
WITH dates_last_order AS (
	SELECT user_id, MIN(order_ts) as last_order
	FROM analysis.orders
	WHERE status = 4
	GROUP BY user_id
	ORDER BY last_order desc
)
SELECT *, 
	CASE 
	WHEN ROW_NUMBER() OVER() > 0 AND ROW_NUMBER() OVER() < 198 THEN 5
	WHEN ROW_NUMBER() OVER() > 197 AND ROW_NUMBER() OVER() < 395 THEN 4
	WHEN ROW_NUMBER() OVER() > 394 AND ROW_NUMBER() OVER() < 593 THEN 3
	WHEN ROW_NUMBER() OVER() > 592 AND ROW_NUMBER() OVER() < 790 THEN 2
	WHEN ROW_NUMBER() OVER() > 789 THEN 1
	END recency
FROM dates_last_order;

--Соберём всё вместе и наполним таблицу 'dm_rfm_segments' данными


INSERT INTO analysis.dm_rfm_segments (user_id, recency, frequency, monetary_value)
SELECT m.user_id, re.recency, fr.frequency, m.monetary_value
FROM analysis.monetary_view m FULL JOIN analysis.frequncy_view fr ON m.user_id = fr.user_id FULL JOIN analysis.recency_view re ON m.user_id = re.user_id;

-- Проверим данные
SELECT *
FROM analysis.dm_rfm_segments drs
LIMIT 10

'''
user_id		recency		frequency	monetary_value
0			3			3			4
1			4			3			3
2			4			3			5
3			4			3			3
4			3			3			3
5			1			5			5
6			1			3			5
7			4			2			2
8			2			1			3
9			5			2			2
'''



