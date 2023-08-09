---------------------------------------
-- D. Pricing and Ratings --
---------------------------------------
--	1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes. How much money has Pizza Runner made so far if there are no delivery fees?

SELECT SUM(CASE
               WHEN pizza_id = 1 THEN 12
               ELSE 10
           END) AS total_revenue
FROM pizza_runner.dbo.cleaned_customer_orders AS co
WHERE cancellation IS NULL;

--	2. What if there was an additional $1 charge for any pizza extras?
--		- Add cheese is $1 extra.

SELECT SUM(CASE
               WHEN pizza_id = 1 THEN 12 + LEN(extras) - LEN(REPLACE(extras, ', ', ''))
               ELSE 10 + LEN(extras) - LEN(REPLACE(extras, ', ', ''))
           END) AS total_revenue_with_extras
FROM pizza_runner.dbo.cleaned_customer_orders AS co
WHERE cancellation IS NULL;

--	3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

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

--	4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--		- customer_id
--		- order_id
--		- runner_id
--		- rating
--		- order_time
--		- pickup_time
--		- Time between order and pickup
--		- Delivery duration
--		- Average speed
--		- Total number of pizzas

SELECT customer_id, 
       co.order_id, 
       runner_id,
       rating,
       order_time,
       pickup_time,
       DATEPART(mi, pickup_time - order_time) AS time_between_order_and_pickup,
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

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

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
