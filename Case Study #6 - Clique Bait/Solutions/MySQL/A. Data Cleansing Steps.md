# :fish: Case Study 6 - Clique Bait

## A. Digital Analysis

<picture>
  <img src="https://img.shields.io/badge/mysql-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### Q1. How many users are there?
```mysql
SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.users;
```
| total_users |
|-------------|
| 500         |

---
### Q2. How many cookies does each user have on average?
```mysql
SELECT CAST(COUNT(cookie_id) / COUNT(DISTINCT user_id) AS DECIMAL(5,2)) AS avg_cookies_per_user
FROM clique_bait.users;
```
| avg_cookies_per_user |
|----------------------|
| 3.56                 |

---
### Q3. What is the unique number of visits by all users per month?
```mysql
SELECT YEAR(event_time) AS year,
       MONTH(event_time) AS month_index,
       MONTHNAME(event_time) AS month,
       COUNT(DISTINCT visit_id) AS unique_visits_per_month
FROM clique_bait.events
GROUP BY 1, 2, 3
ORDER BY 1;
```
| year | month_index | month    | visits_per_month |
|------|-------------|----------|------------------|
| 2020 | 1           | January  | 876              |
| 2020 | 2           | February | 1488             |
| 2020 | 3           | March    | 916              |
| 2020 | 4           | April    | 248              |
| 2020 | 5           | May      | 36               |

---
### Q4. What is the number of events for each event type?
```mysql
SELECT ev.event_type,
       event_name,
       COUNT(ev.event_type) AS events
FROM clique_bait.events AS ev
JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
GROUP BY 1, 2
ORDER BY 1;
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
```mysql
WITH purchase_visit_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS purchase_visit_count
   FROM clique_bait.events
   WHERE event_type = 3),
     total_visits_cte AS
  (SELECT COUNT(DISTINCT visit_id) AS total_visits
   FROM clique_bait.events)
SELECT purchase_visit_count,
       total_visits,
       CAST(100 * purchase_visit_count / total_visits AS DECIMAL(5,2)) AS purchase_visit_pct
FROM purchase_visit_cte,
     total_visits_cte;
```
| purchase_visit_count | total_visits | purchase_visit_pct |
|----------------------|--------------|--------------------|
| 1777                 | 3564         | 49.86              |

---
### Q6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```mysql
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
       CAST(100 * abandoned_visit_count / checkout_visit_count AS DECIMAL(5,2)) AS abandoned_over_check_out_pct,
       total_visits,
       CAST(100 * abandoned_visit_count / total_visits AS DECIMAL(5,2)) AS abandoned_over_total_visits_pct
FROM abandoned_visit_cte,
     checkout_visit_cte,
     total_visits_cte;
```
| abandoned_visit_count | checkout_visit_count | abandoned_over_check_out_pct | total_visits | abandoned_over_total_visits_pct |
|-----------------------|----------------------|------------------------------|--------------|---------------------------------|
| 326                   | 2103                 | 15.50                        | 3564         | 9.15                            |

---
### Q7. What are the top 3 pages by number of views?
```mysql
SELECT ev.page_id,
       page_name,
       COUNT(event_time) AS views
FROM clique_bait.events AS ev
JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id
WHERE ev.event_type = 1
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 3;
```
| page_id | page_name    | views |
|---------|--------------|-------|
| 2       | All Products | 3174  |
| 12      | Checkout     | 2103  |
| 1       | Home Page    | 1782  |

---
### Q8. What is the number of views and cart adds for each product category?
```mysql
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
```
| product_category | views | cart_adds |
|------------------|-------|-----------|
| Fish             | 4633  | 2789      |
| Luxury           | 3032  | 1870      |
| Shellfish        | 6204  | 3792      |

---
### Q9. What are the top 3 products by purchases?
```mysql
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
```
| product_id | product_name | purchase_count |
|------------|--------------|----------------|
| 7          | Lobster      | 754            |
| 9          | Oyster       | 726            |
| 8          | Crab         | 719            |

---
My solution for **[B. Product Funnel Analysis](B.%20Product%20Funnel%20Analysis.md)**.
