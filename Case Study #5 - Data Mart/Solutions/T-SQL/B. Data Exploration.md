# :shopping_cart: Case Study 5 - Data Mart

## B. Data Exploration

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Q1. What day of the week is used for each `week_date` value?
```tsql
SELECT DISTINCT DATENAME(dw, week_date) AS day_of_week
FROM data_mart.dbo.clean_weekly_sales;
```
| day_of_week |
|-------------|
| Monday      |

---
### Q2. What range of week numbers are missing from the dataset?
```tsql
WITH recursive_cte AS
  (SELECT 1 AS week_number_calendar
   UNION ALL 
   SELECT week_number_calendar + 1
   FROM recursive_cte
   WHERE week_number_calendar + 1 <= 52)
SELECT DISTINCT week_number_calendar,
       week_number AS week_number_dataset,
       CASE
           WHEN week_number IS NULL THEN week_number_calendar
           ELSE NULL
       END AS week_number_missing
FROM recursive_cte AS re
LEFT JOIN data_mart.dbo.clean_weekly_sales AS cws ON cws.week_number = re.week_number_calendar
ORDER BY week_number_calendar;
```
| week_number_calendar | week_number_dataset | week_number_missing |
|----------------------|---------------------|---------------------|
| 1                    | NULL                | 1                   |
| 2                    | NULL                | 2                   |
| ...                  | NULL                | ...                 |
| 11                   | NULL                | 11                  |
| 12                   | NULL                | 12                  |
| 13                   | 13                  | NULL                |
| 14                   | 14                  | NULL                |
| ...                  | ...                 | NULL                |
| 35                   | 35                  | NULL                |
| 36                   | 36                  | NULL                |
| 37                   | NULL                | 37                  |
| 38                   | NULL                | 38                  |
| ...                  | NULL                | ...                 |
| 51                   | NULL                | 51                  |
| 52                   | NULL                | 52                  |

> Note: The presented table comprises 12 out of 52 rows of the resulting table. 

---
### Q3. How many total transactions were there for each year in the dataset?
```tsql
SELECT calendar_year,
       COUNT(*) AS transaction_count_by_year
FROM data_mart.dbo.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```
| calendar_year | transaction_count_by_year |
|---------------|---------------------------|
| 2018          | 5698                      |
| 2019          | 5708                      |
| 2020          | 5711                      |

---
### Q4. What is the total sales for each region for each month?
```tsql
SELECT calendar_year,
       month_number,
       region,
       SUM(sales) AS total_sales
FROM data_mart.dbo.clean_weekly_sales
GROUP BY calendar_year,
         month_number,
         region
ORDER BY calendar_year,
         month_number,
         region;
```
| calendar_year | month_number | region        | total_sales |
|---------------|--------------|---------------|-------------|
| 2018          | 3            | Africa        | 130542213   |
| 2018          | 3            | Asia          | 119180883   |
| 2018          | 3            | Canada        | 33815571    |
| 2018          | 3            | Europe        | 8402183     |
| 2018          | 3            | Oceania       | 175777460   |
| 2018          | 3            | South America | 16302144    |
| 2018          | 3            | USA           | 52734998    |
| 2018          | 4            | Africa        | 650194751   |
| 2018          | 4            | Asia          | 603716301   |
| 2018          | 4            | Canada        | 163479820   |

> Note: The presented table comprises 10 out of 140 rows of the resulting table. 

---
### Q5. What is the total count of transactions for each platform?
```tsql
SELECT platform,
       COUNT(*) AS transaction_count_by_platform
FROM data_mart.dbo.clean_weekly_sales
GROUP BY platform
ORDER BY platform;
```
| platform | transaction_count_by_platform |
|----------|-------------------------------|
| Retail   | 8568                          |
| Shopify  | 8549                          |

