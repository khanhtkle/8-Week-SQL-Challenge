# :shopping_cart: Case Study 5 - Data Mart

## A. Data Cleansing Steps

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### In a single query, perform the following operations and generate a new table in the `data_mart` schema named `clean_weekly_sales`:
- ### Convert the `week_date` to a `DATE` format.
- ### Add a `week_number` as the second column for each `week_date` value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc.
- ### Add a `month_number` with the calendar month for each `week_date` value as the 3rd column.
- ### Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values.
- ### Add a new column called `age_band` after the original `segment` column using the following mapping on the number inside the `segment` value.
- ### Add a new `demographic` column using the following mapping for the first letter in the `segment` values.
- ### Ensure all `null` string values with an `unknown` string value in the original `segment` column as well as the new `age_band` and `demographic` columns.
- ### Generate a new `avg_transaction` column as the sales value divided by `transactions` rounded to 2 decimal places for each record.

</br>

```tsql
DROP TABLE IF EXISTS data_mart.dbo.clean_weekly_sales;
SELECT CONVERT(DATE, week_date, 3) AS week_date,
       DATEPART(ww, CONVERT(DATE, week_date, 3)) AS week_number,
       MONTH(CONVERT(DATE, week_date, 3)) AS month_number,
       YEAR(CONVERT(DATE, week_date, 3)) AS calendar_year,
       CASE
           WHEN region = 'USA' THEN 'USA'
           WHEN region = 'SOUTH AMERICA' THEN 'South America'
           ELSE UPPER(LEFT(region, 1)) + LOWER(SUBSTRING(region, 2, LEN(region)))
       END AS region,
       platform,
       COALESCE(SEGMENT, 'unknown') AS SEGMENT,
       CASE
           WHEN RIGHT(SEGMENT, 1) = '1' THEN 'Young Adults'
           WHEN RIGHT(SEGMENT, 1) = '2' THEN 'Middle Aged'
           WHEN RIGHT(SEGMENT, 1) IN ('3', '4') THEN 'Retirees'
           ELSE 'unknown'
       END AS age_band,
       CASE
           WHEN LEFT(SEGMENT, 1) = 'C' THEN 'Couples'
           WHEN LEFT(SEGMENT, 1) = 'F' THEN 'Families'
           ELSE 'unknown'
       END AS demographic,
       customer_type,
       transactions,
       CONVERT(BIGINT, sales) AS sales,
       CAST(ROUND(1.0 * sales / transactions, 2) AS REAL) AS avg_transaction
INTO data_mart.dbo.clean_weekly_sales
FROM data_mart.dbo.weekly_sales;

SELECT *
FROM data_mart.dbo.clean_weekly_sales
ORDER BY week_date;
```
| &nbsp;week_date&nbsp;&nbsp; | week_number | month_number | calendar_year |&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;region&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | platform | segment | &nbsp;&nbsp;&nbsp;age_band&nbsp;&nbsp;&nbsp; | demographic | customer_type | transactions | sales   | avg_transaction |
|------------|-------------|--------------|---------------|---------------|----------|---------|--------------|-------------|---------------|--------------|---------|-----------------|
| 2018-03-26 | 13          | 3            | 2018          | Canada        | Retail   | F2      | Middle Aged  | Families    | New           | 16700        | 632396  | 37.87           |
| 2018-03-26 | 13          | 3            | 2018          | USA           | Retail   | C3      | Retirees     | Couples     | Existing      | 77859        | 4724108 | 60.68           |
| 2018-03-26 | 13          | 3            | 2018          | Africa        | Retail   | F1      | Young Adults | Families    | New           | 23569        | 905823  | 38.43           |
| 2018-03-26 | 13          | 3            | 2018          | Europe        | Retail   | F1      | Young Adults | Families    | New           | 903          | 39900   | 44.19           |
| 2018-03-26 | 13          | 3            | 2018          | South America | Shopify  | C1      | Young Adults | Couples     | New           | 13           | 1864    | 143.38          |
| 2018-03-26 | 13          | 3            | 2018          | Canada        | Shopify  | null    | unknown      | unknown     | New           | 52           | 8839    | 169.98          |
| 2018-03-26 | 13          | 3            | 2018          | Oceania       | Retail   | F1      | Young Adults | Families    | Existing      | 126157       | 6864699 | 54.41           |
| 2018-03-26 | 13          | 3            | 2018          | Oceania       | Shopify  | C4      | Retirees     | Couples     | Existing      | 425          | 77934   | 183.37          |
| 2018-03-26 | 13          | 3            | 2018          | Europe        | Retail   | C2      | Middle Aged  | Couples     | Existing      | 7452         | 373224  | 50.08           |
| 2018-03-26 | 13          | 3            | 2018          | Canada        | Shopify  | C1      | Young Adults | Couples     | New           | 52           | 6622    | 127.35          |

> Note: The presented dataset comprises 10 out of 17,117 rows of the `clean_weekly_sales` table.

---
My solution for **[B. Data Exploration](B.%20Data%20Exploration.md)**.
