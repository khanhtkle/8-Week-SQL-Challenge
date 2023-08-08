-------------------------------------------
-- A. Data Cleaning: Pizza Metrics --
-------------------------------------------
-- 	Create a table `cleaned_runner_orders` from `runner_orders` table:
--		Convert all blank '' and 'null' text values in `pickup_time`, `duration` and `cancellation` into NULL values.
--		Convert the data type of `pickup_time` from VARCHAR(19) to TIMESTAMP.
--		Remove the 'km' suffix and convert the data type of `distance` from VARCHAR(7) to REAL.
--		Remove the suffixes 'min', 'minute', 'minutes' and convert the data type of `distance` from VARCHAR(10) to INTEGER.

DROP TABLE IF EXISTS pizza_runner.cleaned_runner_orders;
CREATE TABLE pizza_runner.cleaned_runner_orders AS
  (SELECT order_id,
          runner_id,
          CASE
              WHEN pickup_time = 'null' THEN NULL
              ELSE pickup_time::TIMESTAMP
          END AS pickup_time,
          CASE
              WHEN distance = 'null' THEN NULL
              ELSE TRIM('km' FROM distance)::REAL
          END AS distance,
          CASE
              WHEN duration = 'null' THEN NULL
              ELSE SUBSTRING(duration, 1, 2)::INTEGER
          END AS duration,
          CASE
              WHEN cancellation in ('null', '') THEN NULL
              ELSE cancellation
          END AS cancellation
   FROM pizza_runner.runner_orders);

SELECT *
FROM pizza_runner.cleaned_runner_orders;

--	Create a new table `cleaned_customer_orders` from `customer_orders` table:
--		Convert all blank '' and 'null' text values in `exclusions` and `extras` into NULL values.
--		Convert the data type of `order_time` from VARCHAR(19) to TIMESTAMP.
-- 		Append `cancellation` from `cleaned_runner_orders` table.

DROP TABLE IF EXISTS pizza_runner.cleaned_customer_orders;
CREATE TABLE pizza_runner.cleaned_customer_orders AS
  (SELECT co.order_id,
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
          order_time::TIMESTAMP AS order_time,
		  cancellation
   FROM pizza_runner.customer_orders AS co
   JOIN pizza_runner.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
   ORDER BY 1, 3);

SELECT *
FROM pizza_runner.cleaned_customer_orders;
