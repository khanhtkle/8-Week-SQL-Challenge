-------------------------------------
-- B. Product Funnel Analysis --
-------------------------------------
-- 	1. Which product had the most views, cart adds and purchases?

SELECT pfa1.product_name,
       CASE
           WHEN pfa1.views = (SELECT MAX(views)
							  FROM clique_bait.product_funnel_analysis) THEN CONCAT(pfa1.views::VARCHAR, ' (most views)')
           ELSE pfa1.views::VARCHAR
       END AS views,
       CASE
           WHEN pfa1.cart_adds = (SELECT MAX(cart_adds)
								  FROM clique_bait.product_funnel_analysis) THEN CONCAT(pfa1.cart_adds::VARCHAR, ' (most cart_adds)')
           ELSE pfa1.cart_adds::VARCHAR
       END AS cart_adds,
       CASE
           WHEN pfa1.purchases = (SELECT MAX(purchases)
								  FROM clique_bait.product_funnel_analysis) THEN CONCAT(pfa1.purchases::VARCHAR, ' (most purchases)')
           ELSE pfa1.purchases::VARCHAR
       END AS purchases
FROM clique_bait.product_funnel_analysis AS pfa1,
     clique_bait.product_funnel_analysis AS pfa2
WHERE pfa1.product_name = pfa2.product_name AND pfa2.views = (SELECT MAX(views)
															  FROM clique_bait.product_funnel_analysis)
	  OR pfa1.product_name = pfa2.product_name AND pfa2.cart_adds = (SELECT MAX(cart_adds)
																	 FROM clique_bait.product_funnel_analysis)
	  OR pfa1.product_name = pfa2.product_name AND pfa2.cart_adds = (SELECT MAX(purchases)
																	 FROM clique_bait.product_funnel_analysis)
ORDER BY 2 DESC;

-- 	2. Which product was most likely to be abandoned?

SELECT product_name,
	   abandoned, 
       views,
       (100.0 * abandoned / views)::DECIMAL(5,2) AS abandoned_rate
FROM clique_bait.product_funnel_analysis
ORDER BY 4 DESC
LIMIT 1;
        
-- 	3. Which product had the highest view to purchase percentage?

SELECT product_name,
	   purchases,
       views,
       (100.0 * purchases / views)::DECIMAL(5,2) AS view_to_purchase_pct
FROM clique_bait.product_funnel_analysis
ORDER BY 4 DESC
LIMIT 1;

-- 	4. What is the average conversion rate from view to cart add?

SELECT SUM(cart_adds) AS total_cart_adds,
	   SUM(views) AS total_views,
	   (1.0 * SUM(cart_adds) / SUM(views))::DECIMAL(5,2) AS view_to_cart_add_conversion_rate
FROM clique_bait.product_funnel_analysis;

-- 	5. What is the average conversion rate from cart add to purchase?

SELECT SUM(purchases) AS total_purchases,
	   SUM(cart_adds) AS total_cart_adds,
	   (1.0 * SUM(purchases) / SUM(cart_adds))::DECIMAL(5,2) AS cart_add_to_purchase_conversion_rate
FROM clique_bait.product_funnel_analysis;
