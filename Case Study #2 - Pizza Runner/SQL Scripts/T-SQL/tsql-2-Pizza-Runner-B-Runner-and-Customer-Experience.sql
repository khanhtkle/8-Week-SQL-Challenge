-------------------------------------------
-- B. Runner and Customer Experience --
-------------------------------------------
--	1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--	Solution uses for the ISO 8601 standard where the first day of the week is Monday.

SET DATEFIRST 1;
SELECT DATEPART(iso_week, registration_date) AS week_number,
       CASE
           WHEN DATEADD(dd, -DATEPART(dw, registration_date) + 1, registration_date) < '2021-01-01' THEN '2021-01-01'
           ELSE DATEADD(dd, -DATEPART(dw, registration_date) + 1, registration_date)
       END AS week_start_date,
       DATEADD(dd, 7 - DATEPART(dw, registration_date), registration_date) AS week_end_date,
       COUNT(runner_id) AS signed_up_runner_count
FROM pizza_runner.dbo.runners
GROUP BY DATEPART(iso_week, registration_date),
         CASE
             WHEN DATEADD(dd, -DATEPART(dw, registration_date) + 1, registration_date) < '2021-01-01' THEN '2021-01-01'
             ELSE DATEADD(dd, -DATEPART(dw, registration_date) + 1, registration_date)
         END,
         DATEADD(dd, 7 - DATEPART(dw, registration_date), registration_date)
ORDER BY week_start_date;

--	Solution uses for the United States standard where the first day of the week is Sunday.

SET DATEFIRST 7;
SELECT CASE
           WHEN DATEPART(WEEK, registration_date) - 1 = 0 THEN 53
           ELSE DATEPART(WEEK, registration_date) - 1
       END AS week_number,
       CASE
           WHEN DATEADD(dd, -DATEPART(dw, registration_date) + 1, registration_date) < '2021-01-01' THEN '2021-01-01'
           ELSE DATEADD(dd, -DATEPART(dw, registration_date) + 1, registration_date)
       END AS week_start_date,
       DATEADD(dd, 7 - DATEPART(dw, registration_date), registration_date) AS week_end_date,
       COUNT(runner_id) AS signed_up_runner_count
FROM pizza_runner.dbo.runners
GROUP BY CASE
             WHEN DATEPART(WEEK, registration_date) - 1 = 0 THEN 53
             ELSE DATEPART(WEEK, registration_date) - 1
         END,
         DATEADD(dd, -DATEPART(dw, registration_date) + 1, registration_date),
         DATEADD(dd, 7 - DATEPART(dw, registration_date), registration_date)
ORDER BY week_start_date;

--	2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id,
       AVG(DATEPART(mi, pickup_time - order_time)) AS avg_pickup_time_minutes
FROM pizza_runner.dbo.cleaned_customer_orders AS co
JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL
GROUP BY runner_id;

--	3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH prep_time_minutes_cte AS
  (SELECT COUNT(co.order_id) AS ordered_pizza_count,
          DATEPART(mi, pickup_time - order_time) AS prep_time_minutes
   FROM pizza_runner.dbo.cleaned_customer_orders AS co
   JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
   GROUP BY co.order_id,
            DATEPART(mi, pickup_time - order_time))
SELECT ordered_pizza_count,
       AVG(prep_time_minutes) AS avg_prep_time_minutes
FROM prep_time_minutes_cte
GROUP BY ordered_pizza_count;

--	Apparently, as the number of pizzas in an order increases, the preparation time tends to be longer.

--	4. What was the average distance travelled for each customer?

SELECT customer_id,
       ROUND(AVG(distance), 1) AS avg_distance
FROM pizza_runner.dbo.cleaned_customer_orders AS co
JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL
GROUP BY customer_id;

--	5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - MIN(duration) AS delivery_time_difference_minutes
FROM pizza_runner.dbo.cleaned_runner_orders;

--	6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT runner_id,
       co.order_id,
       distance,
       duration,
       COUNT(co.order_id) AS pizza_count,
       ROUND(AVG(distance / duration * 60), 1) AS avg_speed
FROM pizza_runner.dbo.cleaned_customer_orders AS co
JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL
GROUP BY runner_id,
         co.order_id,
         distance,
         duration
ORDER BY runner_id,
		 avg_speed;
		 
--	Runner 1 maintained an average speed ranging from 37.5 km/h to 60 km/h, indicating consistent performance across different orders.
--	Runner 2 exhibited a wide range of average speeds, spanning from 35.1 km/h to an alarmingly high speed 93.6 km/h. The substantial disparity in operating speed warrants serious safety concerns.
--	Runner 3 has a consistent average speed of 40 units for the single order listed.

--	7. What is the successful delivery percentage for each runner?

SELECT runner_id,
	   COUNT(pickup_time) AS delivered_order_count,
	   COUNT(order_id) AS total_orders,
       CAST(100.0 * COUNT(pickup_time) / COUNT(*) AS DECIMAL(5,2)) AS successful_delivery_pct
FROM pizza_runner.dbo.cleaned_runner_orders 
GROUP BY runner_id;
