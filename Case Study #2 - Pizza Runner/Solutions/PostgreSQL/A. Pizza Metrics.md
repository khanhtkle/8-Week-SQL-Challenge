# :pizza: Case Study 2 - Pizza Runner

## A. Pizza Metrics

<picture>
  <img src="https://img.shields.io/badge/postgresql-4169e1?style=for-the-badge&logo=postgresql&logoColor=white">
</picture>

### Data Cleaning

1. Create a table `cleaned_runner_orders` from `runner_orders` table:
    - Convert all blank `''` and `'null'` text values in `pickup_time`, `duration` and `cancellation` into `NULL` values.
    - Convert the data type of `pickup_time` from `VARCHAR(19)` to `TIMESTAMP`.
    - Remove the `'km'` suffix and convert the data type of `distance` from `VARCHAR(7)` to `REAL`.
    - Remove the suffixes `'mins'`, `'minute'`, `'minutes'` and convert the data type of `distance` from `VARCHAR(10)` to `INTEGER`.
```pgsql
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

2. Create a new table `cleaned_customer_orders` from `customer_orders` table:
    - Convert all blank `''` and `'null'` text values in `exclusions` and `extras` into `NULL` values.
    - Convert the data type of `order_time` from `VARCHAR(19)` to `TIMESTAMP`.
    - Append `cancellation` from `cleaned_runner_orders` table.
```pgsql
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
```pgsql
SELECT COUNT(order_id) AS pizza_count
FROM pizza_runner.cleaned_customer_orders;
```
| pizza_count  |
|--------------|
| 14           |

---
### Q2. How many unique customer orders were made?
```pgsql
WITH unique_orders_cte AS
  (SELECT DISTINCT pizza_id,
          exclusions,
          extras
   FROM pizza_runner.cleaned_customer_orders)
SELECT COUNT(*) AS unique_order_count
FROM unique_orders_cte;
```
| unique_order_count |
|--------------------|
| 8                  |

---
### Q3. How many successful orders were delivered by each runner?
```pgsql
SELECT runner_id,
       COUNT(order_id) AS delivered_order_count
FROM pizza_runner.cleaned_runner_orders
WHERE cancellation IS NULL
GROUP BY 1;
```
| runner_id | delivered_order_count |
|-----------|-----------------------|
| 1         | 4                     |
| 2         | 3                     |
| 3         | 1                     |

---
### Q4. How many of each type of pizza was delivered?
```pgsql
SELECT pizza_id,
       COUNT(order_id) AS delivered_order_count
FROM pizza_runner.cleaned_customer_orders
WHERE cancellation IS NULL
GROUP BY 1;
```
| pizza_id | delivered_pizza_count |
|----------|-----------------------|
| 1        | 9                     |
| 2        | 3                     |

---
### Q5. How many Vegetarian and Meatlovers were ordered by each customer?
```pgsql
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
```pgsql
SELECT COUNT(pizza_id) AS max_delivered_pizza_in_a_single_order
FROM pizza_runner.cleaned_customer_orders
WHERE cancellation IS NULL
GROUP BY order_id
ORDER BY 1 DESC
LIMIT 1;
```
| max_delivered_pizza_in_a_single_order |
|---------------------------------------|
| 3                                     |

---
### Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```pgsql
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
```
| delivered_pizza_with_at_least_1_change_count | delivered_pizza_with_no_changes_count |
|----------------------------------------------|---------------------------------------|
| 6                                            | 6                                     |

---
### Q8. How many pizzas were delivered that had both exclusions and extras?
```pgsql
SELECT SUM(CASE
               WHEN exclusions IS NOT NULL
                    AND extras IS NOT NULL THEN 1
               ELSE 0
           END) AS delivered_pizza_with_exclusions_and_extras_count
FROM pizza_runner.cleaned_customer_orders
WHERE cancellation IS NULL;
```
| delivered_pizza_with_exclusions_and_extras_count |
|--------------------------------------------------|
| 1                                                |

---
### Q9. What was the total volume of pizzas ordered for each hour of the day?
```pgsql
SELECT DATE_PART('hour', order_time) AS hour_of_day,
       COUNT(order_id) AS ordered_pizza_count
FROM pizza_runner.cleaned_customer_orders
GROUP BY 1
ORDER BY 1;
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
```pgsql
SELECT TO_CHAR(order_time, 'Day') AS day_of_week,
       COUNT(order_id) AS ordered_pizza_count
FROM pizza_runner.cleaned_customer_orders
GROUP BY 1
ORDER BY 2, 1
```
| day_of_week | ordered_pizza_count |
|-------------|---------------------|
| Sunday      | 1                   |
| Saturday    | 3                   |
| Friday      | 5                   |
| Monday      | 5                   |

---
My solution for **[B. Runner and Customer Experience](B.%20Runner%20and%20Customer%20Experience.md)**.
