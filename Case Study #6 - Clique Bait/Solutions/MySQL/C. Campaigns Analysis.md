# :fish: Case Study 6 - Clique Bait

## C. Campaigns Analysis

<picture>
  <img src="https://img.shields.io/badge/mysql-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### Generate a table that has 1 single row for every unique `visit_id` record and has the following columns:
- #### `user_id`
- #### `visit_id`
- #### `visit_start_time`: the earliest `event_time` for each visit
- #### `page_views`: count of page views for each visit
- #### `art_adds`: count of product cart add events for each visit
- #### `purchase`: 1/0 flag if a purchase event exists for each visit
- #### `campaign_name`: map the visit to a campaign if the `visit_start_time falls` between the `start_date` and `end_date`
- #### `impression`: count of ad impressions for each visit
- #### `click`: count of ad clicks for each visit
- #### `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart
```mysql
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
          GROUP_CONCAT(CASE
                           WHEN ev.event_type = 2 THEN page_name
                       END ORDER BY sequence_number SEPARATOR ', ') AS product_carts
   FROM clique_bait.users AS us
   LEFT JOIN clique_bait.events AS ev ON ev.cookie_id = us.cookie_id
   LEFT JOIN clique_bait.event_identifier AS ei ON ei.event_type = ev.event_type
   LEFT JOIN clique_bait.page_hierarchy AS ph ON ph.page_id = ev.page_id
   LEFT JOIN clique_bait.campaign_identifier AS ci ON ev.event_time BETWEEN ci.start_date AND ci.end_date
   GROUP BY 1, 2, 7
   ORDER BY 1, 3);

SELECT *
FROM clique_bait.campaign_analysis;
```
| user_id | visit_id | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;visit_start_time&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | page_views | cart_adds | purchase | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;campaign_name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | impression | click | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;product_carts&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
|---------|----------|---------------------|------------|-----------|----------|-----------------------------------|------------|-------|-----------------------------------------------------------------------------|
| 1       | 0fc437   | 2020-02-04 17:49:50 | 10         | 6         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Tuna, Russian Caviar, Black Truffle, Abalone, Crab, Oyster                  |
| 1       | ccf365   | 2020-02-04 19:16:09 | 7          | 3         | 1        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Lobster, Crab, Oyster                                                       |
| 1       | 0826dc   | 2020-02-26 05:58:38 | 1          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | NULL                                                                        |
| 1       | 02a5d5   | 2020-02-26 16:57:26 | 4          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | NULL                                                                        |
| 1       | f7c798   | 2020-03-15 02:23:26 | 9          | 3         | 1        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Russian Caviar, Crab, Oyster                                                |
| 1       | 30b94d   | 2020-03-15 13:12:54 | 9          | 7         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Salmon, Kingfish, Tuna, Russian Caviar, Abalone, Lobster, Crab              |
| 1       | 41355d   | 2020-03-25 00:11:18 | 6          | 1         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Lobster                                                                     |
| 1       | eaffde   | 2020-03-25 20:06:32 | 10         | 8         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Salmon, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster |
| 2       | 3b5871   | 2020-01-18 10:16:32 | 9          | 6         | 1        | 25% Off - Living The Lux Life     | 1          | 1     | Salmon, Kingfish, Russian Caviar, Black Truffle, Lobster, Oyster            |
| 2       | c5c0ee   | 2020-01-18 10:35:23 | 1          | 0         | 0        | 25% Off - Living The Lux Life     | 0          | 0     | NULL     

### Some ideas to investigate further include:
- ### Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event.
```mysql
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
       CAST(AVG(page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visits,
       CAST(AVG(purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
GROUP BY 1;
```
| impression_stat     | total_visits | avg_page_view_per_visit | avg_cart_add_per_visits | avg_visit_to_purchase_conversion_rate |
|---------------------|--------------|-------------------------|-------------------------|---------------------------------------|
| Received impression | 2052         | 6.80                    | 3.11                    | 0.60                                  |
| No impression       | 1512         | 4.61                    | 1.37                    | 0.36                                  |

