-----------------------------------------------------
-- B. Data Cleaning: Product Funnel Analysis --
-----------------------------------------------------
-- 	Create a new output table which has the following details:
-- 		- How many times was each product viewed?
-- 		- How many times was each product added to cart?
-- 		- How many times was each product added to a cart but not purchased (abandoned)?
-- 		- How many times was each product purchased?
-- 	Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

DROP TABLE IF EXISTS clique_bait.product_funnel_analysis;
CREATE TABLE clique_bait.product_funnel_analysis AS
  (WITH final_page_id_cte AS
     (SELECT product_id,
             page_name AS product_name,
             ev.page_id,
             ev.event_type,
             MAX(ev.page_id) OVER (PARTITION BY visit_id) AS final_page_id_per_visit_id
      FROM clique_bait.events AS ev
      JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
      JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id) 
   SELECT product_id,
		  product_name,
          SUM(CASE
				  WHEN event_type = 1 THEN 1
                  ELSE 0
			  END) AS views,
		  SUM(CASE
				  WHEN event_type = 2 THEN 1
                  ELSE 0
			  END) AS cart_adds,
		  SUM(CASE
				  WHEN event_type = 2 
					   AND (final_page_id_per_visit_id != 13 
							OR final_page_id_per_visit_id IS NULL) THEN 1
				  ELSE 0
			  END) AS abandoned,
		  SUM(CASE
                  WHEN event_type = 2
                       AND final_page_id_per_visit_id = 13 THEN 1
				  ELSE 0
			  END) AS purchases
   FROM final_page_id_cte
   WHERE product_id IS NOT NULL
   GROUP BY 1, 2
   ORDER BY 1);
   
SELECT *
FROM  clique_bait.product_funnel_analysis;


DROP TABLE IF EXISTS clique_bait.category_funnel_analysis;
CREATE TABLE clique_bait.category_funnel_analysis AS
  (WITH final_page_id_cte AS
     (SELECT product_category,
             ev.page_id,
             ev.event_type,
             MAX(ev.page_id) OVER (PARTITION BY visit_id) AS final_page_id_per_visit_id
      FROM clique_bait.events AS ev
      JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
      JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id) 
   SELECT product_category,
		  SUM(CASE
                  WHEN event_type = 1 THEN 1
				  ELSE 0
			  END) AS views,
		  SUM(CASE
			      WHEN event_type = 2 THEN 1
				  ELSE 0
			  END) AS cart_adds,
		  SUM(CASE
			      WHEN event_type = 2
                       AND (final_page_id_per_visit_id != 13
                            OR final_page_id_per_visit_id IS NULL) THEN 1
				  ELSE 0
			  END) AS abandoned,
		  SUM(CASE
                  WHEN event_type = 2
                       AND final_page_id_per_visit_id = 13 THEN 1
				  ELSE 0
			  END) AS purchases
   FROM final_page_id_cte
   WHERE product_category IS NOT NULL
   GROUP BY 1
   ORDER BY 1);
   
SELECT *
FROM  clique_bait.category_funnel_analysis;
