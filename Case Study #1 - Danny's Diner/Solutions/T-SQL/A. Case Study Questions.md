# :ramen: Case Study 1 - Danny's Diner 

## A. Case Study Questions 

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Q1. What is the total amount each customer spent at the restaurant?
```tsql
SELECT customer_id,
       SUM(price) AS total_spent
FROM dannys_diner.dbo.sales AS sa
JOIN dannys_diner.dbo.menu AS mn ON sa.product_id = mn.product_id
GROUP BY customer_id;
```
| customer_id | total_spent |
|-------------|-------------|
| A           | 76          |
| B           | 74          |
| C           | 36          |

---
### Q2. How many days has each customer visited the restaurant?
```tsql
SELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_count
FROM dannys_diner.dbo.sales
GROUP BY customer_id;
```
| customer_id | visit_count |
|-------------|-------------|
| A           | 4           |
| B           | 6           |
| C           | 2           |

---
### Q3. What was the first item from the menu purchased by each customer?
```tsql
 WITH order_sequence_cte AS
  (SELECT DISTINCT customer_id,
                   order_date,
                   sa.product_id,
                   product_name,
                   DENSE_RANK() OVER (PARTITION BY customer_id
                                      ORDER BY order_date) AS order_sequence
   FROM dannys_diner.dbo.sales AS sa
   JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id)
SELECT customer_id,
       order_date,
       product_name
FROM order_sequence_cte
WHERE order_sequence = 1;
```
| customer_id | order_date | product_name |
|-------------|------------|--------------|
| A           | 2021-01-01 | sushi        |
| A           | 2021-01-01 | curry        |
| B           | 2021-01-01 | curry        |
| C           | 2021-01-01 | ramen        |

---
### Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```tsql
SELECT TOP 1 sa.product_id,
           product_name,
           COUNT(sa.product_id) AS purchase_count
FROM dannys_diner.dbo.sales AS sa
JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
GROUP BY sa.product_id,
         product_name
ORDER BY purchase_count DESC;
```
| product_id | product_name | purchase_count |
|------------|--------------|----------------|
| 3          | ramen        | 8              |

---
### Q5. Which item was the most popular for each customer?
```tsql
WITH purchase_count_cte AS
  (SELECT customer_id,
          sa.product_id,
          product_name,
          COUNT(sa.product_id) AS purchase_count,
          DENSE_RANK() OVER (PARTITION BY customer_id
                             ORDER BY COUNT(sa.product_id) DESC) AS purchase_count_rank
   FROM dannys_diner.dbo.sales AS sa
   JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
   GROUP BY customer_id,
            sa.product_id,
            product_name)
SELECT customer_id,
       product_id,
       product_name,
       purchase_count
FROM purchase_count_cte
WHERE purchase_count_rank = 1;
```
| customer_id | product_id | product_name | purchase_count |
|-------------|------------|--------------|----------------|
| A           | 3          | ramen        | 3              |
| B           | 1          | sushi        | 2              |
| B           | 2          | curry        | 2              |
| B           | 3          | ramen        | 2              |
| C           | 3          | ramen        | 3              |

---
### Q6. Which item was purchased first by the customer after they became a member?
```tsql
WITH order_sequence_after_join_date_cte AS
  (SELECT sa.customer_id,
          join_date,
          order_date,
          sa.product_id,
          product_name,
          DENSE_RANK() OVER (PARTITION BY sa.customer_id
                             ORDER BY order_date) AS order_sequence
   FROM dannys_diner.dbo.sales AS sa
   JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
   JOIN dannys_diner.dbo.members AS mb ON mb.customer_id = sa.customer_id
   WHERE order_date >= join_date )
SELECT customer_id,
       join_date,
       order_date,
       product_name
FROM order_sequence_after_join_date_cte
WHERE order_sequence = 1;
```
| customer_id | join_date  | order_date | product_name |
|-------------|------------|------------|--------------|
| A           | 2021-01-07 | 2021-01-07 | curry        |
| B           | 2021-01-09 | 2021-01-11 | sushi        |

---
### Q7. Which item was purchased just before the customer became a member?
```tsql
WITH order_sequence_before_join_date_cte AS
  (SELECT sa.customer_id,
          join_date,
          order_date,
          sa.product_id,
          product_name,
          DENSE_RANK() OVER (PARTITION BY sa.customer_id
                             ORDER BY order_date DESC) AS reverse_order_sequence
   FROM dannys_diner.dbo.sales AS sa
   JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
   JOIN dannys_diner.dbo.members AS mb ON mb.customer_id = sa.customer_id
   WHERE order_date < join_date )
SELECT customer_id,
       join_date,
       order_date,
       product_name
FROM order_sequence_before_join_date_cte
WHERE reverse_order_sequence = 1;
```
| customer_id | join_date  | order_date | product_name |
|-------------|------------|------------|--------------|
| A           | 2021-01-07 | 2021-01-01 | sushi        |
| A           | 2021-01-07 | 2021-01-01 | curry        |
| B           | 2021-01-09 | 2021-01-04 | sushi        |

---
### Q8. What is the total items and amount spent for each member before they became a member?
```tsql
SELECT sa.customer_id,
       COUNT(sa.product_id) AS pre_membership_purchase_count,
       SUM(mn.price) AS pre_membership_total_spent
FROM dannys_diner.dbo.sales AS sa
JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
JOIN dannys_diner.dbo.members AS mb ON mb.customer_id = sa.customer_id
WHERE order_date < join_date
GROUP BY sa.customer_id;
```
| customer_id | pre_membership_purchase_count | pre_membership_total_spent |
|-------------|-------------------------------|----------------------------|
| A           | 2                             | 25                         |
| B           | 3                             | 40                         |

---
### Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
Note: Non-member customers also earn points when making purchases.
```tsql
SELECT sa.customer_id,
       SUM(CASE
               WHEN sa.product_id = 1 THEN price * 10 * 2
               ELSE price * 10
           END) AS total_points
FROM dannys_diner.dbo.sales AS sa
JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
GROUP BY sa.customer_id;
```
| customer_id | total_points |
|-------------|--------------|
| A           | 860          |
| B           | 940          |
| C           | 360          |

--- 
### Q10. In the first week after a customer joins the program (including their join date), they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```tsql
SELECT sa.customer_id,
       SUM(CASE
               WHEN order_date BETWEEN join_date AND DATEADD(wk, 1, join_date)
                    OR sa.product_id = 1 THEN price * 10 * 2
               ELSE price * 10
           END) AS total_points
FROM dannys_diner.dbo.sales AS sa
JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
LEFT JOIN dannys_diner.dbo.members AS mb ON mb.customer_id = sa.customer_id
GROUP BY sa.customer_id;
```
| customer_id | total_points |
|-------------|--------------|
| A           | 1370         |
| B           | 1060         |
| C           | 360          |

---
My solution for **[B. Bonus Questions](B.%20Bonus%20Questions.md)**.
