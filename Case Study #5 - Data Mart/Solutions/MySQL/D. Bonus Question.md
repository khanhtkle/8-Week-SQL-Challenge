# :shopping_cart: Case Study 5 - Data Mart

## D. Bonus Question

<picture>
  <img src="https://img.shields.io/badge/mysql-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- ### `region`
- ### `platform`
- ### `age_band`
- ### `demographic`
- ### `customer_type`
### Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
```mysql
DROP TABLE IF EXISTS data_mart.sales_variance;
CREATE TABLE data_mart.sales_variance AS
  (WITH cumulative_sales_cte AS
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
      GROUP BY 1, 2, 3, 4,5)
   SELECT *,
          cml_sales_4wk_post - cml_sales_4wk_pre AS variance,
          CAST(100.0 * (cml_sales_4wk_post - cml_sales_4wk_pre) / cml_sales_4wk_pre AS DECIMAL(5, 2)) AS variance_pct,
          DENSE_RANK() OVER (PARTITION BY region, platform
                             ORDER BY cml_sales_4wk_post - cml_sales_4wk_pre) AS variance_ranking,
          DENSE_RANK() OVER (PARTITION BY region, platform
                             ORDER BY 100.0 * (cml_sales_4wk_post - cml_sales_4wk_pre) / cml_sales_4wk_pre) AS variance_pct_ranking
   FROM cumulative_sales_cte);

SELECT *
FROM data_mart.sales_variance
WHERE variance_ranking = 1
ORDER BY 1, 2;
```
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;region&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | platform | &nbsp;&nbsp;&nbsp;age_band&nbsp;&nbsp;&nbsp; | demographic | customer_type | cml_sales_4wk_pre | cml_sales_4wk_post | variance | variance_pct | variance_ranking | variance_pct_ranking |
|---------------|----------|--------------|-------------|---------------|-------------------|--------------------|----------|--------------|------------------|----------------------|
| Africa        | Retail   | Middle Aged  | Families    | Existing      | 59918237          | 59247418           | -670819  | -1.12        | 1                | 2                    |
| Africa        | Shopify  | Middle Aged  | Families    | Existing      | 3467519           | 3258490            | -209029  | -6.03        | 1                | 4                    |
| Asia          | Retail   | unknown      | unknown     | Guest         | 198482909         | 193345450          | -5137459 | -2.59        | 1                | 5                    |
| Asia          | Shopify  | Retirees     | Families    | Existing      | 1389991           | 1271585            | -118406  | -8.52        | 1                | 6                    |
| Canada        | Retail   | Middle Aged  | Families    | Existing      | 13313829          | 13213775           | -100054  | -0.75        | 1                | 3                    |
| Canada        | Shopify  | Retirees     | Families    | Existing      | 513072            | 470064             | -43008   | -8.38        | 1                | 7                    |
| Europe        | Retail   | Young Adults | Families    | New           | 144615            | 157368             | 12753    | 8.82         | 1                | 10                   |
| Europe        | Shopify  | Retirees     | Families    | Existing      | 127488            | 92871              | -34617   | -27.15       | 1                | 3                    |
| Oceania       | Retail   | unknown      | unknown     | Guest         | 260004300         | 254520300          | -5484000 | -2.11        | 1                | 6                    |
| Oceania       | Shopify  | Retirees     | Families    | Existing      | 3011069           | 2847349            | -163720  | -5.44        | 1                | 6                    |
| South America | Retail   | unknown      | unknown     | Guest         | 65868404          | 65589252           | -279152  | -0.42        | 1                | 2                    |
| South America | Shopify  | Retirees     | Couples     | New           | 20123             | 15661              | -4462    | -22.17       | 1                | 4                    |
| USA           | Retail   | unknown      | unknown     | Guest         | 67668609          | 66950452           | -718157  | -1.06        | 1                | 7                    |
| USA           | Shopify  | Retirees     | Families    | Existing      | 813264            | 718304             | -94960   | -11.68       | 1                | 3                    |

```mysql
SELECT *
FROM data_mart.sales_variance
WHERE variance_pct_ranking = 1
ORDER BY 1, 2;
```
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;region&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | platform | &nbsp;&nbsp;&nbsp;age_band&nbsp;&nbsp;&nbsp; | demographic | customer_type | cml_sales_4wk_pre | cml_sales_4wk_post | variance | variance_pct | variance_ranking | variance_pct_ranking |
|---------------|----------|-------------|-------------|---------------|-------------------|--------------------|----------|--------------|------------------|----------------------|
| Africa        | Retail   | unknown     | unknown     | Existing      | 5893933           | 5494930            | -399003  | -6.77        | 2                | 1                    |
| Africa        | Shopify  | Retirees    | Families    | New           | 63323             | 56820              | -6503    | -10.27       | 8                | 1                    |
| Asia          | Retail   | unknown     | unknown     | Existing      | 5318073           | 4829601            | -488472  | -9.19        | 5                | 1                    |
| Asia          | Shopify  | Middle Aged | Families    | New           | 123202            | 105421             | -17781   | -14.43       | 7                | 1                    |
| Canada        | Retail   | unknown     | unknown     | Existing      | 1279546           | 1231370            | -48176   | -3.77        | 3                | 1                    |
| Canada        | Shopify  | Middle Aged | Couples     | New           | 57210             | 44666              | -12544   | -21.93       | 5                | 1                    |
| Europe        | Retail   | Middle Aged | Families    | Existing      | 3446016           | 3470095            | 24079    | 0.70         | 4                | 1                    |
| Europe        | Shopify  | Retirees    | Families    | New           | 3750              | 1528               | -2222    | -59.25       | 9                | 1                    |
| Oceania       | Retail   | unknown     | unknown     | Existing      | 7240361           | 6587011            | -653350  | -9.02        | 5                | 1                    |
| Oceania       | Shopify  | Middle Aged | Families    | New           | 247602            | 213786             | -33816   | -13.66       | 7                | 1                    |
| South America | Retail   | unknown     | unknown     | Existing      | 34577             | 31723              | -2854    | -8.25        | 2                | 1                    |
| South America | Shopify  | Middle Aged | Families    | New           | 5079              | 3440               | -1639    | -32.27       | 4                | 1                    |
| USA           | Retail   | unknown     | unknown     | Existing      | 2476907           | 2354926            | -121981  | -4.92        | 4                | 1                    |
| USA           | Shopify  | Retirees    | Families    | New           | 29495             | 24730              | -4765    | -16.16       | 12               | 1                    |
