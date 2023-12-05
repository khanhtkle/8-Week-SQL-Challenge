-------------------------------------
-- C. Campaigns Analysis --
-------------------------------------
-- 	Generate a table that has 1 single row for every unique `visit_id` record and has the following columns:
-- 		- `user_id`
-- 		- `visit_id`
-- 		- `visit_start_time`: the earliest `event_time` for each visit
-- 		- `page_views`: count of page views for each visit
-- 		- `cart_adds`: count of product cart add events for each visit
-- 		- `purchase`: 1/0 flag if a purchase event exists for each visit
-- 		- `campaign_name`: map the visit to a campaign if the `visit_start_time` falls between the `start_date` and `end_date`
-- 		- `impression`: count of ad impressions for each visit
-- 		- `click`: count of ad clicks for each visit
-- 		- `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart

DROP TABLE IF EXISTS clique_bait.dbo.campaign_analysis;
WITH product_carts_cte AS
  (SELECT visit_id,
          STRING_AGG(CASE
                         WHEN event_type = 2 THEN page_name
                     END, ', ') WITHIN GROUP (ORDER BY sequence_number) AS product_carts
   FROM clique_bait.dbo.events AS ev
   LEFT JOIN clique_bait.dbo.page_hierarchy AS ph ON ph.page_id = ev.page_id
   GROUP BY visit_id)
SELECT user_id,
       ev.visit_id,
       CONCAT(CAST(MIN(event_time) AS DATE), ' ', CONVERT(time(0), MIN(event_time))) AS visit_start_time,
       SUM(CASE
               WHEN event_type = 1 THEN 1
               ELSE 0
           END) AS page_views,
       SUM(CASE
               WHEN event_type = 2 THEN 1
               ELSE 0
           END) AS cart_adds,
       SUM(CASE
               WHEN event_type = 3 THEN 1
               ELSE 0
           END) AS purchase,
       ci.campaign_name,
       SUM(CASE
               WHEN event_type = 4 THEN 1
               ELSE 0
           END) AS impression,
       SUM(CASE
               WHEN event_type = 5 THEN 1
               ELSE 0
           END) AS click,
       product_carts
INTO clique_bait.dbo.campaign_analysis
FROM clique_bait.dbo.users AS us
LEFT JOIN clique_bait.dbo.events AS ev ON ev.cookie_id = us.cookie_id
LEFT JOIN product_carts_cte AS pc ON pc.visit_id = ev.visit_id
LEFT JOIN clique_bait.dbo.campaign_identifier AS ci ON ev.event_time BETWEEN ci.start_date AND ci.end_date
GROUP BY user_id,
         ev.visit_id,
         ci.campaign_name,
		 product_carts;

SELECT * 
FROM clique_bait.dbo.campaign_analysis
ORDER BY user_id,
		 visit_start_time;

-- 	Some ideas to investigate further include:

-- 	Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event.

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
										 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN 'Received impression'
              ELSE 'No impression'
          END AS impression_stat
   FROM clique_bait.dbo.campaign_analysis)
SELECT impression_stat,
       COUNT(*) AS total_visits,
       CAST(AVG(1.0 * page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(1.0 * cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visits,
       CAST(AVG(1.0 * purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
GROUP BY impression_stat
ORDER BY impression_stat DESC;

-- 	Does clicking on an impression lead to higher purchase rates?

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
										 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0
                   AND SUM(click) OVER (PARTITION BY user_id, campaign_name
                                        ORDER BY visit_start_time 
										ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN '1. Received + Clicking impression'
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
										 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0
                   AND SUM(click) OVER (PARTITION BY user_id, campaign_name
                                        ORDER BY visit_start_time 
										ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) = 0 THEN '2. Received + No clicking impression'
              ELSE '3. No impression'
          END AS impression_stat
   FROM clique_bait.dbo.campaign_analysis)
SELECT impression_stat,
       COUNT(*) AS total_visits,
       CAST(AVG(1.0 * page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(1.0 * cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visit,
       CAST(AVG(1.0 * purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
GROUP BY impression_stat
ORDER BY impression_stat;

-- 	What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who have just an impression but do not click?

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
                                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0
                   AND SUM(click) OVER (PARTITION BY user_id, campaign_name
                                        ORDER BY visit_start_time 
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN '1. Received + Clicking impression'
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
                                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0
                   AND SUM(click) OVER (PARTITION BY user_id, campaign_name
                                        ORDER BY visit_start_time 
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) = 0 THEN '2. Received + No clicking impression'
              ELSE '3. No impression'
          END AS impression_stat
   FROM clique_bait.dbo.campaign_analysis),
     purchase_rate_cte AS
  (SELECT impression_stat,
          CAST(AVG(purchase) AS DECIMAL(5,2)) AS avg_purchase_rate
   FROM impression_stat_cte
   GROUP BY impression_stat)
SELECT pr1.impression_stat,
       pr2.avg_purchase_rate AS avg_purchase_rate_no_impression,
       pr1.avg_purchase_rate AS avg_purchase_rate_received_impression,
       pr1.avg_purchase_rate - pr2.avg_purchase_rate AS avg_purchase_rate_uplift
FROM purchase_rate_cte AS pr1,
     purchase_rate_cte AS pr2
WHERE pr1.impression_stat != '3. No impression'
  AND pr2.impression_stat = '3. No impression'
ORDER BY impression_stat;

-- 	What metrics can you use to quantify the success or failure of each campaign compared to each other?

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
										 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN 'Received impression'
              ELSE 'No impression'
          END AS impression_stat
   FROM clique_bait.dbo.campaign_analysis)
SELECT campaign_name,
       impression_stat,
       COUNT(*) AS total_visits,
       CAST(AVG(1.0 * page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(1.0 * cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visit,
       CAST(AVG(1.0 * purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
WHERE impression_stat = 'Received impression'
GROUP BY campaign_name,
         impression_stat
ORDER BY campaign_name;

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
										 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN 'Received impression'
              ELSE 'No impression'
          END AS impression_stat
   FROM clique_bait.dbo.campaign_analysis)
SELECT campaign_name,
       impression_stat,
       COUNT(*) AS total_visits,
       CAST(AVG(1.0 * page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(1.0 * cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visit,
       CAST(AVG(1.0 * purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
WHERE impression_stat = 'No impression'
GROUP BY campaign_name,
         impression_stat
ORDER BY campaign_name;
