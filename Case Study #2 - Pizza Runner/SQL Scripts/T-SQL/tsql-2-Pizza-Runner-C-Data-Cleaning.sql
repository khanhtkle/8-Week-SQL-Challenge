--------------------------------------------------
-- C. Data Cleaning: Ingredient Optimisation --
--------------------------------------------------
--	Create a table `cleaned_toppings` from `pizza_recipes` and `pizza_toppings` tables:
--		- Include the `pizza_id`, `topping_id`, and `topping_name` with each distinct `topping_id` and `topping_name` stored as separate rows.
--		- Convert the data type of `toppings` from TEXT to VARCHAR(23).
--		- Convert the data type of the value extracted from the STRING_SPLIT function for `toppings` from VARCHAR(23) to INTEGER.
--		- Convert the data type of `topping_name` from TEXT to VARCHAR(12).

DROP TABLE IF EXISTS pizza_runner.dbo.cleaned_pizza_recipes;
SELECT pizza_id,
       CAST(TRIM(value) AS INTEGER) AS topping_id,
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
ADD record_id INTEGER IDENTITY(1, 1);
GO

SELECT * 
FROM pizza_runner.dbo.cleaned_customer_orders; 

--	Create a table named `extras` from `cleaned_customer_orders` and `pizza_toppings` table:
--		- Include the `extras` alongside their respective `record_id`, `topping_name`, and `cancellation`.
--		- Convert the data type of the value extracted from the STRING_SPLIT function for 'extras' from VARCHAR(4) to INTEGER.
--		- Convert the data type of `topping_name` from TEXT to VARCHAR(12).

DROP TABLE IF EXISTS pizza_runner.dbo.extras;
SELECT record_id,
       CAST(TRIM(ss.value) AS INTEGER) AS topping_id,
       CAST(topping_name AS VARCHAR(12)) AS topping_name,
       cancellation
INTO pizza_runner.dbo.extras
FROM pizza_runner.dbo.cleaned_customer_orders AS co 
CROSS APPLY STRING_SPLIT(extras, ',') AS ss
LEFT JOIN pizza_runner.dbo.pizza_toppings AS pt ON pt.topping_id = TRIM(ss.value);

SELECT *
FROM pizza_runner.dbo.extras;

--	Create a table named `exclusions` from `cleaned_customer_orders` and `pizza_toppings` table:
--		- Include the `exclusions` alongside their respective `record_id`, `topping_name`, and `cancellation`.
--		- Convert the data type of the value extracted from the STRING_SPLIT function for 'exclusions' from VARCHAR(4) to INTEGER.
--		- Convert the data type of `topping_name` from TEXT to VARCHAR(12).

DROP TABLE IF EXISTS pizza_runner.dbo.exclusions;
SELECT record_id,
       CAST(TRIM(ss.value) AS INTEGER) AS topping_id,
       CAST(topping_name AS VARCHAR(12)) AS topping_name,
       cancellation
INTO pizza_runner.dbo.exclusions
FROM pizza_runner.dbo.cleaned_customer_orders AS co 
CROSS APPLY STRING_SPLIT(exclusions, ',') AS ss
LEFT JOIN pizza_runner.dbo.pizza_toppings AS pt ON pt.topping_id = TRIM(ss.value);

SELECT *
FROM pizza_runner.dbo.exclusions;
