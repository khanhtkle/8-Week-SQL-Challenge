# :avocado: Case Study 3 - Foodie-Fi

## C. Challenge Payment Question

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
- Monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan.
- Upgrades from `basic monthly` to `pro monthly` or `pro anual` are reduced by the current paid amount in that month and start immediately.
- Upgrades from `pro monthly` to `pro annual` are paid at the end of the current billing period and also starts at the end of the month period.
- Once a customer churns they will no longer make payments.

1. Create a table `trackers` from `subscriptions` table :
```tsql
DROP TABLE IF EXISTS foodie_fi.dbo.trackers;
SELECT customer_id,
       plan_id,
       start_date AS first_date,
       CASE
           WHEN plan_id = 4 THEN start_date
           ELSE LEAD(start_date, 1, GETDATE()) OVER (PARTITION BY customer_id
                                                     ORDER BY start_date)
       END AS d_date 
INTO foodie_fi.dbo.trackers
FROM foodie_fi.dbo.subscriptions;

SELECT *
FROM foodie_fi.dbo.trackers;
```
| customer_id | plan_id | first_date | d_date     |
|-------------|---------|------------|------------|
| 1           | 0       | 2020-08-01 | 2020-08-08 |
| 1           | 1       | 2020-08-08 | 2023-05-14 |
| 2           | 0       | 2020-09-20 | 2020-09-27 |
| 2           | 3       | 2020-09-27 | 2023-05-14 |
| 11          | 0       | 2020-11-19 | 2020-11-26 |
| 11          | 4       | 2020-11-26 | 2020-11-26 |
| 13          | 0       | 2020-12-15 | 2020-12-22 |
| 13          | 1       | 2020-12-22 | 2021-03-29 |
| 13          | 2       | 2021-03-29 | 2023-05-14 |
| 15          | 0       | 2020-03-17 | 2020-03-24 |
| 15          | 2       | 2020-03-24 | 2020-04-29 |
| 15          | 4       | 2020-04-29 | 2020-04-29 |
| 16          | 0       | 2020-05-31 | 2020-06-07 |
| 16          | 1       | 2020-06-07 | 2020-10-21 |
| 16          | 3       | 2020-10-21 | 2023-05-14 |
| 18          | 0       | 2020-07-06 | 2020-07-13 |
| 18          | 2       | 2020-07-13 | 2023-05-14 |
| 19          | 0       | 2020-06-22 | 2020-06-29 |
| 19          | 2       | 2020-06-29 | 2020-08-29 |
| 19          | 3       | 2020-08-29 | 2023-05-14 |

- The presented data comprises 20 out of 2,650 rows of the `trackers` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19`.

2. Create a table `monthly_plans` from `trackers` table:
```tsql
DROP TABLE IF EXISTS foodie_fi.dbo.monthly_plans;
WITH recursive_cte AS
  (SELECT customer_id,
          plan_id,
          first_date,
          first_date AS start_date,
          d_date
   FROM foodie_fi.dbo.trackers
   WHERE plan_id IN ('1', '2')
   UNION ALL 
   SELECT customer_id,
	  plan_id,
	  first_date,
	  DATEADD(mm, 1, start_date),
	  d_date
   FROM recursive_cte
   WHERE DATEADD(mm, 1, start_date) < d_date)
SELECT customer_id,
       plan_id,
       first_date,
       CASE
           WHEN DAY(first_date) IN ('29', '30', '31') THEN DATEADD(mm, DATEDIFF(mm, first_date, start_date), first_date)
           ELSE start_date
       END AS start_date,
       d_date,
       CASE
           WHEN DAY(first_date) IN ('29', '30', '31') THEN DATEADD(mm, DATEDIFF(mm, first_date, start_date) + 1, first_date)
           ELSE DATEADD(mm, 1, start_date)
       END AS estimated_new_start_date 
INTO foodie_fi.dbo.monthly_plans
FROM recursive_cte;

SELECT *
FROM foodie_fi.dbo.monthly_plans
ORDER BY customer_id,
         start_date;
