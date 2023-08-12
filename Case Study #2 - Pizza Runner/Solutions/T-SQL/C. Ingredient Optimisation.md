# :pizza: Case Study 2 - Pizza Runner

## C. Ingredient Optimisation

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Data Cleaning

1. Create a table `cleaned_toppings` from `pizza_recipes` and `pizza_toppings` tables:
    - Include the `pizza_id`, `topping_id`, and `topping_name` with each distinct `topping_id` and `topping_name` stored as separate rows.
    - Convert the data type of `toppings` from `TEXT` to `VARCHAR(23)`.
    - Converts the data type of the value extracted from the `STRING_SPLIT` function for `toppings` from `VARCHAR(23)` to `INTEGER`.
    - Convert the data type of `topping_name` from `TEXT` to `VARCHAR(12)`.
```tsql
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
  ```
| pizza_id | topping_id | topping_name |
|----------|------------|--------------|
| 1        | 1          | Bacon        |
| 1        | 2          | BBQ Sauce    |
| 1        | 3          | Beef         |
| 1        | 4          | Cheese       |
| 1        | 5          | Chicken      |
| 1        | 6          | Mushrooms    |
| 1        | 8          | Pepperoni    |
| 1        | 10         | Salami       |
| 2        | 4          | Cheese       |
| 2        | 6          | Mushrooms    |
| 2        | 7          | Onions       |
| 2        | 9          | Peppers      |
| 2        | 11         | Tomatoes     |
| 2        | 12         | Tomato Sauce |

2. Add a `record_id` column with an `IDENTITY` constraint to generate unique identifiers.
```tsql
ALTER TABLE pizza_runner.dbo.cleaned_customer_orders
DROP COLUMN IF EXISTS record_id;
GO

ALTER TABLE pizza_runner.dbo.cleaned_customer_orders 
ADD record_id INTEGER IDENTITY(1, 1);
GO

SELECT *
FROM pizza_runner.dbo.cleaned_customer_orders; 
```
| order_id | customer_id | pizza_id | exclusions | extras | order_time          | cancellation            | record_id |
|----------|-------------|----------|------------|--------|---------------------|-------------------------|-----------|
| 1        | 101         | 1        | NULL       | NULL   | 2021-01-01 18:05:02 | NULL                    | 1         |
| 2        | 101         | 1        | NULL       | NULL   | 2021-01-01 19:00:52 | NULL                    | 2         |
| 3        | 102         | 1        | NULL       | NULL   | 2021-01-02 23:51:23 | NULL                    | 3         |
| 3        | 102         | 2        | NULL       | NULL   | 2021-01-02 23:51:23 | NULL                    | 4         |
| 4        | 103         | 1        | 4          | NULL   | 2021-01-04 13:23:46 | NULL                    | 5         |
| 4        | 103         | 1        | 4          | NULL   | 2021-01-04 13:23:46 | NULL                    | 6         |
| 4        | 103         | 2        | 4          | NULL   | 2021-01-04 13:23:46 | NULL                    | 7         |
| 5        | 104         | 1        | NULL       | 1      | 2021-01-08 21:00:29 | NULL                    | 8         |
| 6        | 101         | 2        | NULL       | NULL   | 2021-01-08 21:03:13 | Restaurant Cancellation | 9         |
| 7        | 105         | 2        | NULL       | 1      | 2021-01-08 21:20:29 | NULL                    | 10        |
| 8        | 102         | 1        | NULL       | NULL   | 2021-01-09 23:54:33 | NULL                    | 11        |
| 9        | 103         | 1        | 4          | 1, 5   | 2021-01-10 11:22:59 | Customer Cancellation   | 12        |
| 10       | 104         | 1        | NULL       | NULL   | 2021-01-11 18:34:49 | NULL                    | 13        |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2021-01-11 18:34:49 | NULL                    | 14        |

