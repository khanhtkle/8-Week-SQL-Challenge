-------------------------------------
-- B. Ranking All The Things --
-------------------------------------
-- 	Danny also requires further information about the `ranking` of customer products, but he purposely does not need the `ranking` for non-member purchases so he expects `NULL` values for the records when customers are not yet part of the loyalty program.

-- 	To retrieve the dataset resembling the example outputs:
-- 	- Establish the core by including the `customer_id` and `order_date` from `sales` table.
-- 	- Include `product_name` and `price` from 'menu' alongside their respective 'customer_id' and 'order_date'.
-- 	- Add a column `member`, which siginifies a customer's membership status as `'Y'` when the customer's `order_date` is later than their `join_date` from `member` table, and `'N'` when it's sooner.
-- 	- Add a `ranking` column, which assigns sequential numbers to each customer's orders, with `NULL` values expected for non-member purchases.

SELECT sa.customer_id,
       order_date,
       product_name,
       price,
       CASE
           WHEN order_date < join_date
                OR join_date IS NULL THEN 'N'
           ELSE 'Y'
       END AS member,
       CASE
           WHEN order_date < join_date
                OR join_date IS NULL THEN NULL
           ELSE DENSE_RANK() OVER (PARTITION BY (CASE
                                                     WHEN order_date < join_date
                                                          OR join_date IS NULL THEN NULL
                                                     ELSE sa.customer_id
                                                 END)
                                   ORDER BY order_date)
       END AS ranking
FROM dannys_diner.dbo.sales AS sa
JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
LEFT JOIN dannys_diner.dbo.members AS mb ON mb.customer_id = sa.customer_id
ORDER BY sa.customer_id,
         order_date,
         product_name;
