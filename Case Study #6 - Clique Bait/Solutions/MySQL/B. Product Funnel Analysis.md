# :fish: Case Study 6 - Clique Bait

## B. Product Funnel Analysis

<picture>
  <img src="https://img.shields.io/badge/mysql-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### Create a new output table which has the following details:
- ### How many times was each product viewed?
- ### How many times was each product added to cart?
- ### How many times was each product added to a cart but not purchased (abandoned)?
- ### How many times was each product purchased?
### Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

### Data Cleaning
```mysql
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
FROM clique_bait.product_funnel_analysis;
```
| product_id | product_name   | views | cart_adds | abandoned | purchases |
|------------|----------------|-------|-----------|-----------|-----------|
| 1          | Salmon         | 1559  | 938       | 227       | 711       |
| 2          | Kingfish       | 1559  | 920       | 213       | 707       |
| 3          | Tuna           | 1515  | 931       | 234       | 697       |
| 4          | Russian Caviar | 1563  | 946       | 249       | 697       |
| 5          | Black Truffle  | 1469  | 924       | 217       | 707       |
| 6          | Abalone        | 1525  | 932       | 233       | 699       |
| 7          | Lobster        | 1547  | 968       | 214       | 754       |
| 8          | Crab           | 1564  | 949       | 230       | 719       |
| 9          | Oyster         | 1568  | 943       | 217       | 726       |

</br>

```mysql
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
FROM clique_bait.category_funnel_analysis;
```
| product_category | views | cart_adds | abandoned | purchases |
|------------------|-------|-----------|-----------|-----------|
| Fish             | 4633  | 2789      | 674       | 2115      |
| Luxury           | 3032  | 1870      | 466       | 1404      |
| Shellfish        | 6204  | 3792      | 894       | 2898      |

---
### Q1. Which product had the most views, cart adds and purchases?
```mysql
SELECT pfa1.product_name,
       CASE
           WHEN pfa1.views = (SELECT MAX(views)
                              FROM clique_bait.product_funnel_analysis) THEN CONCAT(pfa1.views, ' (most views)')
           ELSE pfa1.views
       END AS views,
       CASE
           WHEN pfa1.cart_adds = (SELECT MAX(cart_adds)
                                  FROM clique_bait.product_funnel_analysis) THEN CONCAT(pfa1.cart_adds, ' (most cart_adds)')
           ELSE pfa1.cart_adds
       END AS cart_adds,
       CASE
           WHEN pfa1.purchases = (SELECT MAX(purchases)
                                  FROM clique_bait.product_funnel_analysis) THEN CONCAT(pfa1.purchases, ' (most purchases)')
           ELSE pfa1.purchases
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
```
| product_name | views             | cart_adds            | purchases            |
|--------------|-------------------|----------------------|----------------------|
| Oyster       | 1568 (most views) | 943                  | 726                  |
| Lobster      | 1547              | 968 (most cart_adds) | 754 (most purchases) |

---
### Q2. Which product was most likely to be abandoned?
```mysql
SELECT product_name,
       abandoned,
       views,
       CAST(100 * abandoned / views AS DECIMAL(5,2)) AS abandoned_rate
FROM clique_bait.product_funnel_analysis
ORDER BY 4 DESC
LIMIT 1;
```
| product_name   | abandoned | views | abandoned_rate |
|----------------|-----------|-------|----------------|
| Russian Caviar | 249       | 1563  | 15.93          |

---
### Q3. Which product had the highest view to purchase percentage?
```mysql
SELECT product_name,
       purchases,
       views,
       CAST(100 * purchases / views AS DECIMAL(5,2)) AS view_to_purchase_pct
FROM clique_bait.product_funnel_analysis
ORDER BY 4 DESC
LIMIT 1;
```
| product_name | purchases | views | view_to_purchase_pct |
|--------------|-----------|-------|----------------------|
| Lobster      | 754       | 1547  | 48.74                |

---
### Q4. What is the average conversion rate from view to cart add?
```mysql
SELECT SUM(cart_adds) AS total_cart_adds,
       SUM(views) AS total_views,
       CAST(SUM(cart_adds) / SUM(views) AS DECIMAL(5,2)) AS view_to_cart_add_conversion_rate
FROM clique_bait.product_funnel_analysis;
```
| total_cart_adds | total_views | view_to_cart_add_conversion_rate |
|-----------------|-------------|----------------------------------|
| 8451            | 13869       | 0.61                             |

---
### Q5. What is the average conversion rate from cart add to purchase?
```mysql
SELECT SUM(purchases) AS total_purchases,
       SUM(cart_adds) AS total_cart_adds,
       CAST(SUM(purchases) / SUM(cart_adds) AS DECIMAL(5,2)) AS cart_add_to_purchase_conversion_rate
FROM clique_bait.product_funnel_analysis;
```
| total_purchases | total_cart_adds | cart_add_to_purchase_conversion_rate |
|-----------------|-----------------|--------------------------------------|
| 6417            | 8451            | 0.76                                 |

---
My solution for **[C. Campaigns Analysis](C.%20Campaigns%20Analysis.md)**.
