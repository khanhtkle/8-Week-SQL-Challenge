--------------------------------------------------
-- C. Data Cleaning: Ingredient Optimisation --
--------------------------------------------------
--	Create a table `cleaned_toppings` that includes the `pizza_id`, `topping_id`, and `topping_name` with each distinct topping stored as separate rows.
--	Convert the data type of `topping_name` from TEXT to VARCHAR(12) for broader compatibility with table-valued functions and to prevent potential errors.

DROP TABLE IF EXISTS pizza_runner.dbo.cleaned_pizza_recipes;
SELECT pizza_id,
       CAST(TRIM(value) AS INT) AS topping_id,
       CAST(topping_name AS VARCHAR(12)) AS topping_name
INTO pizza_runner.dbo.cleaned_pizza_recipes
FROM pizza_runner.dbo.pizza_recipes AS pr 
CROSS APPLY STRING_SPLIT(CAST(toppings AS VARCHAR(23)), ',') AS ss
LEFT JOIN pizza_runner.dbo.pizza_toppings AS pt ON pt.topping_id = TRIM(ss.value);

SELECT *
FROM pizza_runner.dbo.cleaned_pizza_recipes;

--	Add a `record_id` column with an IDENTITY constraint to generate unique identifiers.

ALTER TABLE pizza_runner.dbo.cleaned_customer_orders
DROP COLUMN IF EXISTS record_id;
GO

ALTER TABLE pizza_runner.dbo.cleaned_customer_orders 
ADD record_id INT IDENTITY(1, 1);
GO

SELECT * FROM pizza_runner.dbo.cleaned_customer_orders; 

--	Create a table named `extras` to extract and store the values from the extras column of `cleaned_customer_orders` table alongside their respective `record_id and `topping_name`.

DROP TABLE IF EXISTS pizza_runner.dbo.extras;
SELECT record_id,
       CAST(TRIM(ss.value) AS INT) AS topping_id,
	   CAST(topping_name AS VARCHAR(12)) AS topping_name,
	   cancellation
INTO pizza_runner.dbo.extras
FROM pizza_runner.dbo.cleaned_customer_orders AS co 
CROSS APPLY STRING_SPLIT(extras, ',') AS ss
LEFT JOIN pizza_runner.dbo.pizza_toppings AS pt ON pt.topping_id = TRIM(ss.value);

SELECT *
FROM pizza_runner.dbo.extras;

--	Create a table named `exclusions` to extract and store the values from the `extras` column of `cleaned_customer_orders` table alongside their respective `record_id`and `topping_name`.

DROP TABLE IF EXISTS pizza_runner.dbo.exclusions;
SELECT record_id,
       CAST(TRIM(ss.value) AS INT) AS topping_id,
	   CAST(topping_name AS VARCHAR(12)) AS topping_name,
	   cancellation
INTO pizza_runner.dbo.exclusions
FROM pizza_runner.dbo.cleaned_customer_orders AS co 
CROSS APPLY STRING_SPLIT(exclusions, ',') AS ss
LEFT JOIN pizza_runner.dbo.pizza_toppings AS pt ON pt.topping_id = TRIM(ss.value);

SELECT *
FROM pizza_runner.dbo.exclusions;
