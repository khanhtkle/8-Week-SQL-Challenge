---------------------------------------
-- E. Bonus Questions --
---------------------------------------
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

DROP TABLE IF EXISTS pizza_runner.dbo.pizza_names;
CREATE TABLE pizza_runner.dbo.pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);

INSERT INTO pizza_runner.dbo.pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_runner.dbo.pizza_recipes;
CREATE TABLE pizza_runner.dbo.pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);

INSERT INTO pizza_runner.dbo.pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

INSERT INTO pizza_runner.dbo.pizza_names
  ("pizza_id", "pizza_name")
VALUES 
  (3, 'Supreme');

SELECT * FROM pizza_runner.dbo.pizza_names;

ALTER TABLE pizza_runner.dbo.pizza_recipes
ALTER COLUMN toppings VARCHAR(43);
GO

INSERT INTO pizza_runner.dbo.pizza_recipes(pizza_id, toppings)
VALUES (3, (SELECT STRING_AGG(topping_id, ', ') WITHIN GROUP (ORDER BY topping_id) FROM pizza_runner.dbo.pizza_toppings))

SELECT * FROM pizza_runner.dbo.pizza_recipes;

