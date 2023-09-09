-------------------------------------
-- A. Dining Metrics --
-------------------------------------
 -- 	1. What is the total amount each customer spent at the restaurant?

SELECT customer_id,
       SUM(price) AS total_spent
FROM dannys_diner.sales AS sa
JOIN dannys_diner.menu AS mn ON sa.product_id = mn.product_id
GROUP BY 1;

-- 	2. How many days has each customer visited the restaurant?

SELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_count
FROM dannys_diner.sales
GROUP BY 1;

-- 	3. What was the first item from the menu purchased by each customer?

 WITH order_sequence_cte AS
  (SELECT DISTINCT customer_id,
                   order_date,
                   sa.product_id,
                   product_name,
                   DENSE_RANK() OVER (PARTITION BY customer_id
                                      ORDER BY order_date) AS order_sequence
   FROM dannys_diner.sales AS sa
   JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id)
SELECT customer_id,
       order_date,
       product_name
FROM order_sequence_cte
WHERE order_sequence = 1;

-- 	4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT sa.product_id,
       product_name,
       COUNT(sa.product_id) AS purchase_count
FROM dannys_diner.sales AS sa
JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1;

-- 	5. Which item was the most popular for each customer?

 WITH purchase_count_cte AS
  (SELECT customer_id,
          sa.product_id,
          product_name,
          COUNT(sa.product_id) AS purchase_count,
          DENSE_RANK() OVER (PARTITION BY customer_id
                             ORDER BY COUNT(sa.product_id) DESC) AS purchase_count_rank
   FROM dannys_diner.sales AS sa
   JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
   GROUP BY 1, 2, 3)
SELECT customer_id,
       product_id,
       product_name,
       purchase_count
FROM purchase_count_cte
WHERE purchase_count_rank = 1;

-- 	6. Which item was purchased first by the customer after they became a member?

 WITH order_sequence_after_join_date_cte AS
  (SELECT sa.customer_id,
          join_date,
          order_date,
          sa.product_id,
          product_name,
          DENSE_RANK() OVER (PARTITION BY sa.customer_id
                             ORDER BY order_date) AS order_sequence
   FROM dannys_diner.sales AS sa
   JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
   JOIN dannys_diner.members AS mb ON mb.customer_id = sa.customer_id
   WHERE order_date >= join_date )
SELECT customer_id,
       join_date,
       order_date,
       product_name
FROM order_sequence_after_join_date_cte
WHERE order_sequence = 1;

-- 	7. Which item was purchased just before the customer became a member?

 WITH order_sequence_before_join_date_cte AS
  (SELECT sa.customer_id,
          join_date,
          order_date,
          sa.product_id,
          product_name,
          DENSE_RANK() OVER (PARTITION BY sa.customer_id
                             ORDER BY order_date DESC) AS reverse_order_sequence
   FROM dannys_diner.sales AS sa
   JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
   JOIN dannys_diner.members AS mb ON mb.customer_id = sa.customer_id
   WHERE order_date < join_date )
SELECT customer_id,
       join_date,
       order_date,
       product_name
FROM order_sequence_before_join_date_cte
WHERE reverse_order_sequence = 1;

-- 	8. What is the total items and amount spent for each member before they became a member?

SELECT sa.customer_id,
       COUNT(sa.product_id) AS pre_membership_purchase_count,
       SUM(mn.price) AS pre_membership_total_spent
FROM dannys_diner.sales AS sa
JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
JOIN dannys_diner.members AS mb ON mb.customer_id = sa.customer_id
WHERE order_date < join_date
GROUP BY 1;

-- 	9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
--	Note: Non-member customers also earn points when making purchases.

SELECT sa.customer_id,
       SUM(CASE
               WHEN sa.product_id = 1 THEN price * 10 * 2
               ELSE price * 10
           END) AS total_points
FROM dannys_diner.sales AS sa
JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
GROUP BY 1;

-- 	10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT sa.customer_id,
       SUM(CASE
               WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 1 WEEK)
                    OR sa.product_id = 1 THEN price * 10 * 2
               ELSE price * 10
           END) AS total_points
FROM dannys_diner.sales AS sa
JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
LEFT JOIN dannys_diner.members AS mb ON mb.customer_id = sa.customer_id
GROUP BY 1;
