--------------------------------------------------
-- C. Data Cleaning: Ingredient Optimisation
--------------------------------------------------
--	Create a table `cleaned_toppings` from `pizza_recipes` and `pizza_toppings` tables:
--		- Include the `pizza_id`, `topping_id`, and `topping_name` with each distinct `topping_id` and `topping_name` stored as separate rows.
--		- Converts the data type of the value extracted from the UNNEST and STRING_TO_ARRAY function for `toppings` from TEXT to INTEGER.

DROP TABLE IF EXISTS pizza_runner.cleaned_pizza_recipes;
CREATE TABLE pizza_runner.cleaned_pizza_recipes AS
  (WITH topping_id_cte AS
     (SELECT pizza_id,
             TRIM(UNNEST(STRING_TO_ARRAY(toppings, ',')))::INTEGER AS topping_id
      FROM pizza_runner.pizza_recipes) 
   SELECT pizza_id,
	  ti.topping_id,
	  topping_name
   FROM topping_id_cte AS ti
   LEFT JOIN pizza_runner.pizza_toppings AS pt ON pt.topping_id = ti.topping_id
   ORDER BY 1, 2);

SELECT *
FROM pizza_runner.cleaned_pizza_recipes;

-- 	Add a `record_id` column with a SERIAL data type to generate unique identifiers.

ALTER TABLE pizza_runner.cleaned_customer_orders
DROP COLUMN IF EXISTS record_id;

ALTER TABLE pizza_runner.cleaned_customer_orders
ADD record_id SERIAL PRIMARY KEY;

SELECT *
FROM pizza_runner.cleaned_customer_orders;

--	Create a table named `extras` from `cleaned_customer_orders` and `pizza_toppings` table:
--		- Include the `extras` alongside their respective `record_id`, `topping_name`, and `cancellation`.
--		- Converts the data type of the value extracted from the UNNEST and STRING_TO_ARRAY function for `extras` from VARCHAR(4) to INTEGER.

DROP TABLE IF EXISTS pizza_runner.extras;
CREATE TABLE pizza_runner.extras AS
  (WITH topping_id_cte AS
     (SELECT record_id,
             TRIM(UNNEST(STRING_TO_ARRAY(extras, ',')))::INTEGER AS topping_id,
	     cancellation
      FROM pizza_runner.cleaned_customer_orders) 
   SELECT record_id,
	  ti.topping_id,
	  topping_name, 
	  cancellation
   FROM topping_id_cte AS ti
   JOIN pizza_runner.pizza_toppings AS pt ON pt.topping_id = ti.topping_id
   ORDER BY 1, 2);
   
SELECT *
FROM pizza_runner.extras;

--	Create a table named `exclusions` from `cleaned_customer_orders` and `pizza_toppings` table:
--		- Include the `exclusions` alongside their respective `record_id`, `topping_name`, and `cancellation`.
--		- Converts the data type of the value extracted from the UNNEST and STRING_TO_ARRAY function for `exclusions` from VARCHAR(4) to INTEGER.

DROP TABLE IF EXISTS pizza_runner.exclusions;
CREATE TABLE pizza_runner.exclusions AS
  (WITH topping_id_cte AS
     (SELECT record_id,
             TRIM(UNNEST(STRING_TO_ARRAY(exclusions, ',')))::INTEGER AS topping_id,
	     cancellation
      FROM pizza_runner.cleaned_customer_orders) 
   SELECT record_id,
	  ti.topping_id,
	  topping_name,
	  cancellation
   FROM topping_id_cte AS ti
   JOIN pizza_runner.pizza_toppings AS pt ON pt.topping_id = ti.topping_id
   ORDER BY 1, 2);
   
SELECT *
FROM pizza_runner.exclusions;
