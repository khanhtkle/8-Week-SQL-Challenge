--------------------------------------------------
-- C. Data Cleaning: Ingredient Optimisation --
--------------------------------------------------
-- 	Create a table `cleaned_toppings` that includes the `pizza_id`, `topping_id`, and `topping_name` with each distinct topping stored as separate rows.
-- 	Create a table `cleaned_toppings` from `pizza_recipes` and `pizza_toppings` tables:
-- 		- Include the `pizza_id`, `topping_id`, and `topping_name` with each distinct `topping_id` and `topping_name` stored as separate rows.
-- 		- Converts the data type of the value extracted from the nested SUBSTRING_INDEX function for `toppings` from TEXT to UNSIGNED.

DROP TABLE IF EXISTS pizza_runner.cleaned_pizza_recipes;
CREATE TABLE pizza_runner.cleaned_pizza_recipes AS
  (WITH RECURSIVE numbers_cte AS
     (SELECT 1 AS n
      UNION ALL 
      SELECT n + 1
      FROM numbers_cte
      WHERE n < (SELECT COUNT(*)
			FROM pizza_runner.pizza_toppings)),
			topping_id_cte AS
     (SELECT pizza_id,
             CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', n), ',', -1)) AS UNSIGNED) AS topping_id
      FROM pizza_runner.pizza_recipes
      CROSS JOIN numbers_cte
      WHERE CHAR_LENGTH(toppings) - CHAR_LENGTH(REPLACE(toppings, ',', '')) >= n - 1) 
   SELECT pizza_id,
	  ti.topping_id,
	  topping_name
   FROM topping_id_cte AS ti
   LEFT JOIN pizza_runner.pizza_toppings AS pt ON pt.topping_id = ti.topping_id);

SELECT *
FROM pizza_runner.cleaned_pizza_recipes
ORDER BY 1, 2;

-- 	Add a `record_id` column with an AUTO_INCREMENT constraint to generate unique identifiers.
-- 	Note: The ALTER TABLE DROP COLUMN operation might result in Error Code 1091 if the specified column doesn't exist in the table. If this error occurs, proceed without executing the DROP COLUMN operation.

ALTER TABLE pizza_runner.cleaned_customer_orders
DROP COLUMN record_id;

ALTER TABLE pizza_runner.cleaned_customer_orders 
ADD record_id INTEGER AUTO_INCREMENT PRIMARY KEY;

SELECT *
FROM pizza_runner.cleaned_customer_orders;

-- 	Create a table named `extras` from `cleaned_customer_orders` and `pizza_toppings` table:
-- 		- Include the `extras` alongside their respective `record_id`, `topping_name`, and `cancellation`.
-- 		- Converts the data type of the value extracted from the nested SUBSTRING_INDEX function for 'extras' from VARCHAR(4) to UNSIGNED.

DROP TABLE IF EXISTS pizza_runner.extras;
CREATE TABLE pizza_runner.extras AS
  (WITH RECURSIVE numbers_cte AS
     (SELECT 1 AS n
      UNION ALL 
      SELECT n + 1
      FROM numbers_cte
      WHERE n < (SELECT COUNT(*)
			FROM pizza_runner.pizza_toppings)),
			topping_id_cte AS
     (SELECT record_id,
             CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ',', n), ',', -1)) AS UNSIGNED) AS topping_id,
	     cancellation
      FROM pizza_runner.cleaned_customer_orders
      CROSS JOIN numbers_cte
      WHERE CHAR_LENGTH(extras) - CHAR_LENGTH(REPLACE(extras, ',', '')) >= n - 1) 
   SELECT record_id,
	  ti.topping_id,
	  topping_name,
	  cancellation
   FROM topping_id_cte AS ti
   LEFT JOIN pizza_runner.pizza_toppings AS pt ON pt.topping_id = ti.topping_id
   ORDER BY 1, 2);

SELECT *
FROM pizza_runner.extras;

-- 	Create a table named `exclusions` from `cleaned_customer_orders` and `pizza_toppings` table:
-- 		- Include the `extras` alongside their respective `record_id`, `topping_name`, and `cancellation`.
-- 		- Converts the data type of the value extracted from the nested SUBSTRING_INDEX function for 'exclusions' from VARCHAR(4) to UNSIGNED.

DROP TABLE IF EXISTS pizza_runner.exclusions;
CREATE TABLE pizza_runner.exclusions AS
  (WITH RECURSIVE numbers_cte AS
     (SELECT 1 AS n
      UNION ALL 
      SELECT n + 1
      FROM numbers_cte
      WHERE n < (SELECT COUNT(*)
			FROM pizza_runner.pizza_toppings)),
			topping_id_cte AS
     (SELECT record_id,
             CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ',', n), ',', -1)) AS UNSIGNED) AS topping_id,
	     cancellation
      FROM pizza_runner.cleaned_customer_orders
      CROSS JOIN numbers_cte
      WHERE CHAR_LENGTH(exclusions) - CHAR_LENGTH(REPLACE(exclusions, ',', '')) >= n - 1) 
   SELECT record_id,
	  ti.topping_id,
	  topping_name,
	  cancellation
   FROM topping_id_cte AS ti
   LEFT JOIN pizza_runner.pizza_toppings AS pt ON pt.topping_id = ti.topping_id
   ORDER BY 1, 2);

SELECT *
FROM pizza_runner.exclusions;
