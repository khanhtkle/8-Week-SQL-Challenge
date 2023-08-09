# :pizza: Case Study 2 - Pizza Runner

## B. Runner and Customer Experience

<picture>
  <img src="https://img.shields.io/badge/postgresql-4169e1?style=for-the-badge&logo=postgresql&logoColor=white">
</picture>

### Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
- Solution uses for the ISO 8601 standard where the first day of the week is Monday.
```pgsql
SELECT DATE_PART('week', registration_date)::INTEGER AS week_number,
       CASE
           WHEN DATE_TRUNC('week', registration_date) < '2021-01-01' THEN '2021-01-01'
           ELSE DATE_TRUNC('week', registration_date)
       END::DATE AS week_start_date,
       (DATE_TRUNC('week', registration_date) + INTERVAL '1 week - 1 day')::DATE AS week_END_date,
       COUNT(runner_id)::INTEGER AS signed_up_runner_count
FROM pizza_runner.runners
GROUP BY 1, 2, 3
ORDER BY 2;
```
| week_number | week_start_date | week_end_date | signed_up_runner_count |
|-------------|-----------------|---------------|------------------------|
| 53          | 2021-01-01      | 2021-01-03    | 2                      |
| 1           | 2021-01-04      | 2021-01-10    | 1                      |
| 2           | 2021-01-11      | 2021-01-17    | 1                      |

- Solution uses for the United States standard where the first day of the week is Sunday.
```pgsql
SELECT CASE
           WHEN DATE_PART('isodow', registration_date) = 7 THEN DATE_PART('week', registration_date + INTERVAL '1 day')
           ELSE DATE_PART('week', registration_date)
       END::INTEGER AS week_number,
       CASE
            WHEN DATE_PART('isodow', registration_date) = 7 THEN (DATE_TRUNC('week', registration_date + INTERVAL '1 day') + INTERVAL '-1 day')
            WHEN (DATE_TRUNC('week', registration_date) + INTERVAL '-1 day') < '2021-01-01' THEN '2021-01-01'
            ELSE (DATE_TRUNC('week', registration_date) + INTERVAL '-1 day')
       END::DATE AS week_start_date,
       CASE
            WHEN DATE_PART('isodow', registration_date) = 7 THEN (DATE_TRUNC('week', registration_date + INTERVAL '1 day') + INTERVAL '1 week - 2 day')
            ELSE (DATE_TRUNC('week', registration_date) + INTERVAL '1 week - 2 day')
       END::DATE AS week_end_date,
       COUNT(runner_id)::INTEGER AS signed_up_runner_count
FROM pizza_runner.runners
GROUP BY 1, 2, 3
ORDER BY 2;
```
| week_number | week_start_date | week_end_date | signed_up_runner_count |
|-------------|-----------------|---------------|------------------------|
| 53          | 2021-01-01      | 2021-01-02    | 1                      |
| 1           | 2021-01-03      | 2021-01-09    | 2                      |
| 2           | 2021-01-10      | 2021-01-16    | 1                      |

---
### Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```pgsql
SELECT runner_id,
       ROUND(AVG(DATE_PART('minute', pickup_time - order_time))::NUMERIC)::REAL AS avg_pickup_time_minutes
FROM pizza_runner.cleaned_customer_orders AS co
JOIN pizza_runner.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL
GROUP BY 1;
```
| runner_id | avg_pickup_time_minutes |
|-----------|-------------------------|
| 1         | 15                      |
| 2         | 23                      |
| 3         | 10                      |

---
### Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```pgsql
WITH prep_time_minutes_cte AS
  (SELECT COUNT(co.order_id)::INTEGER AS ordered_pizza_count,
          DATE_PART('minute', pickup_time - order_time)::INTEGER AS prep_time_minutes
   FROM pizza_runner.cleaned_customer_orders AS co
   JOIN pizza_runner.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
   GROUP BY co.order_id, 2)
