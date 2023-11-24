-------------------------------------
-- A. Digital Analysis --
-------------------------------------
-- 	1. How many users are there?

SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.users;

--  2. How many cookies does each user have on average?

SELECT (1.0 * COUNT(cookie_id) / COUNT(DISTINCT user_id))::DECIMAL(5,2) AS avg_cookies_per_user
FROM clique_bait.users;

--  3. What is the unique number of visits by all users per month?

SELECT DATE_PART('year', event_time) AS year,
       DATE_PART('month', event_time) AS month_index,
	   TO_CHAR(event_time, 'Month') AS month,
	   COUNT(DISTINCT visit_id) AS visits_per_month
FROM clique_bait.events
GROUP BY 1, 2, 3
ORDER BY 1; 

--  4. What is the number of events for each event type?

SELECT ev.event_type,
	   event_name,
	   COUNT(ev.event_type) AS event_count
FROM clique_bait.events AS ev
JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
GROUP BY 1 , 2
ORDER BY 1;

--  5. What is the percentage of visits which have a purchase event?

WITH purchase_visit_cte AS 
  (SELECT COUNT(DISTINCT visit_id) AS purchase_visit_count
   FROM clique_bait.events
   WHERE event_type = 3),
	total_visits_cte AS 
  (SELECT COUNT(DISTINCT visit_id) AS total_visits
   FROM clique_bait.events)
SELECT purchase_visit_count,
	   total_visits,
	   (100.0 * purchase_visit_count / total_visits)::DECIMAL(5,2) AS purchase_visit_pct
FROM purchase_visit_cte, 
     total_visits_cte;

--  6. What is the percentage of visits which view the checkout page but do not have a purchase event (abandoned)?

WITH next_page_id_cte AS
  (SELECT visit_id,
          ev.page_id,
          page_name,
          ev.event_type,
          event_name,
          event_time,
          LEAD(ev.page_id) OVER (PARTITION BY visit_id
                                 ORDER BY event_time, sequence_number) AS next_page_id
   FROM clique_bait.events AS ev
   JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
   JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id),
     abandoned_visit_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS abandoned_visit_count
   FROM next_page_id_cte
   WHERE page_id = 12
     AND next_page_id IS NULL),
     checkout_visit_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS checkout_visit_count
   FROM clique_bait.events
   WHERE page_id = 12),
     total_visits_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS total_visits
   FROM clique_bait.events)
SELECT abandoned_visit_count,
       checkout_visit_count,
       (100.0 * abandoned_visit_count / checkout_visit_count)::DECIMAL(5,2) AS abandoned_over_check_out_pct,
       total_visits,
       (100.0 * abandoned_visit_count / total_visits)::DECIMAL(5,2) AS abandoned_over_total_visits_pct
FROM abandoned_visit_cte,
     checkout_visit_cte,
     total_visits_cte;

--  7. What are the top 3 pages by number of views?

SELECT ev.page_id, 
	   page_name, 
       COUNT(event_time) AS views
FROM clique_bait.events AS ev
JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id
WHERE ev.event_type = 1
GROUP BY 1 , 2
ORDER BY 3 DESC
LIMIT 3;

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
FROM clique_bait.events AS ev
JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id
WHERE product_category IS NOT NULL
GROUP BY 1
ORDER BY 1;

--  9. What are the top 3 products by purchases?

WITH final_page_id_cte AS
  (SELECT product_id,
          page_name AS product_name,
          ev.event_type,
          MAX(ev.page_id) OVER (PARTITION BY visit_id) AS final_page_id_from_this_visit_id
   FROM clique_bait.events AS ev
   JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
   JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id)
SELECT product_id,
       product_name,
       SUM(CASE
               WHEN event_type = 2
                    AND final_page_id_from_this_visit_id = 13 THEN 1
               ELSE 0
           END) AS purchase_count
FROM final_page_id_cte
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 3;
