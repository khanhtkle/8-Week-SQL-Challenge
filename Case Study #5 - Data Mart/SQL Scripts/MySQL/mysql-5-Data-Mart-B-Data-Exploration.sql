----------------------------------------
-- B. Data Exploration --
----------------------------------------
-- 	1. What day of the week is used for each `week_date` value?

SELECT DISTINCT DAYNAME(week_date) AS day_of_week
FROM data_mart.clean_weekly_sales;

-- 	2. What range of week numbers are missing from the dataset?

WITH RECURSIVE recursive_cte AS
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
LEFT JOIN data_mart.clean_weekly_sales AS cws ON cws.week_number = re.week_number_calendar
ORDER BY 1;

-- 	3. How many total transactions were there for each year in the dataset?

SELECT calendar_year,
       COUNT(*) AS transaction_count_by_year
FROM data_mart.clean_weekly_sales
GROUP BY 1
ORDER BY 1;

-- 	4. What is the total sales for each region for each month?

SELECT calendar_year,
       month_number,
       region,
       SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 	5. What is the total count of transactions for each platform?

SELECT platform,
       COUNT(*) AS transaction_count_by_platform
FROM data_mart.clean_weekly_sales
GROUP BY 1
ORDER BY 1;

-- 	6. What is the percentage of sales for Retail vs Shopify for each month?

SELECT calendar_year,
       month_number,
       CAST(100.0 * SUM(CASE
                            WHEN platform = 'Retail' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS retail_sales_pct,
       CAST(100.0 * SUM(CASE
                            WHEN platform = 'Shopify' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS shopify_sales_pct
FROM data_mart.clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;

-- 	7. What is the percentage of sales by demographic for each year in the dataset?

SELECT calendar_year,
       CAST(100.0 * SUM(CASE
                            WHEN demographic = 'Families' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS sales_by_families_pct,
       CAST(100.0 * SUM(CASE
                            WHEN demographic = 'Couples' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS sales_by_couples_pct,
       CAST(100.0 * SUM(CASE
                            WHEN demographic = 'unknown' THEN sales
                        END) / SUM(sales) AS DECIMAL(5, 2)) AS sales_by_unknown_pct
FROM data_mart.clean_weekly_sales
GROUP BY 1
ORDER BY 1;

-- 	8. Which `age_band` and `demographic` values contribute the most to Retail sales?

WITH retail_sales_cte AS
  (SELECT SUM(sales) AS total_retail_sales
   FROM data_mart.clean_weekly_sales
   WHERE platform = 'Retail')
SELECT age_band,
       demographic,
       SUM(sales) AS retail_sales_by_age_band_and_demographic,
       CAST(100.0 * SUM(sales) / total_retail_sales AS DECIMAL(5, 2)) AS retail_sales_by_age_band_and_demographic_pct
FROM data_mart.clean_weekly_sales,
     retail_sales_cte
WHERE platform = 'Retail'
GROUP BY 1, 2, total_retail_sales
ORDER BY 4 DESC;

-- 	9. Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

SELECT calendar_year,
       platform,
       CAST(ROUND(AVG(avg_transaction), 2) AS REAL) AS average_of_avg_transaction,
       CAST(ROUND(1.0 * SUM(sales) / SUM(transactions), 2) AS REAL) AS weighted_avg_transaction
FROM data_mart.clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;