SELECT ordered_pizza_count,
       ROUND(AVG(prep_time_minutes)::NUMERIC)::REAL AS avg_prep_time_minutes
FROM prep_time_minutes_cte
GROUP BY 1
ORDER BY 1;
```
| ordered_pizza_count | avg_prep_time_minutes |
|---------------------|-----------------------|
| 1                   | 12                    |
| 2                   | 18                    |
| 3                   | 29                    |

- Drawing from the presented data:
  - As the number of pizzas in order increases, the average preparation time also increases.
  - The average preparation time appears to be non-linearly related to the number of pizzas.

---
### Q4. What was the average distance travelled for each customer?
```pgsql
SELECT customer_id,
       ROUND(AVG(distance)::NUMERIC, 1)::REAL AS avg_distance
FROM pizza_runner.cleaned_customer_orders AS co
JOIN pizza_runner.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL
GROUP BY 1;
```
| customer_id | avg_distance |
|-------------|--------------|
| 101         | 20           |
| 102         | 16.7         |
| 103         | 23.4         |
| 104         | 10           |
| 105         | 25           |

---
### Q5. What was the difference between the longest and shortest delivery times for all orders?
```pgsql
SELECT MAX(duration) - MIN(duration) AS delivery_time_difference_minutes
FROM pizza_runner.cleaned_runner_orders;
```
| delivery_time_difference_minutes |
|----------------------------------|
| 30                               |

---
### Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```pgsql
SELECT runner_id,
       co.order_id,
       distance,
       duration,
       COUNT(co.order_id)::INTEGER AS pizza_count,
       ROUND(AVG(distance / duration * 60)::NUMERIC, 1)::REAL AS avg_speed
FROM pizza_runner.cleaned_customer_orders AS co
JOIN pizza_runner.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL
GROUP BY 1, 2, 3, 4
ORDER BY 1, 6;
```
| runner_id | order_id | distance | duration | pizza_count | avg_speed |
|-----------|----------|----------|----------|-------------|-----------|
| 1         | 1        | 20       | 32       | 1           | 37.5      |
| 1         | 3        | 13.4     | 20       | 2           | 40.2      |
| 1         | 2        | 20       | 27       | 1           | 44.4      |
| 1         | 10       | 10       | 10       | 2           | 60        |
| 2         | 4        | 23.4     | 40       | 3           | 35.1      |
| 2         | 7        | 25       | 25       | 1           | 60        |
| 2         | 8        | 23.4     | 15       | 1           | 93.6      |
| 3         | 5        | 10       | 15       | 1           | 40        |

- Drawing from the presented data:
  - Runner 1 maintained an average speed ranging from 37.5 km/h to 60 km/h, indicating consistent performance across different orders.
  - Runner 2 exhibited a wide range of average speeds, spanning from 35.1 km/h to an alarmingly high speed 93.6 km/h. The substantial disparity in operating speed warrants serious safety concerns.
  - Runner 3 has a consistent average speed of 40 units for the single order listed.

---
### Q7. What is the successful delivery percentage for each runner?
```pgsql
SELECT runner_id,
       COUNT(pickup_time)::INTEGER AS delivered_order_count,
       COUNT(order_id)::INTEGER AS total_orders,
       (100.0 * COUNT(pickup_time) / COUNT(*))::DECIMAL(5,2) AS successful_delivery_pct
FROM pizza_runner.cleaned_runner_orders
GROUP BY 1
ORDER BY 1;
```
| runner_id | delivered_order_count | total_orders | successful_delivery_pct |
|-----------|-----------------------|--------------|-------------------------|
| 1         | 4                     | 4            | 100.00                  |
| 2         | 3                     | 4            | 75.00                   |
| 3         | 1                     | 2            | 50.00                   |

---
My solution for **[C. Ingredient Optimisation](C.%20Ingredient%20Optimisation.md)**.
