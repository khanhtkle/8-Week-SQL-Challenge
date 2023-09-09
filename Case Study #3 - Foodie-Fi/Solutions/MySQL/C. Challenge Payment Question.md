# :avocado: Case Study 3 - Foodie-Fi

## C. Challenge Payment Question

<picture>
  <img src="https://img.shields.io/badge/mysql-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
#### - Monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan.
#### - Upgrades from `basic monthly` to `pro monthly` or `pro anual` are reduced by the current paid amount in that month and start immediately.
#### - Upgrades from `pro monthly` to `pro annual` are paid at the end of the current billing period and also starts at the end of the month period.
#### - Once a customer churns they will no longer make payments.

<br>

1. Create a table `trackers` from `subscriptions` table :
- In this initial table, our goal is to define and clarify the starting and ending points of each customer's subscription periods. This will allow us to easily apply some techniques to expand our data afterwards.

	- Establish the core  by including the `customer_id`, `plan_id`, and `start_date`.
 	- Rename the `start_date` column as `first_date` for better alignment with the context.
  	- Add a column `d_date` to indicate:
  	  
  		- the timestamp when the customers discontinue their subscriptions.
  	 	- the timestamp when the customers make a transitions from an old subscription plan to a new one.
  	  	- the current timestamp when the data is queried from the database for those customers who are still actively using the service.
```mysql
DROP TABLE IF EXISTS foodie_fi.trackers;
CREATE TABLE foodie_fi.trackers AS
  (SELECT customer_id,
          plan_id,
          start_date AS first_date,
          CASE
              WHEN plan_id = 4 THEN start_date
              ELSE LEAD(start_date, 1, CAST(CURRENT_TIMESTAMP() AS DATE)) OVER (PARTITION BY customer_id
										ORDER BY start_date)
          END AS d_date
   FROM foodie_fi.subscriptions);

SELECT *
FROM foodie_fi.trackers;
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

> Note: The presented dataset comprises 20 out of 2,650 rows of the `trackers` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19`.

<br>

2. Create a table `monthly_plans` from `trackers` table:
- In this second table, our goal is to specify the timestamp when the customers initiate their monthly subscriptions and when their subscription renewals take place. This will establish the foundation for us to precisely calculate the customer's payments later.

	- Establish the core by including the `customer_id`, `plan_id`, and `first_date`.
   
 	- Include another `first_date` column, rename it as `start_date`, and apply recursive common table expression to generate the timestamps for monthly subscription renewals, with the constraint on `d_date`.

	- Add a column `estimated_new_start_date`, which also signifies the estimated timestamps for monthly subscription renewals, without being confined by `d_date`. The purpose behind this will be explained in a subsequent step.
```mysql
DROP TABLE IF EXISTS foodie_fi.monthly_plans;
CREATE TABLE foodie_fi.monthly_plans AS
  (WITH RECURSIVE recursive_cte AS
     (SELECT customer_id,
             plan_id,
             first_date,
             first_date AS start_date,
             d_date
      FROM foodie_fi.trackers
      WHERE plan_id IN ('1', '2')
      UNION ALL 
      SELECT customer_id,
	     plan_id,
             first_date,
             DATE_ADD(start_date, INTERVAL 1 MONTH),
             d_date
      FROM recursive_cte
      WHERE DATE_ADD(start_date, INTERVAL 1 MONTH) < d_date)
   SELECT customer_id,
	  plan_id,
          first_date,
          CASE
              WHEN DAY(first_date) IN ('29', '30', '31') THEN DATE_ADD(first_date, INTERVAL (TIMESTAMPDIFF(MONTH, first_date, start_date)) MONTH)
              ELSE start_date
	  END AS start_date,
          d_date,
          CASE
	      WHEN DAY(first_date) IN ('29', '30', '31') THEN DATE_ADD(first_date, INTERVAL (TIMESTAMPDIFF(MONTH, first_date, start_date) + 1) MONTH)
              ELSE DATE_ADD(start_date, INTERVAL 1 MONTH)
	  END AS estimated_new_start_date
   FROM recursive_cte
   ORDER BY 1, 4);

SELECT *
FROM foodie_fi.monthly_plans;
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

> Note: The presented dataset comprises 21 out of 17,010 rows of the `monthly_plans` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19` with their respective `start_date` in the year 2020.

<br>

3. Create a table `annual_plans` from `trackers` table:
- In this third table, our goal is to specify the timestamp when the customers initiate their annual subscriptions and when their subscription renewals take place. This operation closely mirrors the one with `monthly_plans` table and it will continue to establish the foundation for us to precisely calculate the customer's payments later.

	- Establish the core by including the `customer_id`, `plan_id`, and `first_date`.
   
 	- Include another `first_date` column, rename it as `start_date`, and apply recursive common table expression to generate the timestamps for annual subscription renewals, with the constraint on `d_date`.

	- Add a column `estimated_new_start_date`, which signifies the estimated timestamps for annually subscription renewals, without being confined by `d_date`. The purpose behind this will be explained in a subsequent step.