3. Create a table named `extras` from `cleaned_customer_orders` and `pizza_toppings` table:
    -  Include the `extras` alongside their respective `record_id`, `topping_name`, and `cancellation`.
    -  Converts the data type of the value extracted from the `STRING_SPLIT` function for 'extras' from `VARCHAR(4)` to `INTEGER`.
    -  Convert the data type of `topping_name` from `TEXT` to `VARCHAR(12)`.
```tsql
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
```
| record_id | topping_id | topping_name | cancellation          |
|-----------|------------|--------------|-----------------------|
| 8         | 1          | Bacon        | NULL                  |
| 10        | 1          | Bacon        | NULL                  |
| 12        | 1          | Bacon        | Customer Cancellation |
| 12        | 5          | Chicken      | Customer Cancellation |
| 14        | 1          | Bacon        | NULL                  |
| 14        | 4          | Cheese       | NULL                  |

4. Create a table named `exclusions` from `cleaned_customer_orders` and `pizza_toppings` table:
    - Include the `exclusions` alongside their respective `record_id`, `topping_name`, and `cancellation`.
    - Converts the data type of the value extracted from the `STRING_SPLIT` function for 'exclusions' from `VARCHAR(4)` to `INTEGER`.
    - Convert the data type of `topping_name` from `TEXT` to `VARCHAR(12)`.
```tsql
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
```
| record_id | topping_id | topping_name | cancellation          |
|-----------|------------|--------------|-----------------------|
| 5         | 4          | Cheese       | NULL                  |
| 6         | 4          | Cheese       | NULL                  |
| 7         | 4          | Cheese       | NULL                  |
| 12        | 4          | Cheese       | Customer Cancellation |
| 14        | 2          | BBQ Sauce    | NULL                  |
| 14        | 6          | Mushrooms    | NULL                  |

--- 
### Q1. What are the standard ingredients for each pizza?
```tsql
SELECT	pn.pizza_id,
        pizza_name,
        STRING_AGG(topping_name, ', ') AS standard_ingredients
FROM pizza_runner.dbo.pizza_names AS pn 
JOIN pizza_runner.dbo.cleaned_pizza_recipes AS pr ON pr.pizza_id =  pn.pizza_id
GROUP BY pn.pizza_id,
         pizza_name;
```
| pizza_id | pizza_name | standard_ingredients                                                  |
|----------|------------|-----------------------------------------------------------------------|
| 1        | Meatlovers | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2        | Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce            |

---
### Q2. What was the most commonly added extra?
```tsql
WITH ordered_extras_count_cte AS
  (SELECT topping_name,
          COUNT(record_id) AS ordered_extras_count,
          DENSE_RANK() OVER (ORDER BY COUNT(record_id) DESC) AS ranking
   FROM pizza_runner.dbo.extras
   GROUP BY topping_name)
SELECT topping_name,
       ordered_extras_count
FROM ordered_extras_count_cte
WHERE ranking = 1;
```
| topping_name | ordered_extras_count |
|--------------|----------------------|
| Bacon        | 4                    |

---
### Q3. What was the most common exclusion?
```tsql
WITH ordered_exclusions_count_cte AS
  (SELECT topping_name,
          COUNT(record_id) AS ordered_exclusions_count,
          DENSE_RANK() OVER (ORDER BY COUNT(record_id) DESC) AS ranking
   FROM pizza_runner.dbo.exclusions
   GROUP BY topping_name)
SELECT topping_name,
       ordered_exclusions_count
FROM ordered_exclusions_count_cte
WHERE ranking = 1;
```
| topping_name | ordered_exclusions_count |
|--------------|--------------------------|
| Cheese       | 4                        |