```
| customer_id | plan_id | first_date | start_date | d_date     | estimated_new_start_date |
|-------------|---------|------------|------------|------------|--------------------------|
| 1           | 1       | 2020-08-08 | 2020-08-08 | 2023-05-14 | 2020-09-08               |
| 1           | 1       | 2020-08-08 | 2020-09-08 | 2023-05-14 | 2020-10-08               |
| 1           | 1       | 2020-08-08 | 2020-10-08 | 2023-05-14 | 2020-11-08               |
| 1           | 1       | 2020-08-08 | 2020-11-08 | 2023-05-14 | 2020-12-08               |
| 1           | 1       | 2020-08-08 | 2020-12-08 | 2023-05-14 | 2021-01-08               |
| 13          | 1       | 2020-12-22 | 2020-12-22 | 2021-03-29 | 2021-01-22               |
| 15          | 2       | 2020-03-24 | 2020-03-24 | 2020-04-29 | 2020-04-24               |
| 15          | 2       | 2020-03-24 | 2020-04-24 | 2020-04-29 | 2020-05-24               |
| 16          | 1       | 2020-06-07 | 2020-06-07 | 2020-10-21 | 2020-07-07               |
| 16          | 1       | 2020-06-07 | 2020-07-07 | 2020-10-21 | 2020-08-07               |
| 16          | 1       | 2020-06-07 | 2020-08-07 | 2020-10-21 | 2020-09-07               |
| 16          | 1       | 2020-06-07 | 2020-09-07 | 2020-10-21 | 2020-10-07               |
| 16          | 1       | 2020-06-07 | 2020-10-07 | 2020-10-21 | 2020-11-07               |
| 18          | 2       | 2020-07-13 | 2020-07-13 | 2023-05-14 | 2020-08-13               |
| 18          | 2       | 2020-07-13 | 2020-08-13 | 2023-05-14 | 2020-09-13               |
| 18          | 2       | 2020-07-13 | 2020-09-13 | 2023-05-14 | 2020-10-13               |
| 18          | 2       | 2020-07-13 | 2020-10-13 | 2023-05-14 | 2020-11-13               |
| 18          | 2       | 2020-07-13 | 2020-11-13 | 2023-05-14 | 2020-12-13               |
| 18          | 2       | 2020-07-13 | 2020-12-13 | 2023-05-14 | 2021-01-13               |
| 19          | 2       | 2020-06-29 | 2020-06-29 | 2020-08-29 | 2020-07-29               |
| 19          | 2       | 2020-06-29 | 2020-07-29 | 2020-08-29 | 2020-08-29               |

 - The presented data comprises 21 out of 17,010 rows of the `monthly_plans` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19` with their respective `start_date` in the year 2020.

3. Create a table `annual_plans` from `trackers` table:
```tsql
DROP TABLE IF EXISTS foodie_fi.dbo.annual_plans;
WITH recursive_cte AS
  (SELECT customer_id,
          plan_id,
          first_date,
          first_date AS start_date,
          d_date
   FROM foodie_fi.dbo.trackers
   WHERE plan_id = 3
   UNION ALL 
   SELECT customer_id,
	  plan_id,
	  first_date,
	  DATEADD(yy, 1, start_date),
	  d_date
   FROM recursive_cte
   WHERE DATEADD(yy, 1, start_date) < d_date)
SELECT customer_id,
       plan_id,
       first_date,
       CASE
           WHEN DAY(first_date) = 29
                AND MONTH(first_date) = 2 THEN DATEADD(yy, DATEDIFF(yy, first_date, start_date), first_date)
           ELSE start_date
       END AS start_date,
       d_date,
       CASE
           WHEN DAY(first_date) = 29
                AND MONTH(first_date) = 2 THEN DATEADD(yy, DATEDIFF(yy, first_date, start_date) + 1, first_date)
           ELSE DATEADD(yy, 1, start_date)
       END AS estimated_renew_start_date 
INTO foodie_fi.dbo.annual_plans
FROM recursive_cte;

SELECT *
FROM foodie_fi.dbo.annual_plans
ORDER BY customer_id,
         start_date;
```
| customer_id | plan_id | first_date | start_date | d_date     | estimated_renew_start_date |
|-------------|---------|------------|------------|------------|----------------------------|
| 2           | 3       | 2020-09-27 | 2020-09-27 | 2023-05-14 | 2021-09-27                 |
| 2           | 3       | 2020-09-27 | 2021-09-27 | 2023-05-14 | 2022-09-27                 |
| 2           | 3       | 2020-09-27 | 2022-09-27 | 2023-05-14 | 2023-09-27                 |
| 16          | 3       | 2020-10-21 | 2020-10-21 | 2023-05-14 | 2021-10-21                 |
| 16          | 3       | 2020-10-21 | 2021-10-21 | 2023-05-14 | 2022-10-21                 |
| 16          | 3       | 2020-10-21 | 2022-10-21 | 2023-05-14 | 2023-10-21                 |
| 19          | 3       | 2020-08-29 | 2020-08-29 | 2023-05-14 | 2021-08-29                 |
| 19          | 3       | 2020-08-29 | 2021-08-29 | 2023-05-14 | 2022-08-29                 |
| 19          | 3       | 2020-08-29 | 2022-08-29 | 2023-05-14 | 2023-08-29                 |

 - The presented data comprises 9 out of 786 rows of the `annual_plans` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19`.

4. Create a table `payment_calculations` from `monthly_plans`, `annual_plans`, and `plans` tables:
```tsql
DROP TABLE IF EXISTS foodie_fi.dbo.payment_calculations;
WITH expanded_trackers_cte AS
  (SELECT *
   FROM foodie_fi.dbo.monthly_plans
   UNION ALL 
   SELECT *
   FROM foodie_fi.dbo.annual_plans)
