# :shopping_cart: Case Study 5 - Data Mart

## C. Before & After Analysis

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect.
### We would include all `week_date` values for `2020-06-15` as the start of the period after the change and the previous `week_date` values would be before the change.
### Q1. What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?
```tsql
WITH cumulative_sales_cte AS
  (SELECT SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') - 4 AND DATEPART(ww, '2020-06-15') - 1 THEN sales
              END) AS cml_sales_4wk_pre,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') AND DATEPART(ww, '2020-06-15') + 3 THEN sales
              END) AS cml_sales_4wk_post
   FROM data_mart.dbo.clean_weekly_sales
   WHERE calendar_year = 2020)
SELECT cml_sales_4wk_pre,
       cml_sales_4wk_post,
       cml_sales_4wk_post - cml_sales_4wk_pre AS variance,
       CAST(100.0 * (cml_sales_4wk_post - cml_sales_4wk_pre) / cml_sales_4wk_pre AS DECIMAL(5, 2)) AS variance_pct
FROM cumulative_sales_cte;
```
| cml_sales_4wk_pre | cml_sales_4wk_post | variance  | variance_pct |
|-------------------|--------------------|-----------|--------------|
| 2345878357        | 2318994169         | -26884188 | -1.15        |

---
### Q2. What about the entire 12 weeks before and after?
```tsql
WITH cumulative_sales_cte AS
  (SELECT SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') - 12 AND DATEPART(ww, '2020-06-15') - 1 THEN sales
              END) AS cml_sales_12wk_pre,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') AND DATEPART(ww, '2020-06-15') + 11 THEN sales
              END) AS cml_sales_12wk_post
   FROM data_mart.dbo.clean_weekly_sales
   WHERE calendar_year = 2020)
SELECT cml_sales_12wk_pre,
       cml_sales_12wk_post,
       cml_sales_12wk_post - cml_sales_12wk_pre AS variance,
       CAST(100.0 * (cml_sales_12wk_post - cml_sales_12wk_pre) / cml_sales_12wk_pre AS DECIMAL(5, 2)) AS variance_pct
FROM cumulative_sales_cte;
```
| cml_sales_12wk_pre | cml_sales_12wk_post | variance   | variance_pct |
|--------------------|---------------------|------------|--------------|
| 7126273147         | 6973947753          | -152325394 | -2.14        |

---
### Q3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
4 week period:
```tsql
WITH cml_sales_4wk_2020_cte AS
  (SELECT SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') - 4 AND DATEPART(ww, '2020-06-15') - 1 THEN sales
              END) AS cml_sales_4wk_pre_2020,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') AND DATEPART(ww, '2020-06-15') + 3 THEN sales
              END) AS cml_sales_4wk_post_2020
   FROM data_mart.dbo.clean_weekly_sales
   WHERE calendar_year = 2020),
     cumulative_sales_cte AS
  (SELECT calendar_year,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') - 4 AND DATEPART(ww, '2020-06-15') - 1 THEN sales
              END) AS cml_sales_same_4wk_pre_period,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') AND DATEPART(ww, '2020-06-15') + 3 THEN sales
              END) AS cml_sales_same_4wk_post_period
   FROM data_mart.dbo.clean_weekly_sales
   WHERE calendar_year != 2020
   GROUP BY calendar_year)
SELECT calendar_year,
       cml_sales_same_4wk_pre_period,
       cml_sales_4wk_pre_2020,
       cml_sales_4wk_pre_2020 - cml_sales_same_4wk_pre_period AS same_pre_period_variance,
       CAST(100.0 * (cml_sales_4wk_pre_2020 - cml_sales_same_4wk_pre_period) / cml_sales_same_4wk_pre_period AS DECIMAL(5, 2)) AS same_pre_period_variance_pct,
       cml_sales_same_4wk_post_period,
       cml_sales_4wk_post_2020,
       cml_sales_4wk_post_2020 - cml_sales_same_4wk_post_period AS same_pre_period_variance,
       CAST(100.0 * (cml_sales_4wk_post_2020 - cml_sales_same_4wk_post_period) / cml_sales_same_4wk_post_period AS DECIMAL(5, 2)) AS same_post_period_variance_pct
FROM cumulative_sales_cte,
     cml_sales_4wk_2020_cte
ORDER BY calendar_year;
```
| calendar_year | cml_sales_same_4wk_pre_period | cml_sales_4wk_pre_2020 | same_pre_period_variance | same_pre_period_variance_pct | cml_sales_same_4wk_post_period | cml_sales_4wk_post_2020 | same_pre_period_variance | same_post_period_variance_pct |
|---------------|-------------------------------|------------------------|--------------------------|------------------------------|--------------------------------|-------------------------|--------------------------|-------------------------------|
| 2018          | 2125140809                    | 2345878357             | 220737548                | 10.39                        | 2129242914                     | 2318994169              | 189751255                | 8.91                          |
| 2019          | 2249989796                    | 2345878357             | 95888561                 | 4.26                         | 2252326390                     | 2318994169              | 66667779                 | 2.96                          |

