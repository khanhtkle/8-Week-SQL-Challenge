-------------------------------------------
-- C. Ingredient Optimisation --
-------------------------------------------
-- 	1. What are the standard ingredients for each pizza?

SELECT pn.pizza_id, 
       pizza_name, 
       GROUP_CONCAT(topping_name SEPARATOR ', ') AS standard_ingredients
FROM pizza_runner.pizza_names AS pn 
JOIN pizza_runner.cleaned_pizza_recipes AS pr ON pr.pizza_id = pn.pizza_id
GROUP BY 1, 2;

-- 	2. What was the most commonly added extra?

WITH ordered_extras_count_cte AS
  (SELECT topping_name,
          COUNT(record_id) AS ordered_extras_count,
          DENSE_RANK() OVER (ORDER BY COUNT(record_id) DESC) AS ranking
   FROM pizza_runner.extras
   GROUP BY 1)
SELECT topping_name,
       ordered_extras_count
FROM ordered_extras_count_cte
WHERE ranking = 1;

-- 	3. What was the most common exclusion?

WITH ordered_exclusions_count_cte AS
  (SELECT topping_name,
          COUNT(record_id) AS ordered_exclusions_count,
          DENSE_RANK() OVER (ORDER BY COUNT(record_id) DESC) AS ranking
   FROM pizza_runner.exclusions
   GROUP BY 1)
SELECT topping_name,
       ordered_exclusions_count
FROM ordered_exclusions_count_cte
WHERE ranking = 1;

-- 	4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:
--  		- Meat Lovers
--  		- Meat Lovers - Exclude Beef
--  		- Meat Lovers - Extra Bacon
--  		- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH extra_format_cte AS
  (SELECT record_id,
          CONCAT('Extra ', GROUP_CONCAT(topping_name SEPARATOR ', ')) AS extra_format
   FROM pizza_runner.extras
   GROUP BY 1),
     exclude_format_cte AS
  (SELECT record_id,
          CONCAT('Exclude ', GROUP_CONCAT(topping_name SEPARATOR ', ')) AS exclude_format
   FROM pizza_runner.exclusions
   GROUP BY 1)
SELECT co.record_id,
       order_id,
       customer_id,
       co.pizza_id,
       exclusions,
       extras,
       CONCAT_WS(' - ', pizza_name, exclude_format, extra_format) AS order_item_description,
       order_time
FROM pizza_runner.cleaned_customer_orders AS co
LEFT JOIN pizza_runner.pizza_names AS pn ON pn.pizza_id = co.pizza_id
LEFT JOIN extra_format_cte AS et ON et.record_id = co.record_id
LEFT JOIN exclude_format_cte AS ec ON ec.record_id = co.record_id;

-- 	5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a '2x' in front of any relevant ingredients
-- 		- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH ingredients_cte AS
  (SELECT co.record_id,
          order_id,
          customer_id,
          co.pizza_id,
          pn.pizza_name,
          extras,
          exclusions,
          pr.topping_id,
          CASE
              WHEN pr.topping_id = et.topping_id THEN CONCAT('x2', pr.topping_name)
              ELSE pr.topping_name
          END AS ingredients,
          order_time
   FROM pizza_runner.cleaned_customer_orders AS co
   LEFT JOIN pizza_runner.pizza_names AS pn ON pn.pizza_id = co.pizza_id
   LEFT JOIN pizza_runner.cleaned_pizza_recipes AS pr ON pr.pizza_id = co.pizza_id
   LEFT JOIN pizza_runner.extras AS et ON et.record_id = co.record_id
   				      AND et.topping_id = pr.topping_id)
SELECT record_id,
       order_id,
       customer_id,
       pizza_id,
       extras,
       exclusions,
       CONCAT(pizza_name, ': ', GROUP_CONCAT(ingredients ORDER BY topping_id SEPARATOR ', ')) AS ingredient_list,
       order_time
FROM ingredients_cte AS ig
WHERE ingredients NOT IN (SELECT topping_name
			  FROM pizza_runner.exclusions AS ec
			  WHERE ec.record_id = ig.record_id)
GROUP BY 1, 2, 3, 4, 5, 6, pizza_name, 8;

-- 	6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH ingredients_cte AS
  (SELECT record_id,
          topping_id,
          topping_name
   FROM pizza_runner.extras
   WHERE cancellation IS NULL
   UNION ALL 
   SELECT record_id,
	  topping_id,
	  topping_name
   FROM pizza_runner.cleaned_customer_orders AS co
   LEFT JOIN pizza_runner.cleaned_pizza_recipes AS pr ON pr.pizza_id = co.pizza_id
   WHERE topping_id NOT IN (SELECT topping_id
			    FROM pizza_runner.exclusions AS ec
			    WHERE ec.record_id = co.record_id)
     AND cancellation IS NULL),
     total_quantity_cte AS
  (SELECT topping_name,
          COUNT(record_id) AS total_quantity,
          DENSE_RANK() OVER (ORDER BY COUNT(record_id) DESC) AS ranking
   FROM ingredients_cte
   GROUP BY 1)
SELECT topping_name,
       total_quantity
FROM total_quantity_cte
WHERE ranking = 1;
