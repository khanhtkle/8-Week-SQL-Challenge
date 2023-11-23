-------------------------------------
-- D. Bonus Question --
-------------------------------------
-- 	Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
-- 	- region
-- 	- platform
-- 	- age_band
-- 	- demographic
-- 	- customer_type
-- 	Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

DROP TABLE IF EXISTS data_mart.sales_variance;
CREATE TABLE data_mart.sales_variance AS (
WITH cumulative_sales_cte AS
  (SELECT region,
          platform,
          age_band,
          demographic,
          customer_type,
          SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') - 4 AND WEEKOFYEAR('2020-06-15') - 1 THEN sales
              END) AS cml_sales_4wk_pre,
          SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') AND WEEKOFYEAR('2020-06-15') + 3 THEN sales
              END) AS cml_sales_4wk_post
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year = 2020
   GROUP BY 1, 2, 3, 4, 5)
SELECT *,
       cml_sales_4wk_post - cml_sales_4wk_pre AS variance,
       CAST(100.0 * (cml_sales_4wk_post - cml_sales_4wk_pre) / cml_sales_4wk_pre AS DECIMAL(5, 2)) AS variance_pct,
       DENSE_RANK() OVER (PARTITION BY region, platform
                          ORDER BY cml_sales_4wk_post - cml_sales_4wk_pre) AS variance_ranking,
       DENSE_RANK() OVER (PARTITION BY region, platform
						  ORDER BY CAST(100.0 * (cml_sales_4wk_post - cml_sales_4wk_pre) / cml_sales_4wk_pre AS DECIMAL(5, 2))) AS variance_pct_ranking
FROM cumulative_sales_cte);

SELECT *
FROM data_mart.sales_variance
WHERE variance_ranking = 1
ORDER BY 1, 2;

SELECT *
FROM data_mart.sales_variance
WHERE variance_pct_ranking = 1
ORDER BY 1, 2;
