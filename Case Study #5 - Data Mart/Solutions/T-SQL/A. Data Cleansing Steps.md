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

```

---
My solution for **[B. Data Exploration](B.%20Data/%20Exploration.md)**.