---
### Q6. What is the percentage of sales for Retail vs Shopify for each month?
```tsql
SELECT calendar_year,
       month_number,
       CAST(100.0 * SUM(CASE
                            WHEN platform = 'Retail' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS retail_sales_pct,
       CAST(100.0 * SUM(CASE
                            WHEN platform = 'Shopify' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS shopify_sales_pct
FROM data_mart.dbo.clean_weekly_sales
GROUP BY calendar_year,
         month_number
ORDER BY calendar_year,
         month_number;
```
| calendar_year | month_number | retail_sales_pct | shopify_sales_pct |
|---------------|--------------|------------------|-------------------|
| 2018          | 3            | 97.92            | 2.08              |
| 2018          | 4            | 97.93            | 2.07              |
| 2018          | 5            | 97.73            | 2.27              |
| 2018          | 6            | 97.76            | 2.24              |
| 2018          | 7            | 97.75            | 2.25              |
| 2018          | 8            | 97.71            | 2.29              |
| 2018          | 9            | 97.68            | 2.32              |
| 2019          | 3            | 97.71            | 2.29              |
| 2019          | 4            | 97.80            | 2.20              |
| 2019          | 5            | 97.52            | 2.48              |

> Note: The presented table comprises 10 out of 20 rows of the resulting table. 

---
### Q7. What is the percentage of sales by demographic for each year in the dataset?
```tsql
SELECT calendar_year,
       CAST(100.0 * SUM(CASE
                            WHEN demographic = 'Families' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS sales_by_families_pct,
       CAST(100.0 * SUM(CASE
                            WHEN demographic = 'Couples' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2))AS sales_by_couples_pct,
       CAST(100.0 * SUM(CASE
                            WHEN demographic = 'unknown' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2))AS sales_by_unknown_pct
FROM data_mart.dbo.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```
| calendar_year | sales_by_families_pct | sales_by_couples_pct | sales_by_unknown_pct |
|---------------|-----------------------|----------------------|----------------------|
| 2018          | 31.99                 | 26.38                | 41.63                |
| 2019          | 32.47                 | 27.28                | 40.25                |
| 2020          | 32.73                 | 28.72                | 38.55                |

> Note: The presented table comprises 10 out of 3 rows of the resulting table.

---
### Q8. Which `age_band` and `demographic` values contribute the most to Retail sales?
```tsql
WITH retail_sales_cte AS
  (SELECT SUM(sales) AS total_retail_sales
   FROM data_mart.dbo.clean_weekly_sales
   WHERE platform = 'Retail')
SELECT age_band,
       demographic,
       SUM(sales) AS retail_sales_by_age_band_and_demographic,
       CAST(100.0 * SUM(sales) / total_retail_sales AS DECIMAL(5, 2)) AS retail_sales_by_age_band_and_demographic_pct
FROM data_mart.dbo.clean_weekly_sales,
     retail_sales_cte
WHERE platform = 'Retail'
GROUP BY age_band,
         demographic,
         total_retail_sales
ORDER BY retail_sales_by_age_band_and_demographic_pct DESC;
```
| age_band     | demographic | retail_sales_by_age_band_and_demographic | retail_sales_by_age_band_and_demographic_pct |
|--------------|-------------|------------------------------------------|----------------------------------------------|
| unknown      | unknown     | 16067285533                              | 40.52                                        |
| Retirees     | Families    | 6634686916                               | 16.73                                        |
| Retirees     | Couples     | 6370580014                               | 16.07                                        |
| Middle Aged  | Families    | 4354091554                               | 10.98                                        |
| Young Adults | Couples     | 2602922797                               | 6.56                                         |
| Middle Aged  | Couples     | 1854160330                               | 4.68                                         |
| Young Adults | Families    | 1770889293                               | 4.47                                         |

---
### Q9. Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
```tsql
SELECT calendar_year,
       platform,
       CAST(ROUND(AVG(avg_transaction), 2) AS REAL) AS average_of_avg_transaction,
       CAST(ROUND(1.0 * SUM(sales) / SUM(transactions), 2) AS REAL) AS weighted_avg_transaction
FROM data_mart.dbo.clean_weekly_sales
GROUP BY calendar_year,
         platform
ORDER BY calendar_year,
         platform;
```
| calendar_year | platform | average_of_avg_transaction | weighted_avg_transaction |
|---------------|----------|----------------------------|--------------------------|
| 2018          | Retail   | 42.91                      | 36.56                    |
| 2018          | Shopify  | 188.28                     | 192.48                   |
| 2019          | Retail   | 41.97                      | 36.83                    |
| 2019          | Shopify  | 177.56                     | 183.36                   |
| 2020          | Retail   | 40.64                      | 36.56                    |
| 2020          | Shopify  | 174.87                     | 179.03                   |

---
My solution for **[C. Before & After Analysis](C.%20Before%20&%20After%20Analysis.md)**.
