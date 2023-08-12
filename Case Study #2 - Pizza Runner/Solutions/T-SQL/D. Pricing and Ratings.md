# :pizza: Case Study 2 - Pizza Runner

## D. Pricing and Ratings

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes. How much money has Pizza Runner made so far if there are no delivery fees?
```tsql
SELECT SUM(CASE
               WHEN pizza_id = 1 THEN 12
               ELSE 10
           END) AS total_revenue
FROM pizza_runner.dbo.cleaned_customer_orders AS co
WHERE cancellation IS NULL;
```
| total_revenue |
|---------------|
| 138           |

---
### Q2. What if there was an additional $1 charge for any pizza extras?
```tsql
SELECT SUM(CASE
               WHEN pizza_id = 1 THEN 12 + LEN(extras) - LEN(REPLACE(extras, ', ', ''))
               ELSE 10 + LEN(extras) - LEN(REPLACE(extras, ', ', ''))
           END) AS total_revenue_with_extras
FROM pizza_runner.dbo.cleaned_customer_orders AS co
WHERE cancellation IS NULL;
```
| total_revenue_with_extras |
|---------------------------|
| 36                        |

---
### Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
Note: The values of `rating` have been assigned in an arbitrary manner, devoid of any specific calculation or metrics.
```tsql
DROP TABLE IF EXISTS pizza_runner.dbo.ratings;
CREATE TABLE pizza_runner.dbo.ratings (
   "order_id" TINYINT, 
   "rating" TINYINT
);

INSERT INTO pizza_runner.dbo.ratings 
  ("order_id", "rating")
SELECT order_id,
       CASE
           WHEN order_id IN ('1', '2', '10') THEN 5
           WHEN order_id IN ('5', '7') THEN 4
           WHEN order_id IN ('3') THEN 3
           WHEN order_id IN ('4') THEN 2
           WHEN order_id IN ('8') THEN 1
       END AS rating
FROM
  (SELECT DISTINCT co.order_id
   FROM pizza_runner.dbo.cleaned_customer_orders AS co
   WHERE cancellation IS NULL) AS co;

SELECT *
FROM pizza_runner.dbo.ratings;
```
| order_id | rating |
|----------|--------|
| 1        | 5      |
| 2        | 5      |
| 3        | 3      |
| 4        | 2      |
| 5        | 4      |
| 7        | 4      |
| 8        | 1      |
| 10       | 5      |

---
### Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? {customer_id} {order_id} {runner_id} {rating} {order_time} {pickup_time} {Time between order and pickup} {Delivery duration} {Average speed} {Total number of pizzas}
```tsql
SELECT customer_id, 
       co.order_id, 
       runner_id,
       rating,
       order_time,
       pickup_time,
       DATEPART(mi, CAST(pickup_time AS DATETIME) - CAST(order_time AS DATETIME)) AS time_between_order_and_pickup,
       duration AS delivery_duration,
       ROUND(AVG(distance / duration * 60), 1) AS average_speed,
       COUNT(pizza_id) AS total_number_of_pizza  
FROM pizza_runner.dbo.cleaned_customer_orders AS co
JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
JOIN pizza_runner.dbo.ratings AS ra ON ra.order_id = co.order_id
WHERE co.cancellation IS NULL
GROUP BY customer_id, 
	 co.order_id, 
	 runner_id,
	 rating,
	 order_time,
	 pickup_time,
	 duration,
	 distance
ORDER BY order_id;
```
| customer_id | order_id | runner_id | rating | order_time          | pickup_time         | time_between_order_and_pickup | delivery_duration | average_speed | total_number_of_pizza |
|-------------|----------|-----------|--------|---------------------|---------------------|-------------------------------|-------------------|---------------|-----------------------|
| 101         | 1        | 1         | 5      | 2021-01-01 18:05:02 | 2021-01-01 18:15:34 | 10                            | 32                | 37.5          | 1                     |
| 101         | 2        | 1         | 5      | 2021-01-01 19:00:52 | 2021-01-01 19:10:54 | 10                            | 27                | 44.4          | 1                     |
| 102         | 3        | 1         | 3      | 2021-01-02 23:51:23 | 2021-01-03 00:12:37 | 21                            | 20                | 40.2          | 2                     |
| 103         | 4        | 2         | 2      | 2021-01-04 13:23:46 | 2021-01-04 13:53:03 | 29                            | 40                | 35.1          | 3                     |
| 104         | 5        | 3         | 4      | 2021-01-08 21:00:29 | 2021-01-08 21:10:57 | 10                            | 15                | 40            | 1                     |
| 105         | 7        | 2         | 4      | 2021-01-08 21:20:29 | 2021-01-08 21:30:45 | 10                            | 25                | 60            | 1                     |
| 102         | 8        | 2         | 1      | 2021-01-09 23:54:33 | 2021-01-10 00:15:02 | 20                            | 15                | 93.6          | 1                     |
| 104         | 10       | 1         | 5      | 2021-01-11 18:34:49 | 2021-01-11 18:50:20 | 15                            | 10                | 60            | 2                     |


---
### Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```tsql
SELECT SUM(CASE
               WHEN pizza_id = 1 THEN 12
               ELSE 10
           END) AS total_revenue,
       SUM(0.3 * distance) AS runner_payment,
       SUM(CASE
               WHEN pizza_id = 1 THEN 12
               ELSE 10
           END) - SUM(0.3 * distance) AS net_profit
FROM pizza_runner.dbo.cleaned_customer_orders AS co
JOIN pizza_runner.dbo.cleaned_runner_orders AS ro ON ro.order_id = co.order_id
WHERE co.cancellation IS NULL;
```
| total_revenue | runner_payment | net_profit |
|---------------|----------------|------------|
| 138           | 64.62          | 73.38      |

---
My solution for **[E. Bonus Questions](E.%20Bonus%20Questions.md)**.
