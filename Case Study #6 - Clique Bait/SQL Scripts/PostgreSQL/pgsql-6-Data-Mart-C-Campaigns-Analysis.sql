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

DROP TABLE IF EXISTS clique_bait.campaign_analysis;
CREATE TABLE clique_bait.campaign_analysis AS
  (SELECT user_id,
          ev.visit_id,
          MIN(event_time) AS visit_start_time,
          SUM(CASE
                  WHEN ev.event_type = 1 THEN 1
                  ELSE 0
              END) AS page_views,
          SUM(CASE
                  WHEN ev.event_type = 2 THEN 1
                  ELSE 0
              END) AS cart_adds,
          SUM(CASE
                  WHEN ev.event_type = 3 THEN 1
                  ELSE 0
              END) AS purchase,
          ci.campaign_name,
          SUM(CASE
                  WHEN ev.event_type = 4 THEN 1
                  ELSE 0
              END) AS impression,
          SUM(CASE
                  WHEN ev.event_type = 5 THEN 1
                  ELSE 0
              END) AS click,
          STRING_AGG(CASE
               			 WHEN ev.event_type = 2 THEN page_name
           			 END, ', ' ORDER BY sequence_number) AS product_carts
   FROM clique_bait.users AS us
   LEFT JOIN clique_bait.events AS ev ON ev.cookie_id = us.cookie_id
   LEFT JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
   LEFT JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id
   LEFT JOIN clique_bait.campaign_identifier AS ci ON ev.event_time BETWEEN ci.start_date AND ci.end_date
   GROUP BY 1, 2, 7
   ORDER BY 1, 2, 3);

SELECT *
FROM clique_bait.campaign_analysis;

-- 	Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event.

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
                                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN 'Received impression'
              ELSE 'No impression'
          END AS impression_stat
   FROM clique_bait.campaign_analysis)
SELECT impression_stat,
       COUNT(*) AS total_visits,
       AVG(page_views)::DECIMAL(5,2) AS avg_page_view_per_visit,
       AVG(cart_adds)::DECIMAL(5,2) AS avg_cart_add_per_visits,
       AVG(purchase)::DECIMAL(5,2) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
GROUP BY 1;

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
   FROM clique_bait.campaign_analysis)
SELECT impression_stat,
       COUNT(*) AS total_visits,
       AVG(page_views)::DECIMAL(5,2) AS avg_page_view_per_visit,
       AVG(cart_adds)::DECIMAL(5,2) AS avg_cart_add_per_visit,
       AVG(purchase)::DECIMAL(5,2) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
GROUP BY 1
ORDER BY 1;

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
   FROM clique_bait.campaign_analysis),
     purchase_rate_cte AS
  (SELECT impression_stat,
          AVG(purchase)::DECIMAL(5,2) AS avg_purchase_rate
   FROM impression_stat_cte
   GROUP BY impression_stat)
SELECT pr1.impression_stat,
       pr2.avg_purchase_rate AS avg_purchase_rate_no_impression,
       pr1.avg_purchase_rate AS avg_purchase_rate_received_impression,
       pr1.avg_purchase_rate - pr2.avg_purchase_rate AS avg_purchase_rate_uplift
FROM purchase_rate_cte AS pr1,
     purchase_rate_cte AS pr2
WHERE pr1.impression_stat != '3. No impression'
  AND pr2.impression_stat = '3. No impression';

-- 	What metrics can you use to quantify the success or failure of each campaign compared to each other?

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
										 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN 'Received impression'
              ELSE 'No impression'
          END AS impression_stat
   FROM clique_bait.campaign_analysis)
SELECT campaign_name,
       impression_stat,
       COUNT(*) AS total_visits,
       AVG(page_views)::DECIMAL(5,2) AS avg_page_view_per_visit,
       AVG(cart_adds)::DECIMAL(5,2) AS avg_cart_add_per_visit,
       AVG(purchase)::DECIMAL(5,2) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
WHERE impression_stat = 'Received impression'
GROUP BY 1, 2
ORDER BY 1, 2 DESC;

WITH impression_stat_cte AS
  (SELECT *,
          CASE
              WHEN SUM(impression) OVER (PARTITION BY user_id, campaign_name
                                         ORDER BY visit_start_time 
										 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) > 0 THEN 'Received impression'
              ELSE 'No impression'
          END AS impression_stat
   FROM clique_bait.campaign_analysis)
SELECT campaign_name,
       impression_stat,
       COUNT(*) AS total_visits,
       AVG(page_views)::DECIMAL(5,2) AS avg_page_view_per_visit,
       AVG(cart_adds)::DECIMAL(5,2) AS avg_cart_add_per_visit,
       AVG(purchase)::DECIMAL(5,2) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
WHERE impression_stat = 'No impression'
GROUP BY 1, 2
ORDER BY 1, 2 DESC;
