---------------------------------------
-- E. Bonus Questions --
---------------------------------------
--     If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
--     This is how `pizza_name` table changes when adding Supreme pizza to the menu.

INSERT INTO pizza_runner.dbo.pizza_names
  ("pizza_id", "pizza_name")
SELECT 3, 'Supreme'
WHERE NOT EXISTS (SELECT 1
                  FROM pizza_runner.dbo.pizza_names
                  WHERE pizza_id = 3);

SELECT * 
FROM pizza_runner.dbo.pizza_names;

--     This is how `pizza_recipes` table changes when adding Supreme pizza to the menu.
    
INSERT INTO pizza_runner.dbo.pizza_recipes
  ("pizza_id", "toppings")
SELECT 3, (SELECT STRING_AGG(topping_id, ', ') WITHIN GROUP (ORDER BY topping_id)
           FROM pizza_runner.dbo.pizza_toppings)
WHERE NOT EXISTS (SELECT 1
                  FROM pizza_runner.dbo.pizza_recipes
                  WHERE pizza_id = 3);

SELECT * 
FROM pizza_runner.dbo.pizza_recipes;
