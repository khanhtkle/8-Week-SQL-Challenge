# :fish: Case Study 6 - Clique Bait

## A. Digital Analysis

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Q1. How many users are there?
```tsql
SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.dbo.users;
```
| total_users |
|-------------|
| 500         |

---
### Q2. How many cookies does each user have on average?
```tsql
SELECT CAST(1.0 * COUNT(cookie_id) / COUNT(DISTINCT user_id) AS DECIMAL(5,2)) AS avg_cookies_per_user
FROM clique_bait.dbo.users;
```
| avg_cookies_per_user |
|----------------------|
| 3.56                 |

---
### Q3. What is the unique number of visits by all users per month?
```tsql
SELECT YEAR(event_time) AS year,
       MONTH(event_time) AS month_index,
       FORMAT(event_time, 'MMMM') AS month,
       COUNT(DISTINCT visit_id) AS unique_visits_per_month
FROM clique_bait.dbo.events
GROUP BY YEAR(event_time),
         MONTH(event_time),
         FORMAT(event_time, 'MMMM')
ORDER BY MONTH(event_time);
```
| year | month_index | month    | unique_visits_per_month |
|------|-------------|----------|-------------------------|
| 2020 | 1           | January  | 876                     |
| 2020 | 2           | February | 1488                    |
| 2020 | 3           | March    | 916                     |
| 2020 | 4           | April    | 248                     |
| 2020 | 5           | May      | 36                      |

---
### Q4. What is the number of events for each event type?
```tsql
SELECT ev.event_type,
       event_name,
       COUNT(ev.event_type) AS events
FROM clique_bait.dbo.events AS ev
JOIN clique_bait.dbo.event_identifier AS ei ON ei.event_type = ev.event_type
GROUP BY ev.event_type,
         event_name
ORDER BY event_type;
```
| event_type | event_name    | events |
|------------|---------------|--------|
| 1          | Page View     | 20928  |
| 2          | Add to Cart   | 8451   |
| 3          | Purchase      | 1777   |
| 4          | Ad Impression | 876    |
| 5          | Ad Click      | 702    |

---
### Q5. What is the percentage of visits which have a purchase event?
```tsql
WITH purchase_visit_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS purchase_visit_count
   FROM clique_bait.dbo.events
   WHERE event_type = 3),
     total_visits_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS total_visits
   FROM clique_bait.dbo.events)
SELECT purchase_visit_count,
       total_visits,
       CAST(100.0 * purchase_visit_count / total_visits AS DECIMAL(5, 2)) AS purchase_visit_pct
FROM purchase_visit_cte,
     total_visits_cte;
```
| purchase_visit_count | total_visits | purchase_visit_pct |
|----------------------|--------------|--------------------|
| 1777                 | 3564         | 49.86              |

---
### Q6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```tsql
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
       CAST(100.0 * abandoned_visit_count / checkout_visit_count AS DECIMAL(5, 2)) AS abandoned_over_check_out_pct,
       total_visits,
       CAST(100.0 * abandoned_visit_count / total_visits AS DECIMAL(5, 2)) AS abandoned_over_total_visits_pct
FROM abandoned_visit_cte,
     checkout_visit_cte,
     total_visits_cte;
```
| abandoned_visit_count | checkout_visit_count | abandoned_over_check_out_pct | total_visits | abandoned_over_total_visits_pct |
|-----------------------|----------------------|------------------------------|--------------|---------------------------------|
| 326                   | 2103                 | 15.50                        | 3564         | 9.15                            |

---
### Q7. What are the top 3 pages by number of views?
```tsql
SELECT TOP 3 ev.page_id,
       page_name,
       COUNT(event_time) AS views
FROM clique_bait.dbo.events AS ev
JOIN clique_bait.dbo.event_identifier AS ei ON ei.event_type = ev.event_type
JOIN clique_bait.dbo.page_hierarchy AS ph ON ph.page_id = ev.page_id
WHERE ev.event_type = 1
GROUP BY ev.page_id,
         page_name
ORDER BY views DESC;
```
| page_id | page_name    | views |
|---------|--------------|-------|
| 2       | All Products | 3174  |
| 12      | Checkout     | 2103  |
| 1       | Home Page    | 1782  |

---
### Q8. What is the number of views and cart adds for each product category?
```tsql
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
```
| product_category | views | cart_adds |
|------------------|-------|-----------|
| Fish             | 4633  | 2789      |
| Luxury           | 3032  | 1870      |
| Shellfish        | 6204  | 3792      |

---
### Q9. What are the top 3 products by purchases?
```tsql
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
GROUP BY product_id,
         product_name
ORDER BY purchase_count DESC;
```
| product_id | product_name | purchase_count |
|------------|--------------|----------------|
| 7          | Lobster      | 754            |
| 9          | Oyster       | 726            |
| 8          | Crab         | 719            |

---
My solution for **[B. Product Funnel Analysis](B.%20Product%20Funnel%20Analysis.md)**.