SELECT customer_id,
       et.plan_id,
       plan_name,
       start_date AS payment_date,
       LAG(et.plan_id) OVER (PARTITION BY customer_id
                             ORDER BY start_date) AS previous_plan_id,
       LAG(DATEDIFF(dd, start_date, estimated_new_start_date)) OVER (PARTITION BY customer_id
                                                                     ORDER BY start_date) AS estimated_day_between_previous_plan,
       DATEDIFF(dd, LAG(et.start_date) OVER (PARTITION BY customer_id
					     ORDER BY start_date), start_date) AS actual_day_between_previous_plan,
       LAG(price) OVER (PARTITION BY customer_id
			ORDER BY start_date) previous_price,
       price,
       ROW_NUMBER() OVER (PARTITION BY customer_id
			  ORDER BY start_date) AS payment 
INTO foodie_fi.dbo.payment_calculations
FROM expanded_trackers_cte AS et
JOIN foodie_fi.dbo.plans AS pl ON pl.plan_id = et.plan_id;

SELECT * 
FROM foodie_fi.dbo.payment_calculations;
```
| customer_id | plan_id | plan_name     | payment_date | previous_plan_id | estimated_day_between_previous_plan | actual_day_between_previous_plan | previous_price | price  | payment |
|-------------|---------|---------------|--------------|------------------|-------------------------------------|----------------------------------|----------------|--------|---------|
| 1           | 1       | basic monthly | 2020-08-08   | NULL             | NULL                                | NULL                             | NULL           | 9.90   | 1       |
| 1           | 1       | basic monthly | 2020-09-08   | 1                | 31                                  | 31                               | 9.90           | 9.90   | 2       |
| 1           | 1       | basic monthly | 2020-10-08   | 1                | 30                                  | 30                               | 9.90           | 9.90   | 3       |
| 1           | 1       | basic monthly | 2020-11-08   | 1                | 31                                  | 31                               | 9.90           | 9.90   | 4       |
| 1           | 1       | basic monthly | 2020-12-08   | 1                | 30                                  | 30                               | 9.90           | 9.90   | 5       |
| 2           | 3       | pro annual    | 2020-09-27   | NULL             | NULL                                | NULL                             | NULL           | 199.00 | 1       |
| 13          | 1       | basic monthly | 2020-12-22   | NULL             | NULL                                | NULL                             | NULL           | 9.90   | 1       |
| 15          | 2       | pro monthly   | 2020-03-24   | NULL             | NULL                                | NULL                             | NULL           | 19.90  | 1       |
| 15          | 2       | pro monthly   | 2020-04-24   | 2                | 31                                  | 31                               | 19.90          | 19.90  | 2       |
| 16          | 1       | basic monthly | 2020-06-07   | NULL             | NULL                                | NULL                             | NULL           | 9.90   | 1       |
| 16          | 1       | basic monthly | 2020-07-07   | 1                | 30                                  | 30                               | 9.90           | 9.90   | 2       |
| 16          | 1       | basic monthly | 2020-08-07   | 1                | 31                                  | 31                               | 9.90           | 9.90   | 3       |
| 16          | 1       | basic monthly | 2020-09-07   | 1                | 31                                  | 31                               | 9.90           | 9.90   | 4       |
| 16          | 1       | basic monthly | 2020-10-07   | 1                | 30                                  | 30                               | 9.90           | 9.90   | 5       |
| 16          | 3       | pro annual    | 2020-10-21   | 1                | 31                                  | 14                               | 9.90           | 199.00 | 6       |
| 18          | 2       | pro monthly   | 2020-07-13   | NULL             | NULL                                | NULL                             | NULL           | 19.90  | 1       |
| 18          | 2       | pro monthly   | 2020-08-13   | 2                | 31                                  | 31                               | 19.90          | 19.90  | 2       |
| 18          | 2       | pro monthly   | 2020-09-13   | 2                | 31                                  | 31                               | 19.90          | 19.90  | 3       |
| 18          | 2       | pro monthly   | 2020-10-13   | 2                | 30                                  | 30                               | 19.90          | 19.90  | 4       |
| 18          | 2       | pro monthly   | 2020-11-13   | 2                | 31                                  | 31                               | 19.90          | 19.90  | 5       |
| 18          | 2       | pro monthly   | 2020-12-13   | 2                | 30                                  | 30                               | 19.90          | 19.90  | 6       |
| 19          | 2       | pro monthly   | 2020-06-29   | NULL             | NULL                                | NULL                             | NULL           | 19.90  | 1       |
| 19          | 2       | pro monthly   | 2020-07-29   | 2                | 30                                  | 30                               | 19.90          | 19.90  | 2       |
| 19          | 3       | pro annual    | 2020-08-29   | 2                | 31                                  | 31                               | 19.90          | 199.00 | 3       |

 - The presented data comprises 24 out of 17,796 rows of the `payment_calculations` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19` with their respective `payment_date` in the year 2020.