---
### 4. Generate an order item for each record in the `customers_orders` table in the format of one of the following: {Meat Lovers} {Meat Lovers - Exclude Beef} {Meat Lovers - Extra Bacon} {Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers}
```tsql
WITH extra_format_cte AS
  (SELECT record_id,
          CONCAT('Extra ', STRING_AGG(topping_name, ', ')) AS extra_format
   FROM pizza_runner.dbo.extras
   GROUP BY record_id),
     exclude_format_cte AS
  (SELECT record_id,
          CONCAT('Exclude ', STRING_AGG(topping_name, ', ')) AS exclude_format
   FROM pizza_runner.dbo.exclusions
   GROUP BY record_id)
SELECT co.record_id,
       order_id,
       customer_id,
       co.pizza_id,
       exclusions,
       extras,
       CONCAT_WS(' - ', pizza_name, exclude_format, extra_format) AS order_item_description,
       order_time
FROM pizza_runner.dbo.cleaned_customer_orders AS co
LEFT JOIN pizza_runner.dbo.pizza_names AS pn ON pn.pizza_id = co.pizza_id
LEFT JOIN extra_format_cte AS et ON et.record_id = co.record_id
LEFT JOIN exclude_format_cte AS ec ON ec.record_id = co.record_id;
```
| record_id | order_id | customer_id | pizza_id | exclusions | extras | order_item_description                                          | order_time          |
|-----------|----------|-------------|----------|------------|--------|-----------------------------------------------------------------|---------------------|
| 1         | 1        | 101         | 1        | NULL       | NULL   | Meatlovers                                                      | 2021-01-01 18:05:02 |
| 2         | 2        | 101         | 1        | NULL       | NULL   | Meatlovers                                                      | 2021-01-01 19:00:52 |
| 3         | 3        | 102         | 1        | NULL       | NULL   | Meatlovers                                                      | 2021-01-02 23:51:23 |
| 4         | 3        | 102         | 2        | NULL       | NULL   | Vegetarian                                                      | 2021-01-02 23:51:23 |
| 5         | 4        | 103         | 1        | 4          | NULL   | Meatlovers - Exclude Cheese                                     | 2021-01-04 13:23:46 |
| 6         | 4        | 103         | 1        | 4          | NULL   | Meatlovers - Exclude Cheese                                     | 2021-01-04 13:23:46 |
| 7         | 4        | 103         | 2        | 4          | NULL   | Vegetarian - Exclude Cheese                                     | 2021-01-04 13:23:46 |
| 8         | 5        | 104         | 1        | NULL       | 1      | Meatlovers - Extra Bacon                                        | 2021-01-08 21:00:29 |
| 9         | 6        | 101         | 2        | NULL       | NULL   | Vegetarian                                                      | 2021-01-08 21:03:13 |
| 10        | 7        | 105         | 2        | NULL       | 1      | Vegetarian - Extra Bacon                                        | 2021-01-08 21:20:29 |
| 11        | 8        | 102         | 1        | NULL       | NULL   | Meatlovers                                                      | 2021-01-09 23:54:33 |
| 12        | 9        | 103         | 1        | 4          | 1, 5   | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              | 2021-01-10 11:22:59 |
| 13        | 10       | 104         | 1        | NULL       | NULL   | Meatlovers                                                      | 2021-01-11 18:34:49 |
| 14        | 10       | 104         | 1        | 2, 6       | 1, 4   | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese | 2021-01-11 18:34:49 |

