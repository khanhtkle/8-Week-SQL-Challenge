# :pizza: Case Study 2 - Pizza Runner

## E. Bonus Questions

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an `INSERT` statement to demonstrate what would happen if a new `Supreme` pizza with all the toppings was added to the Pizza Runner menu?
-  This is how `pizza_name` table changes when adding Supreme pizza to the menu.
```tsql
INSERT INTO pizza_runner.dbo.pizza_names
  ("pizza_id", "pizza_name")
SELECT 3, 'Supreme'
WHERE NOT EXISTS (SELECT 1
                  FROM pizza_runner.dbo.pizza_names
                  WHERE pizza_id = 3);

SELECT *
FROM pizza_runner.dbo.pizza_names;
```
| pizza_id | pizza_name |
|----------|------------|
| 1        | Meatlovers |
| 2        | Vegetarian |
| 3        | Supreme    |

-  This is how `pizza_recipes` table changes when adding Supreme pizza to the menu.
```tsql
INSERT INTO pizza_runner.dbo.pizza_recipes
  ("pizza_id", "toppings")
SELECT 3, (SELECT STRING_AGG(topping_id, ', ') WITHIN GROUP (ORDER BY topping_id)
           FROM pizza_runner.dbo.pizza_toppings)
WHERE NOT EXISTS (SELECT 1
                  FROM pizza_runner.dbo.pizza_recipes
                  WHERE pizza_id = 3);

SELECT *
FROM pizza_runner.dbo.pizza_recipes;
```
| pizza_id | toppings                              |
|----------|---------------------------------------|
| 1        | 1, 2, 3, 4, 5, 6, 8, 10               |
| 2        | 4, 6, 7, 9, 11, 12                    |
| 3        | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 |
