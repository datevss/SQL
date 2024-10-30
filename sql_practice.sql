
--Работа с пропусками
SELECT CAST(COUNT(date_end) AS real) / COUNT(*) 
FROM rest_orders.dishes_prices;

SELECT *
FROM rest_orders.dishes_prices
WHERE date_end IS NOT NULL;

--Заполнение пропусков
SELECT order_id,
       COALESCE(total_cost, 1500) AS total_cost,
       COALESCE(discount, 0) AS discount,
       final_cost
FROM rest_orders.orders;

--Работа с дубликатами
SELECT first_name, last_name, COUNT(*)
FROM rest_orders.users
GROUP BY first_name, last_name
HAVING COUNT(*)>1;
------------------------------------
SELECT first_name, last_name
FROM rest_orders.users
WHERE registration_date < '2020-01-01'
GROUP BY first_name, last_name
HAVING COUNT(*) =1;

--Работа с join
SELECT c.city_name,
       COUNT(order_id) AS unique_order_count,
       SUM(final_cost) AS total_revenue
FROM rest_orders.cities AS c
INNER JOIN rest_orders.orders AS o USING (city_id)
GROUP BY c.city_name
ORDER BY total_revenue DESC;
------------------------------------
SELECT d.object_id,
       d.name,
       o.order_id
FROM rest_orders.dishes AS d
FULL JOIN rest_orders.order_items AS o ON d.object_id = o.item;
------------------------------------

SELECT d.name AS dish_name,
       COALESCE(c.city_name, 'Неизвестный город') AS city_name,
       COUNT(oi.order_id) AS order_count
FROM rest_orders.dishes AS d
LEFT JOIN rest_orders.order_items AS oi ON d.object_id = oi.item
LEFT JOIN rest_orders.orders AS o USING (order_id)
LEFT JOIN rest_orders.cities AS c USING (city_id)
GROUP BY d.name, c.city_name, o.city_id
ORDER BY d.name, order_count DESC;

------------------------------------
SELECT o.order_id,
       o.order_dt,
       u.first_name,
       u.last_name,
       c.city_name,
       d.name dish_name,
       dp.price dish_price,
       oi.count dish_count
FROM rest_orders.dishes_prices dp
LEFT JOIN rest_orders.dishes d ON dp.dishes_id = d.object_id
JOIN rest_orders.order_items oi ON d.object_id = oi.item
JOIN rest_orders.orders o USING (order_id)
JOIN rest_orders.users u USING (user_id)
JOIN rest_orders.cities c ON u.city_id = c.city_id
ORDER BY o.order_id, dish_name;

--Пересечение и вычитание
SELECT distinct user_id
FROM rest_orders.orders o
JOIN rest_orders.order_items oi USING (order_id)
WHERE device_type = 'Desktop' AND oi.count>=3
INTERSECT
SELECT distinct user_id
FROM rest_orders.orders o
JOIN rest_orders.order_items oi USING (order_id)
WHERE device_type = 'Mobile' AND oi.count>=3;

------------------------------------
SELECT order_id
FROM rest_orders.order_statuses
WHERE status_id = 1
EXCEPT
SELECT order_id
FROM rest_orders.order_statuses
WHERE status_id = 2;

--Объединение множеств
SELECT 
    'no_discount' AS order_type,
     COUNT(DISTINCT order_id) AS total_orders,
     COUNT(DISTINCT user_id) AS total_users,
     AVG(final_cost) AS avg_cost
FROM rest_orders.orders
WHERE discount=0 OR discount IS NULL
UNION
SELECT 
    'with_discount' AS order_type,
     COUNT(DISTINCT order_id) AS total_orders,
     COUNT(DISTINCT user_id) AS total_users,
     AVG(final_cost) AS avg_cost
FROM rest_orders.orders
WHERE discount !=0;

--Подзапросы
SELECT city_id,
       COUNT(order_id) AS fail_orders
FROM rest_orders.orders
WHERE order_id NOT IN 
   (SELECT order_id
    FROM rest_orders.order_statuses
    WHERE status_id = 2)
GROUP BY city_id
------------------------------------
SELECT *
FROM rest_orders.orders
WHERE final_cost>
(SELECT 
       AVG(final_cost) as avg_cost
FROM rest_orders.orders)
------------------------------------
SELECT city_name,
       COUNT(user_id) AS total_users,
       AVG(total_order) AS avg_orders,
       AVG(avg_cost) AS avg_cost
FROM (
    SELECT 
        city_name,
        user_id,
        COUNT(order_id) AS total_order,
        AVG(final_cost) AS avg_cost
    FROM rest_orders.orders AS o
    -- Присоединим данные о названии города:
    INNER JOIN rest_orders.cities AS c ON o.city_id = c.city_id
    -- Для расчёта сгруппируем данные по идентификатору клиента и городу:
    GROUP BY 
        user_id,
        city_name
) AS user_activity
GROUP BY city_name