- ### Does clicking on an impression lead to higher purchase rates?
```mysql
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
       CAST(AVG(page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visit,
       CAST(AVG(purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
GROUP BY 1
ORDER BY 1;
```
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;impression_stat&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | total_visits | avg_page_view_per_visit | avg_cart_add_per_visit | avg_visit_to_purchase_conversion_rate |
|--------------------------------------|--------------|-------------------------|------------------------|---------------------------------------|
| 1. Received + Clicking impression    | 1739         | 6.95                    | 3.30                   | 0.61                                  |
| 2. Received + No clicking impression | 313          | 5.99                    | 2.05                   | 0.54                                  |
| 3. No impression                     | 1512         | 4.61                    | 1.37                   | 0.36                                  |

- ### What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
```mysql
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
  AND pr2.impression_stat = '3. No impression';
```
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;impression_stat&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | avg_purchase_rate_no_impression | avg_purchase_rate_received_impression | avg_purchase_rate_uplift |
|--------------------------------------|---------------------------------|---------------------------------------|--------------------------|
| 1. Received + Clicking impression    | 0.36                            | 0.61                                  | 0.25                     |
| 2. Received + No clicking impression | 0.36                            | 0.54                                  | 0.18                     |

- ### What metrics can you use to quantify the success or failure of each campaign compared to each other?
```mysql
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
       CAST(AVG(page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visit,
       CAST(AVG(purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
WHERE impression_stat = 'Received impression'
GROUP BY 1, 2
ORDER BY 1, 2 DESC;
```
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;campaign_name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | &nbsp;&nbsp;&nbsp;&nbsp;impression_stat&nbsp;&nbsp;&nbsp;&nbsp; | total_visits | avg_page_view_per_visit | avg_cart_add_per_visit | avg_visit_to_purchase_conversion_rate |
|-----------------------------------|---------------------|--------------|-------------------------|------------------------|---------------------------------------|
| NULL                              | Received impression | 243          | 7.42                    | 3.57                   | 0.65                                  |
| 25% Off - Living The Lux Life     | Received impression | 195          | 7.48                    | 3.59                   | 0.64                                  |
| BOGOF - Fishing For Compliments   | Received impression | 111          | 7.43                    | 3.80                   | 0.66                                  |
| Half Off - Treat Your Shellf(ish) | Received impression | 1503         | 6.57                    | 2.92                   | 0.59                                  |

</br>

```mysql
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
       CAST(AVG(page_views) AS DECIMAL(5,2)) AS avg_page_view_per_visit,
       CAST(AVG(cart_adds) AS DECIMAL(5,2)) AS avg_cart_add_per_visit,
       CAST(AVG(purchase) AS DECIMAL(5,2)) AS avg_visit_to_purchase_conversion_rate
FROM impression_stat_cte
WHERE impression_stat = 'No impression'
GROUP BY 1, 2
ORDER BY 1, 2 DESC;
```
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;campaign_name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | &nbsp;&nbsp;&nbsp;&nbsp;impression_stat&nbsp;&nbsp;&nbsp;&nbsp; | total_visits | avg_page_view_per_visit | avg_cart_add_per_visit | avg_visit_to_purchase_conversion_rate |
|-----------------------------------|-----------------|--------------|-------------------------|------------------------|---------------------------------------|
| NULL                              | No impression   | 269          | 4.68                    | 1.40                   | 0.41                                  |
| 25% Off - Living The Lux Life     | No impression   | 209          | 4.67                    | 1.39                   | 0.37                                  |
| BOGOF - Fishing For Compliments   | No impression   | 149          | 4.77                    | 1.36                   | 0.36                                  |
| Half Off - Treat Your Shellf(ish) | No impression   | 885          | 4.55                    | 1.36                   | 0.34                                  |