12 week period:
```tsql
WITH cml_sales_12wk_2020_cte AS
  (SELECT SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') - 12 AND DATEPART(ww, '2020-06-15') - 1 THEN sales
              END) AS cml_sales_12wk_pre_2020,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') AND DATEPART(ww, '2020-06-15') + 11 THEN sales
              END) AS cml_sales_12wk_post_2020
   FROM data_mart.dbo.clean_weekly_sales
   WHERE calendar_year = 2020),
     cumulative_sales_cte AS
  (SELECT calendar_year,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') - 12 AND DATEPART(ww, '2020-06-15') - 1 THEN sales
              END) AS cml_sales_same_12wk_pre_period,
          SUM(CASE
                  WHEN week_number BETWEEN DATEPART(ww, '2020-06-15') AND DATEPART(ww, '2020-06-15') + 11 THEN sales
              END) AS cml_sales_same_12wk_post_period
   FROM data_mart.dbo.clean_weekly_sales
   WHERE calendar_year != 2020
   GROUP BY calendar_year)
SELECT calendar_year,
       cml_sales_same_12wk_pre_period,
       cml_sales_12wk_pre_2020,
       cml_sales_12wk_pre_2020 - cml_sales_same_12wk_pre_period AS same_pre_period_variance,
       CAST(100.0 * (cml_sales_12wk_pre_2020 - cml_sales_same_12wk_pre_period) / cml_sales_same_12wk_pre_period AS DECIMAL(5, 2)) AS same_pre_period_variance_pct,
       cml_sales_same_12wk_post_period,
       cml_sales_12wk_post_2020,
       cml_sales_12wk_post_2020 - cml_sales_same_12wk_post_period AS same_pre_period_variance,
       CAST(100.0 * (cml_sales_12wk_post_2020 - cml_sales_same_12wk_post_period) / cml_sales_same_12wk_post_period AS DECIMAL(5, 2)) AS same_post_period_variance_pct
FROM cumulative_sales_cte,
     cml_sales_12wk_2020_cte
ORDER BY calendar_year;
```
| calendar_year | cml_sales_same_12wk_pre_period | cml_sales_12wk_pre_2020 | same_pre_period_variance | same_pre_period_variance_pct | cml_sales_same_12wk_post_period | cml_sales_12wk_post_2020 | same_pre_period_variance | same_post_period_variance_pct |
|---------------|--------------------------------|-------------------------|--------------------------|------------------------------|---------------------------------|--------------------------|--------------------------|-------------------------------|
| 2018          | 6396562317                     | 7126273147              | 729710830                | 11.41                        | 6500818510                      | 6973947753               | 473129243                | 7.28                          |
| 2019          | 6883386397                     | 7126273147              | 242886750                | 3.53                         | 6862646103                      | 6973947753               | 111301650                | 1.62                          |

---
My solution for **[D. Bonus Question](D.%20Bonus%20Question.md)**.
