-------------------------------------
-- A. Data Cleansing Steps --
-------------------------------------
--	In a single query, perform the following operations and generate a new table the `data_mart` schema named `clean_weekly_sales`:
--		- Convert the `week_date` to a DATE format.
--		- Add a `week_number` as the second column for each `week_date` value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc.
--		- Add a `month_number` with the calendar month for each `week_date` value as the 3rd column.
--		- Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values.
--		- Add a new column called `age_band` after the original `segment` column using the following mapping on the number inside the `segment` value.
--		- Add a new `demographic` column using the following mapping for the first letter in the `segment` values.
--		- Ensure all 'null' string values with an 'unknown' string value in the original `segment` column as well as the new `age_band` and `demographic` columns.
--		- Generate a new `avg_transaction` column as the `sales` value divided by `transactions` rounded to 2 decimal places for each record.

DROP TABLE IF EXISTS data_mart.dbo.clean_weekly_sales;
SELECT CONVERT(DATE, week_date, 3) AS week_date,
       DATEPART(ww, CONVERT(DATE, week_date, 3)) AS week_number,
       MONTH(CONVERT(DATE, week_date, 3)) AS month_number,
       YEAR(CONVERT(DATE, week_date, 3)) AS calendar_year,
       CASE WHEN region = 'USA' THEN 'USA'
			WHEN region = 'SOUTH AMERICA' THEN 'South America'
			ELSE UPPER(LEFT(region, 1)) + LOWER(SUBSTRING(region, 2, LEN(region))) 
	   END AS region,
       platform,
       COALESCE(segment, 'unknown') AS segment,
       CASE
           WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
           WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
           WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
           ELSE 'unknown'
       END AS age_band,
       CASE
           WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
           WHEN LEFT(segment, 1) = 'F' THEN 'Families'
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
