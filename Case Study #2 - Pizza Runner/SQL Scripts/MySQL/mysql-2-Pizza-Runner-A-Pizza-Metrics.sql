---------------------------------------
-- A. Pizza Metrics --
---------------------------------------
-- 	1. How many pizzas were ordered?

SELECT COUNT(order_id) AS pizza_count
FROM pizza_runner.cleaned_customer_orders;

-- 	2. How many unique customer orders were made?

WITH unique_orders_cte AS
  (SELECT DISTINCT pizza_id,
          exclusions,
          extras
   FROM pizza_runner.cleaned_customer_orders)
SELECT COUNT(*) AS unique_order_count
FROM unique_orders_cte;

-- 	3. How many successful orders were delivered by each runner?

SELECT runner_id,
       COUNT(order_id) AS delivered_order_count
FROM pizza_runner.cleaned_runner_orders
WHERE cancellation IS NULL
GROUP BY 1;

-- 	4. How many of each type of pizza was delivered?

SELECT pizza_id,
       COUNT(order_id) AS delivered_order_count
FROM pizza_runner.cleaned_customer_orders
WHERE cancellation IS NULL
GROUP BY 1;

-- 	5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id,
       SUM(CASE
               WHEN pizza_name = 'Meatlovers' THEN 1
               ELSE 0
           END) AS ordered_meatlovers_count,
       SUM(CASE
               WHEN pizza_name = 'Vegetarian' THEN 1
               ELSE 0
           END) AS ordered_vegetarian_count
FROM pizza_runner.cleaned_customer_orders AS ro
JOIN pizza_runner.pizza_names AS pn ON pn.pizza_id = ro.pizza_id
GROUP BY 1;

-- 	6. What was the maximum number of pizzas delivered in a single order?

SELECT COUNT(pizza_id) AS max_delivered_pizza_in_a_single_order
FROM pizza_runner.cleaned_customer_orders
WHERE cancellation IS NULL
GROUP BY order_id
ORDER BY 1 DESC
LIMIT 1;

-- 	7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT SUM(CASE
               WHEN exclusions IS NOT NULL
                    OR extras IS NOT NULL THEN 1
               ELSE 0
           END) AS delivered_pizza_with_at_least_1_change_count,
       SUM(CASE
               WHEN exclusions IS NULL
                    AND extras IS NULL THEN 1
               ELSE 0
           END) AS delivered_pizza_with_no_changes_count
FROM pizza_runner.cleaned_customer_orders AS co
JOIN pizza_runner.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL;

-- 	8. How many pizzas were delivered that had both exclusions and extras?

SELECT SUM(CASE
               WHEN exclusions IS NOT NULL
                    AND extras IS NOT NULL THEN 1
               ELSE 0
           END) AS delivered_pizza_with_exclusions_and_extras_count
FROM pizza_runner.cleaned_customer_orders
WHERE cancellation IS NULL;

-- 	9. What was the total volume of pizzas ordered for each hour of the day?

SELECT HOUR(order_time) AS hour_of_day,
       COUNT(order_id) AS ordered_pizza_count
FROM pizza_runner.cleaned_customer_orders
GROUP BY 1
ORDER BY 1;

-- 	10. What was the volume of orders for each day of the week?

SELECT	DAYNAME(order_time) AS day_of_week,
        COUNT(order_id) AS ordered_pizza_count
FROM pizza_runner.cleaned_customer_orders
GROUP BY 1
ORDER BY 2;