5. Create a table `payments` from `payment_calculations` table:
```tsql
DROP TABLE IF EXISTS foodie_fi.dbo.payments;
SELECT customer_id,
       plan_id,
       plan_name,
       payment_date,
       CASE
           WHEN previous_plan_id < plan_id
                AND actual_day_between_previous_plan < estimated_day_between_previous_plan THEN price - previous_price
           ELSE price
       END AS price,
       payment 
INTO foodie_fi.dbo.payments
FROM foodie_fi.dbo.payment_calculations AS pc;

SELECT *
FROM foodie_fi.dbo.payments
WHERE YEAR(payment_date) = 2020;
```
| customer_id | plan_id | plan_name     | payment_date | price  | payment |
|-------------|---------|---------------|--------------|--------|---------|
| 1           | 1       | basic monthly | 2020-08-08   | 9.90   | 1       |
| 1           | 1       | basic monthly | 2020-09-08   | 9.90   | 2       |
| 1           | 1       | basic monthly | 2020-10-08   | 9.90   | 3       |
| 1           | 1       | basic monthly | 2020-11-08   | 9.90   | 4       |
| 1           | 1       | basic monthly | 2020-12-08   | 9.90   | 5       |
| 2           | 3       | pro annual    | 2020-09-27   | 199.00 | 1       |
| 13          | 1       | basic monthly | 2020-12-22   | 9.90   | 1       |
| 15          | 2       | pro monthly   | 2020-03-24   | 19.90  | 1       |
| 15          | 2       | pro monthly   | 2020-04-24   | 19.90  | 2       |
| 16          | 1       | basic monthly | 2020-06-07   | 9.90   | 1       |
| 16          | 1       | basic monthly | 2020-07-07   | 9.90   | 2       |
| 16          | 1       | basic monthly | 2020-08-07   | 9.90   | 3       |
| 16          | 1       | basic monthly | 2020-09-07   | 9.90   | 4       |
| 16          | 1       | basic monthly | 2020-10-07   | 9.90   | 5       |
| 16          | 3       | pro annual    | 2020-10-21   | 189.10 | 6       |
| 18          | 2       | pro monthly   | 2020-07-13   | 19.90  | 1       |
| 18          | 2       | pro monthly   | 2020-08-13   | 19.90  | 2       |
| 18          | 2       | pro monthly   | 2020-09-13   | 19.90  | 3       |
| 18          | 2       | pro monthly   | 2020-10-13   | 19.90  | 4       |
| 18          | 2       | pro monthly   | 2020-11-13   | 19.90  | 5       |
| 18          | 2       | pro monthly   | 2020-12-13   | 19.90  | 6       |
| 19          | 2       | pro monthly   | 2020-06-29   | 19.90  | 1       |
| 19          | 2       | pro monthly   | 2020-07-29   | 19.90  | 2       |
| 19          | 3       | pro annual    | 2020-08-29   | 199.00 | 3       |

 - The presented data comprises 24 out of 17,796 rows of the `payments` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19` with their respective `payment_date` in the year 2020.

---
My solution for **[C. Challenge Payment Question](C.%20Challenge%20Payment%20Question.md)**.
