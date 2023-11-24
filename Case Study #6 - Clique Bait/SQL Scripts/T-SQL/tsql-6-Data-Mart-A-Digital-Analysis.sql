-------------------------------------
-- A. Digital Analysis --
-------------------------------------
-- 	1. How many users are there?

SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.dbo.users;

--  2. How many cookies does each user have on average?

SELECT CAST(1.0 * COUNT(cookie_id) / COUNT(DISTINCT user_id) AS DECIMAL(5,2)) AS avg_cookies_per_user
FROM clique_bait.dbo.users;

--  3. What is the unique number of visits by all users per month?

SELECT YEAR(event_time) AS year,
       MONTH(event_time) AS month_index,
       FORMAT(event_time, 'MMMM') AS month,
       COUNT(DISTINCT visit_id) AS visits_per_month_count
FROM clique_bait.dbo.events
GROUP BY YEAR(event_time),
         MONTH(event_time),
         FORMAT(event_time, 'MMMM')
ORDER BY MONTH(event_time);

--  4. What is the number of events for each event type?

SELECT ev.event_type,
       event_name,
       COUNT(ev.event_type) AS events_count
FROM clique_bait.dbo.events AS ev
JOIN clique_bait.dbo.event_identifier AS ei ON ei.event_type = ev.event_type
GROUP BY ev.event_type,
         event_name
ORDER BY event_type;

--  5. What is the percentage of visits which have a purchase event?

WITH purchase_visit_cte AS 
  (SELECT COUNT(DISTINCT visit_id) AS purchase_visit_count
   FROM clique_bait.dbo.events
   WHERE event_type = 3),
	total_visits_cte AS 
  (SELECT COUNT(DISTINCT visit_id) AS total_visits
   FROM clique_bait.dbo.events)
SELECT purchase_visit_count,
	   total_visits,
	   CAST(100.0 * purchase_visit_count / total_visits AS DECIMAL(5,2)) AS purchase_visit_pct
FROM purchase_visit_cte, 
     total_visits_cte;

--  6. What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH next_page_id_cte AS
  (SELECT visit_id,
          ev.page_id,
          page_name,
          ev.event_type,
          event_name,
          event_time,
          LEAD(ev.page_id) OVER (PARTITION BY visit_id
                                 ORDER BY event_time, sequence_number) AS next_page_id
   FROM clique_bait.dbo.events AS ev
   JOIN clique_bait.dbo.event_identifier AS ei ON ei.event_type = ev.event_type
   JOIN clique_bait.dbo.page_hierarchy AS ph ON ph.page_id = ev.page_id),
     abandoned_visit_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS abandoned_visit_count
   FROM next_page_id_cte
   WHERE page_id = 12
     AND next_page_id IS NULL),
     checkout_visit_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS checkout_visit_count
   FROM clique_bait.dbo.events
   WHERE page_id = 12),
     total_visits_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS total_visits
   FROM clique_bait.dbo.events)
SELECT abandoned_visit_count,
       checkout_visit_count,
       CAST(100.0 * abandoned_visit_count / checkout_visit_count AS DECIMAL(5,2)) AS abandoned_over_check_out_pct,
       total_visits,
       CAST(100.0 * abandoned_visit_count / total_visits AS DECIMAL(5,2)) AS abandoned_over_total_visits_pct
FROM abandoned_visit_cte,
     checkout_visit_cte,
     total_visits_cte;

--  7. What are the top 3 pages by number of views?

SELECT TOP 3 ev.page_id,
       page_name,
       COUNT(event_time) AS views
FROM clique_bait.dbo.events AS ev
JOIN clique_bait.dbo.event_identifier AS ei ON ei.event_type = ev.event_type
JOIN clique_bait.dbo.page_hierarchy AS ph ON ph.page_id = ev.page_id
WHERE ev.event_type = 1
GROUP BY ev.page_id, page_name
ORDER BY views DESC;

--  8. What is the number of views and cart adds for each product category?

SELECT product_category,
       SUM(CASE
               WHEN ev.event_type = 1 THEN 1
               ELSE 0
           END) AS views,
       SUM(CASE
               WHEN ev.event_type = 2 THEN 1
               ELSE 0
           END) AS cart_adds
FROM clique_bait.dbo.events AS ev
JOIN clique_bait.dbo.page_hierarchy AS ph ON ph.page_id = ev.page_id
WHERE product_category IS NOT NULL
GROUP BY product_category
ORDER BY product_category;

--  9. What are the top 3 products by purchases?

WITH final_page_id_cte AS
  (SELECT product_id,
          page_name AS product_name,
          ev.event_type,
          MAX(ev.page_id) OVER (PARTITION BY visit_id) AS final_page_id_from_this_visit_id
   FROM clique_bait.dbo.events AS ev
   JOIN clique_bait.dbo.event_identifier AS ei ON ei.event_type = ev.event_type
   JOIN clique_bait.dbo.page_hierarchy AS ph ON ph.page_id = ev.page_id)
SELECT TOP 3 product_id,
       product_name,
       SUM(CASE
               WHEN event_type = 2
                    AND final_page_id_from_this_visit_id = 13 THEN 1
               ELSE 0
           END) AS purchase_count
FROM final_page_id_cte
GROUP BY product_id, product_name
ORDER BY purchase_count DESC;
