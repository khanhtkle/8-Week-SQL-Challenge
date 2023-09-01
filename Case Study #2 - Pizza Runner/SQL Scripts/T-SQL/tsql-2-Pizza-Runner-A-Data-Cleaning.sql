-------------------------------------------
-- A. Data Cleaning: Pizza Metrics --
-------------------------------------------
-- 	Create a table `cleaned_runner_orders` from `runner_orders` table:
--		- Convert all blank '' and 'null' text values in `pickup_time`, `duration` and `cancellation` into NULL values.
--		- Convert the data type of `pickup_time` from VARCHAR(19) to DATETIME2(0).
--		- Remove the 'km' suffix and convert the data type of `distance` from VARCHAR(7) to FLOAT.
--		- Remove the suffixes 'min', 'minute', 'minutes' and convert the data type of `distance` from VARCHAR(10) to INTEGER.

DROP TABLE IF EXISTS pizza_runner.dbo.cleaned_runner_orders;
SELECT order_id,
       runner_id,
       CASE
           WHEN pickup_time = 'null' THEN NULL
           ELSE CAST(pickup_time AS DATETIME2(0))
       END AS pickup_time,
       CASE
           WHEN distance = 'null' THEN NULL
           ELSE CAST(TRIM('km' FROM distance) AS FLOAT)
       END AS distance,
       CASE
           WHEN duration = 'null' THEN NULL
           ELSE CAST(SUBSTRING(duration, 1, 2) AS INTEGER)
       END AS duration,
       CASE
           WHEN cancellation in ('null', '') THEN NULL
           ELSE cancellation
       END AS cancellation 
INTO pizza_runner.dbo.cleaned_runner_orders
FROM pizza_runner.dbo.runner_orders;

SELECT * 
FROM pizza_runner.dbo.cleaned_runner_orders;

--	Create a new table `cleaned_customer_orders` from `customer_orders` table:
--		Convert all blank '' and 'null' text values in `exclusions` and `extras` into NULL values.
--		Convert the data type of `order_time` from VARCHAR(19) to DATETIME2(0).
-- 		Append `cancellation` from `cleaned_runner_orders` table.

DROP TABLE IF EXISTS pizza_runner.dbo.cleaned_customer_orders;
SELECT co.order_id,
       customer_id,
       pizza_id,
       CASE
           WHEN exclusions IN ('null', '') THEN NULL
           ELSE exclusions
       END AS exclusions,
       CASE
           WHEN extras IN ('null', 'NULL', '') THEN NULL
           ELSE extras
       END AS extras,
       CAST(order_time AS DATETIME2(0)) AS order_time,
       cancellation
INTO pizza_runner.dbo.cleaned_customer_orders 
FROM pizza_runner.dbo.customer_orders AS co
JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id;

SELECT *
FROM pizza_runner.dbo.cleaned_customer_orders;
