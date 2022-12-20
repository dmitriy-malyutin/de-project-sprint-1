# Витрина RFM

## 1.1. Выясните требования к целевой витрине.

Постановка задачи выглядит достаточно абстрактно - постройте витрину. Первым делом вам необходимо выяснить у заказчика детали. Запросите недостающую информацию у заказчика в чате.

Зафиксируйте выясненные требования. Составьте документацию готовящейся витрины на основе заданных вами вопросов, добавив все необходимые детали.

-----------

1. Витрина должна называться 'dm_rfm_segments' и располагаться в схеме 'analysis'
2. Витрина должна состоять из полей:

    user_id
    recency (число от 1 до 5, распределение по давности заказов)
    frequency (число от 1 до 5, распределение по частоте заказов)
    monetary_value (число от 1 до 5, распределение по потраченной сумме)
3. В витрине нужны данные с начала 2022 года.
4. Обновления витрины не нужны
5. Цель витрины - отображение RFM факторов для заказов в статусе 'Closed'


## 1.2. Изучите структуру исходных данных.

Полключитесь к базе данных и изучите структуру таблиц.

Если появились вопросы по устройству источника, задайте их в чате.

Зафиксируйте, какие поля вы будете использовать для расчета витрины.

-----------
user_id - users.id
recency (число от 1 до 5, 1 - не делал заказов или делал давно, 5 - делал недавно) - оценить по order_ts и user_id, для status = 4 (заказ готов). 
frequency (число от 1 до 5, 1 - наименьшее количество заказов, 5 - наибольшее) - аналогично recency, count(order_id)
monetary_value (число от 1 до 5, 1 - наименьшая сумма, 5 - наибольшая) - SUM(payment) для user_id



## 1.3. Проанализируйте качество данных

Изучите качество входных данных. Опишите, насколько качественные данные хранятся в источнике. Так же укажите, какие инструменты обеспечения качества данных были использованы в таблицах в схеме production.

-----------
В витрине основные данные берутся из столбцов 'payment', 'user_id', 'status'. Проверим эти данные.
```SQL
SELECT MIN(payment) AS min_pay, MAX(payment) AS max_pay, AVG(payment) as avg_pay, 
    COUNT(CASE WHEN payment IS NULL THEN 1 END) AS is_null
FROM production.orders
```
MIN         MAX         AVG                     is_null
60.00000	6360.00000	2289.9360000000000000   0

Данные по оплатам выглядят корректно, нет слишком большого разброса между MAX, MIN и AVG, Null-значения отсутствуют.
```SQL
SELECT MIN(user_id) AS min_user_id, MAX(user_id) AS max_user_id, COUNT(DISTINCT(user_id)) as total_users, 
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) AS is_null
FROM production.orders
```
min_user_id     max_user_id     total_users     is_null
0	            999	            1000	        0

Аналогично 'payments', проблем в данных не вижу. id пользователя - это его номер от 0 до 999, всего 1000. Null отсутствуют.

Т.к. нас интересуют только заказы в статусе 4, то другими статусами можно пренебречь.
```SQL
SELECT COUNT(CASE WHEN status IS NULL THEN 1 END) AS is_null, COUNT(status) AS total_status_4
FROM production.orders
WHERE 
status = 4
```
is_null     total_status_4
0	        4991

Здесь также не возникло замечаний.
В таблице присутствуют только статусы 4 и 5, что кажется логичным, промежуточные статусы тут не нужны.

Также, следует проверить содержимое данных с ценами и оплатами:
```SQL
SELECT * FROM analysis.orders
WHERE
payment <> cost
```
Возвращает пустую таблицу, таким образом можно брать любой из столбцов для оценки 'monetary_value'.
Следует проверить и колонку 'bonus_payment'. В зависимости от значения колонки (можно трактовать как чаевые или оплату бонусами), тот или иной клиент может подняться или опуститься в рейтинге. Судя по ограничению ((cost=(payments+bonus_payment))) это всё-таки оплата бонусами, но лучше уточнить значение этой колонки.
```SQL
SELECT * FROM analysis.orders o
WHERE
o.bonus_payment > 0
```
Также вернулась пустая таблица, данную колонку можно не учитывать, соответственно и значением этой колонки можно принебречь.

Таким образом, замечаний к данным нет.

## 1.4. Подготовьте витрину данных

Теперь, когда требования понятны, а исходные данные изучены, можно приступить к реализации.

### 1.4.1. Сделайте VIEW для таблиц из базы production.**

Вас просят при расчете витрины обращаться только к объектам из схемы analysis. Чтобы не дублировать данные (данные находятся в этой же базе), вы решаете сделать view. Таким образом, View будут находиться в схеме analysis и вычитывать данные из схемы production. 

Напишите SQL-запросы для создания пяти VIEW (по одному на каждую таблицу) и выполните их. Для проверки предоставьте код создания VIEW.

```SQL
--Впишите сюда ваш ответ
CREATE VIEW analysis.orderitems AS
	SELECT * FROM production.orderitems;

CREATE VIEW analysis.orders AS
	SELECT * FROM production.orders;

CREATE VIEW analysis.orderstatuses AS
	SELECT * FROM production.orderstatuses;
	
CREATE VIEW analysis.orderstatuslog AS
	SELECT * FROM production.orderstatuslog;
	
CREATE VIEW analysis.products AS
	SELECT * FROM production.products;

CREATE VIEW analysis.users AS
	SELECT * FROM production.users;
```
В задании идёт речь о пяти таблицах. Полагаю, таблицу 'orderstatuses' можно исклить из выборки.


### 1.4.2. Напишите DDL-запрос для создания витрины.**

Далее вам необходимо создать витрину. Напишите CREATE TABLE запрос и выполните его на предоставленной базе данных в схеме analysis.

```SQL
--Впишите сюда ваш ответ
CREATE TABLE analysis.dm_rfm_segments (user_id Int, recency Int, frequency Int, monetary_value Int);

```

### 1.4.3. Напишите SQL запрос для заполнения витрины

Наконец, реализуйте расчет витрины на языке SQL и заполните таблицу, созданную в предыдущем пункте.

Для решения предоставьте код запроса.

```SQL
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

SELECT *
FROM analysis.dm_rfm_segments drs




