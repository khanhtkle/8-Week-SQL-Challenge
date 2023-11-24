-------------------------------------
-- B. Product Funnel Analysis --
-------------------------------------
-- 	1. Which product had the most views, cart adds and purchases?

SELECT pfa1.product_name,
       CASE
           WHEN pfa1.views = (SELECT MAX(views)
							  FROM clique_bait.dbo.product_funnel_analysis) THEN CAST(CONCAT(pfa1.views, ' (most views)') AS VARCHAR)
           ELSE CAST(pfa1.views AS VARCHAR)
       END AS views,
       CASE
           WHEN pfa1.cart_adds = (SELECT MAX(cart_adds)
								  FROM clique_bait.dbo.product_funnel_analysis) THEN CAST(CONCAT(pfa1.cart_adds, ' (most cart_adds)') AS VARCHAR)
           ELSE CAST(pfa1.cart_adds AS VARCHAR)
       END AS cart_adds,
       CASE
           WHEN pfa1.purchases = (SELECT MAX(purchases)
								  FROM clique_bait.dbo.product_funnel_analysis) THEN CAST(CONCAT(pfa1.purchases, ' (most purchases)') AS VARCHAR)
           ELSE CAST(pfa1.purchases AS VARCHAR)
       END AS purchases
FROM clique_bait.dbo.product_funnel_analysis AS pfa1,
     clique_bait.dbo.product_funnel_analysis AS pfa2
WHERE pfa1.product_name = pfa2.product_name AND pfa2.views = (SELECT MAX(views)
															  FROM clique_bait.dbo.product_funnel_analysis)
	  OR pfa1.product_name = pfa2.product_name AND pfa2.cart_adds = (SELECT MAX(cart_adds)
																	 FROM clique_bait.dbo.product_funnel_analysis)
	  OR pfa1.product_name = pfa2.product_name AND pfa2.cart_adds = (SELECT MAX(purchases)
																	 FROM clique_bait.dbo.product_funnel_analysis)
ORDER BY CASE
             WHEN pfa1.views = (SELECT MAX(views)
							    FROM clique_bait.dbo.product_funnel_analysis) THEN CAST(CONCAT(pfa1.views, ' (most views)') AS VARCHAR)
             ELSE CAST(pfa1.views AS VARCHAR)
         END DESC;

-- 	2. Which product was most likely to be abandoned?

SELECT TOP 1 product_name,
	   abandoned, 
       views,
       CAST(100.0 * abandoned / views AS DECIMAL(5,2)) AS abandoned_rate
FROM clique_bait.dbo.product_funnel_analysis
ORDER BY CAST(100.0 * abandoned / views AS DECIMAL(5,2)) DESC;
        
-- 	3. Which product had the highest view to purchase percentage?

SELECT TOP 1 product_name,
	   purchases,
       views,
       CAST(100.0 * purchases / views AS DECIMAL(5,2)) AS view_to_purchase_pct
FROM clique_bait.dbo.product_funnel_analysis
ORDER BY CAST(100.0 * purchases / views AS DECIMAL(5,2)) DESC;

-- 	4. What is the average conversion rate from view to cart add?

SELECT SUM(cart_adds) AS total_cart_adds,
	   SUM(views) AS total_views,
	   CAST(1.0 * SUM(cart_adds) / SUM(views) AS DECIMAL(5,2)) AS view_to_cart_add_conversion_rate
FROM clique_bait.dbo.product_funnel_analysis;

-- 	5. What is the average conversion rate from cart add to purchase?

SELECT SUM(purchases) AS total_purchases,
	   SUM(cart_adds) AS total_cart_adds,
	   CAST(1.0 * SUM(purchases) / SUM(cart_adds) AS DECIMAL(5,2)) AS cart_add_to_purchase_conversion_rate
FROM clique_bait.dbo.product_funnel_analysis;
