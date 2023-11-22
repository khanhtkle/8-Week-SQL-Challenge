----------------------------------------
-- C. Before & After Analysis --
----------------------------------------
-- 	1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

WITH cumulative_sales_cte AS
  (SELECT SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') - 4 AND WEEKOFYEAR('2020-06-15') - 1 THEN sales
              END) AS cml_sales_4wk_pre,
          SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') AND WEEKOFYEAR('2020-06-15') + 3 THEN sales
              END) AS cml_sales_4wk_post
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year = 2020)
SELECT cml_sales_4wk_pre,
       cml_sales_4wk_post,
       cml_sales_4wk_post - cml_sales_4wk_pre AS variance,
       CAST(100.0 * (cml_sales_4wk_post - cml_sales_4wk_pre) / cml_sales_4wk_pre AS DECIMAL(5, 2)) AS variance_pct
FROM cumulative_sales_cte;

-- 	2. What about the entire 12 weeks before and after?

WITH cumulative_sales_cte AS
  (SELECT SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') - 12 AND WEEKOFYEAR('2020-06-15') - 1 THEN sales
              END) AS cml_sales_12wk_pre,
          SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') AND WEEKOFYEAR('2020-06-15') + 11 THEN sales
              END) AS cml_sales_12wk_post
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year = 2020)
SELECT cml_sales_12wk_pre,
       cml_sales_12wk_post,
       cml_sales_12wk_post - cml_sales_12wk_pre AS variance,
       CAST(100.0 * (cml_sales_12wk_post - cml_sales_12wk_pre) / cml_sales_12wk_pre AS DECIMAL(5, 2)) AS variance_pct
FROM cumulative_sales_cte;

-- 	3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

-- 	4wk)

SET @cml_sales_4wk_pre_2020 := (
SELECT SUM(CASE
               WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') - 4 AND WEEKOFYEAR('2020-06-15') - 1 THEN sales
           END) AS cml_sales_4wk_pre
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year = 2020);

SET @cml_sales_4wk_post_2020 := (
SELECT SUM(CASE
               WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') AND WEEKOFYEAR('2020-06-15') + 3 THEN sales
           END) AS cml_sales_4wk_post
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year = 2020);

WITH cumulative_sales_cte AS
  (SELECT calendar_year,
		  SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') - 4 AND WEEKOFYEAR('2020-06-15') - 1 THEN sales
              END) AS cml_sales_same_4wk_pre_period,
          SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') AND WEEKOFYEAR('2020-06-15') + 3 THEN sales
              END) AS cml_sales_same_4wk_post_period
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year != 2020
   GROUP BY calendar_year)
SELECT calendar_year,
	   cml_sales_same_4wk_pre_period,
	   @cml_sales_4wk_pre_2020 AS cml_sales_4wk_pre_2020,
       CAST(@cml_sales_4wk_pre_2020 - cml_sales_same_4wk_pre_period AS REAL) AS same_pre_period_variance,
	   CAST(100.0 * (@cml_sales_4wk_pre_2020 - cml_sales_same_4wk_pre_period) / cml_sales_same_4wk_pre_period AS DECIMAL(5, 2)) AS same_pre_period_variance_pct,
	   cml_sales_same_4wk_post_period,
	   @cml_sales_4wk_post_2020 AS cml_sales_4wk_post_2020,
       CAST(@cml_sales_4wk_post_2020 - cml_sales_same_4wk_post_period AS REAL) same_pre_period_variance,
	   CAST(100.0 * (@cml_sales_4wk_post_2020 - cml_sales_same_4wk_post_period) / cml_sales_same_4wk_post_period AS DECIMAL(5, 2)) AS same_post_period_variance_pct
FROM cumulative_sales_cte
ORDER BY calendar_year;


-- 	12wk)

SET @cml_sales_12wk_pre_2020:= (
SELECT SUM(CASE
               WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') - 12 AND WEEKOFYEAR('2020-06-15') - 1 THEN sales
           END) AS cml_sales_12wk_pre
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year = 2020);

SET @cml_sales_12wk_post_2020 := (
SELECT SUM(CASE
               WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') AND WEEKOFYEAR('2020-06-15') + 11 THEN sales
           END) AS cml_sales_12wk_post
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year = 2020);

WITH cumulative_sales_cte AS
  (SELECT calendar_year,
		  SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') - 12 AND WEEKOFYEAR('2020-06-15') - 1 THEN sales
              END) AS cml_sales_same_12wk_pre_period,
          SUM(CASE
                  WHEN week_number BETWEEN WEEKOFYEAR('2020-06-15') AND WEEKOFYEAR('2020-06-15') + 11 THEN sales
              END) AS cml_sales_same_12wk_post_period
   FROM data_mart.clean_weekly_sales
   WHERE calendar_year != 2020
   GROUP BY calendar_year)
SELECT calendar_year,
	   cml_sales_same_12wk_pre_period,
	   @cml_sales_12wk_pre_2020 AS cml_sales_12wk_pre_2020,
       CAST(@cml_sales_12wk_pre_2020 - cml_sales_same_12wk_pre_period AS REAL) same_pre_period_variance,
	   CAST(100.0 * (@cml_sales_12wk_pre_2020 - cml_sales_same_12wk_pre_period) / cml_sales_same_12wk_pre_period AS DECIMAL(5, 2)) AS same_pre_period_variance_pct,
	   cml_sales_same_12wk_post_period,
	   @cml_sales_12wk_post_2020 AS cml_sales_12wk_post_2020,
       CAST(@cml_sales_12wk_post_2020 - cml_sales_same_12wk_post_period AS REAL) AS same_pre_period_variance,
	   CAST(100.0 * (@cml_sales_12wk_post_2020 - cml_sales_same_12wk_post_period) / cml_sales_same_12wk_post_period AS DECIMAL(5, 2)) AS same_post_period_variance_pct
FROM cumulative_sales_cte
ORDER BY calendar_year;