```mysql
DROP TABLE IF EXISTS foodie_fi.annual_plans;
CREATE TABLE foodie_fi.annual_plans AS
  (WITH RECURSIVE recursive_cte AS
     (SELECT customer_id,
             plan_id,
             first_date,
             first_date AS start_date,
             d_date
      FROM foodie_fi.trackers
      WHERE plan_id = 3
      UNION ALL 
      SELECT customer_id,
	     plan_id,
             first_date,
             DATE_ADD(start_date, INTERVAL 1 YEAR),
             d_date
      FROM recursive_cte
      WHERE DATE_ADD(start_date, INTERVAL 1 YEAR) < d_date) 
   SELECT customer_id,
	  plan_id,
          first_date,
          CASE
              WHEN DAY(first_date) = 29
		   AND MONTH(first_date) = 2 THEN DATE_ADD(first_date, INTERVAL (TIMESTAMPDIFF(YEAR, first_date, start_date)) YEAR)
	      ELSE start_date
	  END AS start_date,
          d_date,
          CASE
	      WHEN DAY(first_date) = 29
		   AND MONTH(first_date) = 2 THEN DATE_ADD(first_date, INTERVAL (TIMESTAMPDIFF(YEAR, first_date, start_date) + 1) YEAR)
	      ELSE DATE_ADD(start_date, INTERVAL 1 YEAR)
          END AS estimated_renew_start_date
   FROM recursive_cte
   ORDER BY 1, 4);

SELECT *
FROM foodie_fi.annual_plans;
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

> Note: The presented dataset comprises 9 out of 786 rows of the `annual_plans` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19`.

<br>

4. Create a table `payment_calculations` from `monthly_plans`, `annual_plans`, and `plans` tables:

- In this fourth table, our objective is to combine all the subscription initiate and renewal timestamps for customers across both types of subscription plans, monthly and annually. Additionally, we will create and calculate certain factors that will play as key metrics to calculate the customer's payments in the next step.

	- Apply the `UNION ALL` operation and establish the core by including the `customer_id`, `plan_id`, and `start_date`.

 	- Rename the `start_date` column as `payment_date` for better alignment with the context.
 
 	- Include the `plan_name` alongside their respective `customer_id`, `plan_id`, and `payment_date`.
 
  	- Add a column `previous_plan_id`, which signifies the subscription `plan_id` of the preceding period..
  
  	- Add a column `estimated_day_between_previous_plan`, which calculate the number of days between `start_date` of the previous subscription periods and theirs `estimated_renew_start_date`.
  	
  	- Add a column `actual_day_between_previous_plan`, which calculate the number of days between `start_date` of the previous subscription periods and `start_date` of the current periods.
  
  	- Add a column `previous_price`, which signifies the price of the subscription plan using in the preceding period.
  
  	- Include the `plan_name` and `price` alongside their respective `plan_id` using in the current period.
  	
  	- Add a column `payment`, which assigns sequential numbers to each customer's subscription payment.
```mysql
DROP TABLE IF EXISTS foodie_fi.payment_calculations;
CREATE TABLE foodie_fi.payment_calculations AS
  (WITH expanded_trackers_cte AS
     (SELECT *
      FROM foodie_fi.monthly_plans
      UNION ALL 
      SELECT *
      FROM foodie_fi.annual_plans) 
   SELECT customer_id,
	  et.plan_id,
          plan_name,
          start_date AS payment_date,
          LAG(et.plan_id) OVER (PARTITION BY customer_id
				ORDER BY start_date) AS previous_plan_id,
	  LAG(TIMESTAMPDIFF(DAY, start_date, estimated_new_start_date)) OVER (PARTITION BY customer_id
									      ORDER BY start_date) AS estimated_day_between_previous_plan,
	  TIMESTAMPDIFF(DAY, LAG(et.start_date) OVER (PARTITION BY customer_id
						      ORDER BY start_date), start_date) AS actual_day_between_previous_plan,
	  LAG(price) OVER (PARTITION BY customer_id
			   ORDER BY start_date) previous_price,
	  price,
          ROW_NUMBER() OVER (PARTITION BY customer_id
			     ORDER BY start_date) AS payment
   FROM expanded_trackers_cte AS et
   JOIN foodie_fi.plans AS pl ON pl.plan_id = et.plan_id);

SELECT *
FROM foodie_fi.payment_calculations;
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

> Note: The presented dataset comprises 24 out of 17,796 rows of the `payment_calculations` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19` with their respective `payment_date` in the year 2020.

<br>

5. Create a table `payments` from `payment_calculations` table:
- In this concluding table, our goal is to take into account all the factors prepared in the previous stage to calculate the payment price for each customer, aggregate the data to generate the desired dataset that matches the example output.

	- Eshtablish the desired data by including `customer_id`, `plan_id`, `plan_name`, `payment_date`, and `payment`.

  	- Add a column `price`, which not only signifies the cost of the subsciption plan being used in the current period but also accounts for any plan upgrades that occur within the same period, with the price of the new plan being reduced by the current paid amount.
```mysql
DROP TABLE IF EXISTS foodie_fi.payments;
CREATE TABLE foodie_fi.payments AS
  (SELECT customer_id,
          plan_id,
          plan_name,
          payment_date,
          CASE
              WHEN previous_plan_id < plan_id
                   AND actual_day_between_previous_plan < estimated_day_between_previous_plan THEN price - previous_price
              ELSE price
          END AS price,
          payment
   FROM foodie_fi.payment_calculations AS pc);
   
SELECT *
FROM foodie_fi.payments
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

> Note: The presented dataset comprises 24 out of 17,796 rows of the `payments` table, featuring only `customer_id` values `1`, `2`, `11`, `13`, `15`, `16`, `18`, `19` with their respective `payment_date` in the year 2020.

---
My solution for **[D. Outside The Box Questions](D.%20Outside%20The%20Box%20Questions.md)**.