---
### Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a `'2x'` in front of any relevant ingredients. {For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"}
```tsql
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
   FROM pizza_runner.dbo.cleaned_customer_orders AS co
   LEFT JOIN pizza_runner.dbo.pizza_names AS pn ON pn.pizza_id = co.pizza_id
   LEFT JOIN pizza_runner.dbo.cleaned_pizza_recipes AS pr ON pr.pizza_id = co.pizza_id
   LEFT JOIN pizza_runner.dbo.extras AS et ON et.record_id = co.record_id
                                          AND et.topping_id = pr.topping_id)
SELECT record_id,
       order_id,
       customer_id,
       pizza_id,
       extras,
       exclusions,
       CONCAT(pizza_name, ': ', STRING_AGG(ingredients, ', ') WITHIN GROUP (ORDER BY topping_id)) AS ingredient_list,
       order_time
FROM ingredients_cte AS ig
WHERE ingredients NOT IN (SELECT topping_name
                          FROM pizza_runner.dbo.exclusions AS ec
                          WHERE ec.record_id = ig.record_id)
GROUP BY record_id,
         order_id,
         customer_id,
         pizza_id,
         extras,
         exclusions,
         pizza_name,
         order_time;
```
| record_id | order_id | customer_id | pizza_id | extras | exclusions | ingredient_list                                                                     | order_time          |
|-----------|----------|-------------|----------|--------|------------|-------------------------------------------------------------------------------------|---------------------|
| 1         | 1        | 101         | 1        | NULL   | NULL       | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   | 2021-01-01 18:05:02 |
| 2         | 2        | 101         | 1        | NULL   | NULL       | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   | 2021-01-01 19:00:52 |
| 3         | 3        | 102         | 1        | NULL   | NULL       | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   | 2021-01-02 23:51:23 |
| 4         | 3        | 102         | 2        | NULL   | NULL       | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce              | 2021-01-02 23:51:23 |
| 5         | 4        | 103         | 1        | NULL   | 4          | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           | 2021-01-04 13:23:46 |
| 6         | 4        | 103         | 1        | NULL   | 4          | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           | 2021-01-04 13:23:46 |
| 7         | 4        | 103         | 2        | NULL   | 4          | Vegetarian: Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce                      | 2021-01-04 13:23:46 |
| 8         | 5        | 104         | 1        | 1      | NULL       | Meatlovers: x2Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami | 2021-01-08 21:00:29 |
| 9         | 6        | 101         | 2        | NULL   | NULL       | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce              | 2021-01-08 21:03:13 |
| 10        | 7        | 105         | 2        | 1      | NULL       | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce              | 2021-01-08 21:20:29 |
| 11        | 8        | 102         | 1        | NULL   | NULL       | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   | 2021-01-09 23:54:33 |
| 12        | 9        | 103         | 1        | 1, 5   | 4          | Meatlovers: x2Bacon, BBQ Sauce, Beef, x2Chicken, Mushrooms, Pepperoni, Salami       | 2021-01-10 11:22:59 |
| 13        | 10       | 104         | 1        | NULL   | NULL       | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   | 2021-01-11 18:34:49 |
| 14        | 10       | 104         | 1        | 1, 4   | 2, 6       | Meatlovers: x2Bacon, Beef, x2Cheese, Chicken, Pepperoni, Salami                     | 2021-01-11 18:34:49 |

---
### Q6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```tsql
WITH ingredients_cte AS
  (SELECT record_id,
          topping_id,
          topping_name
   FROM pizza_runner.dbo.extras
   WHERE cancellation IS NULL
   UNION ALL 
   SELECT record_id,
          topping_id,
          topping_name
   FROM pizza_runner.dbo.cleaned_customer_orders AS co
   LEFT JOIN pizza_runner.dbo.cleaned_pizza_recipes AS pr ON pr.pizza_id = co.pizza_id
   WHERE topping_id NOT IN (SELECT topping_id
                            FROM pizza_runner.dbo.exclusions AS ec
                            WHERE ec.record_id = co.record_id)
     AND cancellation IS NULL),
     total_quantity_cte AS
  (SELECT topping_name,
          COUNT(record_id) AS total_quantity,
          DENSE_RANK() OVER (ORDER BY COUNT(record_id) DESC) AS ranking
   FROM ingredients_cte
   GROUP BY topping_name)
SELECT topping_name,
       total_quantity
FROM total_quantity_cte
WHERE ranking = 1;
```
| topping_name | total_quantity |
|--------------|----------------|
| Bacon        | 12             |

---
My solution for **[D. Pricing and Ratings](D.%20Pricing%20and%20Ratings.md)**.
