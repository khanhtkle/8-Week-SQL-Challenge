# :avocado: Case Study 3 - Foodie-Fi

## A. Pizza Metrics

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Based off the 8 sample customers provided in the sample from the `subscriptions` table, write a brief description about each customer’s onboarding journey.
```tsql
SELECT su.*,
       plan_name,
       price
FROM foodie_fi.dbo.subscriptions AS su
JOIN foodie_fi.dbo.plans AS pl ON pl.plan_id = su.plan_id
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)

SELECT * 
FROM pizza_runner.dbo.cleaned_runner_orders;
```
| customer_id | plan_id | start_date | plan_name     | price  |
|-------------|---------|------------|---------------|--------|
| 1           | 0       | 2020-08-01 | trial         | 0.00   |
| 1           | 1       | 2020-08-08 | basic monthly | 9.90   |
| 2           | 0       | 2020-09-20 | trial         | 0.00   |
| 2           | 3       | 2020-09-27 | pro annual    | 199.00 |
| 11          | 0       | 2020-11-19 | trial         | 0.00   |
| 11          | 4       | 2020-11-26 | churn         | NULL   |
| 13          | 0       | 2020-12-15 | trial         | 0.00   |
| 13          | 1       | 2020-12-22 | basic monthly | 9.90   |
| 13          | 2       | 2021-03-29 | pro monthly   | 19.90  |
| 15          | 0       | 2020-03-17 | trial         | 0.00   |
| 15          | 2       | 2020-03-24 | pro monthly   | 19.90  |
| 15          | 4       | 2020-04-29 | churn         | NULL   |
| 16          | 0       | 2020-05-31 | trial         | 0.00   |
| 16          | 1       | 2020-06-07 | basic monthly | 9.90   |
| 16          | 3       | 2020-10-21 | pro annual    | 199.00 |
| 18          | 0       | 2020-07-06 | trial         | 0.00   |
| 18          | 2       | 2020-07-13 | pro monthly   | 19.90  |
| 19          | 0       | 2020-06-22 | trial         | 0.00   |
| 19          | 2       | 2020-06-29 | pro monthly   | 19.90  |
| 19          | 3       | 2020-08-29 | pro annual    | 199.00 |

- Drawing from the presented data:
  - Customer 1: Started trial on August 1, 2020. Upgraded to `basic monthly` plan on August 8, 2020.
  - Customer 2: Started trial on September 20, 2020. Upgraded to `pro annual` plan on September 27, 2020.
  - Customer 11: Started trial on November 19, 2020. Churned out on November 26, 2020.
  - Customer 13: Started trial on December 15, 2020. Upgraded to `basic monthly` plan on December 22, 2020. Further upgraded to `pro monthly` plan on March 29, 2021.
  - Customer 15: Started trial on March 17, 2020. Upgraded to `pro monthly` plan on March 24, 2020. Churned out on April 29, 2020.
  - Customer 16: Started trial on May 31, 2020. Upgraded to `basic monthly` plan on June 7, 2020. Further upgraded to `pro annual` plan on October 21, 2020.
  - Customer 18: Started trial on July 6, 2020. Upgraded to `pro monthly` plan on July 13, 2020.
  - Customer 19: Started trial on June 22, 2020. Upgraded to `pro monthly` plan on June 29, 2020. Further upgraded to `pro annual` plan on August 29, 2020.

---
My solution for **[B. Data Analysis Questions](B.%20Data%20Analysis%20Questions.md)**.
