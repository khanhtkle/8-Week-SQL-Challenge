# :pizza: Case Study 2 - Pizza Runner

## A. Pizza Metrics

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

* Create a table `cleaned_runner_orders` from `runner_orders` table:
  * Convert all blank ```''``` and ```'null'``` text values in `pickup_time`, `duration` and `cancellation` into ```NULL``` values.
  * Convert the data type of `pickup_time` from `VARCHAR(19)` to `DATETIME`.
  * Remove the ```'km'``` suffix and convert the data type of `distance` from `VARCHAR(7)` to `FLOAT`.
  * Remove the suffixes ```'mins'```, ```'minute'```, ```'minutes'``` and convert the data type of `distance` from `VARCHAR(10)` to `INTEGER`.
```tsql
DROP TABLE IF EXISTS pizza_runner.dbo.cleaned_runner_orders;
SELECT order_id,
       runner_id,
       CASE
           WHEN pickup_time = 'null' THEN NULL
           ELSE CAST(pickup_time AS DATETIME)
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
  ```
| order_id | runner_id | pickup_time             | distance | duration | cancellation            |
|----------|-----------|-------------------------|----------|----------|-------------------------|
| 1        | 1         | 2021-01-01 18:15:34.000 | 20       | 32       | NULL                    |
| 2        | 1         | 2021-01-01 19:10:54.000 | 20       | 27       | NULL                    |
| 3        | 1         | 2021-01-03 00:12:37.000 | 13.4     | 20       | NULL                    |
| 4        | 2         | 2021-01-04 13:53:03.000 | 23.4     | 40       | NULL                    |
| 5        | 3         | 2021-01-08 21:10:57.000 | 10       | 15       | NULL                    |
| 6        | 3         | NULL                    | NULL     | NULL     | Restaurant Cancellation |
| 7        | 2         | 2021-01-08 21:30:45.000 | 25       | 25       | NULL                    |
| 8        | 2         | 2021-01-10 00:15:02.000 | 23.4     | 15       | NULL                    |
| 9        | 2         | NULL                    | NULL     | NULL     | Customer Cancellation   |
| 10       | 1         | 2021-01-11 18:50:20.000 | 10       | 10       | NULL                    |

* Create a new table `cleaned_customer_orders` from `customer_orders` table:
  * Convert all blank ```''``` and ```'null'``` text values in `exclusions` and `extras` into `NULL` values.
  * Convert the data type of `order_time` from `VARCHAR(19)` to `DATETIME`.
  * Append the column `cancellation` from `cleaned_runner_orders` table.
```tsql
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
       CAST(order_time AS DATETIME) AS order_time,
	   cancellation
INTO pizza_runner.dbo.cleaned_customer_orders 
FROM pizza_runner.dbo.customer_orders AS co
JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id;

SELECT *
FROM pizza_runner.dbo.cleaned_customer_orders;
```
| order_id | customer_id | pizza_id | exclusions | extras | order_time              | cancellation            |
|----------|-------------|----------|------------|--------|-------------------------|-------------------------|
| 1        | 101         | 1        | NULL       | NULL   | 2021-01-01 18:05:02.000 | NULL                    |
| 2        | 101         | 1        | NULL       | NULL   | 2021-01-01 19:00:52.000 | NULL                    |
| 3        | 102         | 1        | NULL       | NULL   | 2021-01-02 23:51:23.000 | NULL                    |
| 3        | 102         | 2        | NULL       | NULL   | 2021-01-02 23:51:23.000 | NULL                    |
| 4        | 103         | 1        | 4          | NULL   | 2021-01-04 13:23:46.000 | NULL                    |
| 4        | 103         | 1        | 4          | NULL   | 2021-01-04 13:23:46.000 | NULL                    |
| 4        | 103         | 2        | 4          | NULL   | 2021-01-04 13:23:46.000 | NULL                    |
| 5        | 104         | 1        | NULL       | 1      | 2021-01-08 21:00:29.000 | NULL                    |
| 6        | 101         | 2        | NULL       | NULL   | 2021-01-08 21:03:13.000 | Restaurant Cancellation |
| 7        | 105         | 2        | NULL       | 1      | 2021-01-08 21:20:29.000 | NULL                    |
| 8        | 102         | 1        | NULL       | NULL   | 2021-01-09 23:54:33.000 | NULL                    |
| 9        | 103         | 1        | 4          | 1, 5   | 2021-01-10 11:22:59.000 | Customer Cancellation   |
| 10       | 104         | 1        | NULL       | NULL   | 2021-01-11 18:34:49.000 | NULL                    |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2021-01-11 18:34:49.000 | NULL                    |

--- 
### Q1. How many pizzas were ordered?
```tsql
SELECT COUNT(order_id) AS pizza_count
FROM pizza_runner.dbo.cleaned_customer_orders;
```
| pizza_count  |
|--------------|
| 14           |

