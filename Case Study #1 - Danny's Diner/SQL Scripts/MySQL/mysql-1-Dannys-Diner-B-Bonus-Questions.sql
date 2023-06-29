-------------------------------------
-- B. Bonus Question --
-------------------------------------
-- 1. Join All The Things
SELECT	
	sa.customer_id, 
	order_date, 
	product_name, 
	price,
	CASE WHEN order_date < join_date OR join_date IS NULL THEN 'N' ELSE 'Y' END AS member
FROM
	dannys_diner.sales AS sa
			JOIN 
	dannys_diner.menu AS mn ON mn.product_id = sa.product_id
			LEFT JOIN
	dannys_diner.members AS mb ON mb.customer_id = sa.customer_id
ORDER BY 
	sa.customer_id, order_date, product_name;


-- 	2. Rank All The Things

SELECT 
	sa.customer_id, 
	order_date, 
	product_name, 
	price, 
	CASE WHEN order_date < join_date OR join_date IS NULL THEN 'N' ELSE 'Y' END AS member, 
	CASE WHEN order_date < join_date OR join_date IS NULL THEN NULL 
		 ELSE DENSE_RANK() OVER (PARTITION BY (
									CASE WHEN order_date < join_date OR join_date IS NULL THEN NULL ELSE sa.customer_id END
													) ORDER BY order_date) END AS ranking 
FROM
	dannys_diner.sales AS sa
			JOIN	
	dannys_diner.menu AS mn ON mn.product_id = sa.product_id
			LEFT JOIN
	dannys_diner.members AS mb ON mb.customer_id = sa.customer_id
ORDER BY 
	sa.customer_id, order_date, product_name;