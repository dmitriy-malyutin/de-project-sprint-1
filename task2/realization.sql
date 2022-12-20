-- добавьте код сюда
CREATE OR REPLACE VIEW analysis.orders (order_id, order_ts, user_id, bonus_payment, payment, cost, bonus_grant, status) AS 
SELECT o.order_id, o.order_ts, o.user_id, o.bonus_payment, o.payment, o.cost, o.bonus_grant, ol.status_id
FROM production.orders o FULL JOIN production.orderstatuslog ol ON o.order_id = ol.order_id
WHERE 
ol.status_id IN (4, 5)