---
### Q2. How many unique customer orders were made?
```tsql
WITH unique_orders_cte AS
  (SELECT DISTINCT pizza_id,
          exclusions,
          extras
   FROM pizza_runner.dbo.cleaned_customer_orders)
SELECT COUNT(*) AS unique_order_count
FROM unique_orders_cte;
```
| unique_order_count |
|--------------------|
| 8                  |

---
### Q3. How many successful orders were delivered by each runner?
```tsql
SELECT runner_id,
       COUNT(order_id) AS delivered_order_count
FROM pizza_runner.dbo.cleaned_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
```
| runner_id | delivered_order_count |
|-----------|-----------------------|
| 1         | 4                     |
| 2         | 3                     |
| 3         | 1                     |

---
### Q4. How many of each type of pizza was delivered?
```tsql
SELECT pizza_id,
       COUNT(order_id) AS delivered_pizza_count
FROM pizza_runner.dbo.cleaned_customer_orders
WHERE cancellation IS NULL
GROUP BY pizza_id;
```
| pizza_id | delivered_pizza_count |
|----------|-----------------------|
| 1        | 9                     |
| 2        | 3                     |

---
### Q5. How many Vegetarian and Meatlovers were ordered by each customer?
* Convert the data type of `pizza_name` from `TEXT` to `VARCHAR(10)` for broader compatibility with table-valued functions and to prevent potential errors.
```tsql
ALTER TABLE pizza_runner.dbo.pizza_names
ALTER COLUMN pizza_name VARCHAR(10);
GO
```
```tsql
SELECT customer_id,
       SUM(CASE
               WHEN pizza_name = 'Meatlovers' THEN 1
               ELSE 0
           END) AS ordered_meatlovers_count,
       SUM(CASE
               WHEN pizza_name = 'Vegetarian' THEN 1
               ELSE 0
           END) AS ordered_vegetarian_count
FROM pizza_runner.dbo.cleaned_customer_orders AS ro
JOIN pizza_runner.dbo.pizza_names AS pn ON pn.pizza_id= ro.pizza_id
GROUP BY customer_id;
```
| customer_id | ordered_meatlovers_count | ordered_vegetarian_count |
|-------------|--------------------------|--------------------------|
| 101         | 2                        | 1                        |
| 102         | 2                        | 1                        |
| 103         | 3                        | 1                        |
| 104         | 3                        | 0                        |
| 105         | 0                        | 1                        |

---
### Q6. What was the maximum number of pizzas delivered in a single order?
```tsql
SELECT TOP 1 COUNT(pizza_id) AS max_delivered_pizza_in_a_single_order
FROM pizza_runner.dbo.cleaned_customer_orders
WHERE cancellation IS NULL
GROUP BY order_id
ORDER BY max_delivered_pizza_in_a_single_order DESC;

```
| max_delivered_pizza_in_a_single_order |
|---------------------------------------|
| 3                                     |

---
### Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```tsql
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
FROM pizza_runner.dbo.cleaned_customer_orders
WHERE cancellation IS NULL;
```
| delivered_pizza_with_at_least_1_change_count | delivered_pizza_with_no_changes_count |
|----------------------------------------------|---------------------------------------|
| 6                                            | 6                                     |

---
### Q8. How many pizzas were delivered that had both exclusions and extras?
```tsql
SELECT SUM(CASE
               WHEN exclusions IS NOT NULL
                    AND extras IS NOT NULL THEN 1
               ELSE 0
           END) AS delivered_pizza_with_exclusions_and_extras_count
FROM pizza_runner.dbo.cleaned_customer_orders
WHERE cancellation IS NULL;
```
| delivered_pizza_with_exclusions_and_extras_count |
|--------------------------------------------------|
| 1                                                |

---
### Q9. What was the total volume of pizzas ordered for each hour of the day?
```tsql
SELECT DATEPART(hh, order_time) AS hour_of_day,
       COUNT(order_id) AS ordered_pizza_count
FROM pizza_runner.dbo.cleaned_customer_orders
GROUP BY DATEPART(hh, order_time)
ORDER BY DATEPART(hh, order_time);
```
| hour_of_day | ordered_pizza_count |
|-------------|---------------------|
| 11          | 1                   |
| 13          | 3                   |
| 18          | 3                   |
| 19          | 1                   |
| 21          | 3                   |
| 23          | 3                   |

---
### Q10. What was the volume of orders for each day of the week?
```tsql
SELECT DATENAME(dw, order_time) AS day_of_week,
	     COUNT(order_id) AS ordered_pizza_count
FROM pizza_runner.dbo.cleaned_customer_orders
GROUP BY DATENAME(dw, order_time),
         DATEPART(dw, order_time)
ORDER BY DATEPART(dw, order_time);
```
| week_day  | order_volume  |
|-----------|---------------|
| Friday    | 1             |
| Saturday  | 5             |
| Thursday  | 3             |
| Wednesday | 5             |

---
My solution for **[B. Runner and Customer Experience](B.%20Runner%20and%20Customer%20Experience.md)**.
