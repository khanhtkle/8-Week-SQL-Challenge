----------------------------------------
-- C. Challenge Payment Question --
----------------------------------------
-- 	The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
-- 		- Monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan.
-- 		- Upgrades from `basic monthly` to `pro monthly` or `pro anual` are reduced by the current paid amount in that month and start immediately.
-- 		- Upgrades from `pro monthly` to `pro annual` are paid at the end of the current billing period and also starts at the end of the month period.
-- 		- Once a customer churns they will no longer make payments.

--	1. Create a table `trackers` from `subscriptions` table :
--	- In this initial table, our goal is to define and clarify the starting and ending points of each customer's subscription periods. This will allow us to easily apply some techniques to expand our data afterwards.
--		- Establish the core  by including the `customer_id`, `plan_id`, and `start_date`.
--		- Rename the `start_date` column as `first_date` for better alignment with the context.
--		- Add a column `d_date` to indicate:
--			- the timestamp when the customers discontinue their subscriptions.
--			- the timestamp when the customers make a transitions from an old subscription plan to a new one.
--			- the current timestamp when the data is queried from the database for those customers who are still actively using the service.

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

--	2. Create a table `monthly_plans` from `trackers` table:
--	- In this second table, our goal is to specify the timestamp when the customers initiate their monthly subscriptions and when their subscription renewals take place. This will establish the foundation for us to precisely calculate the customer's payments later.
--		- Establish the core by including the `customer_id`, `plan_id`, and `first_date`.
--		- Include another `first_date` column, rename it as `start_date`, and apply recursive common table expression to generate the timestamps for monthly subscription renewals, with the constraint on `d_date`.
--		- Add a column `estimated_new_start_date`, which also signifies the estimated timestamps for monthly subscription renewals, without being confined by `d_date`. The purpose behind this will be explained in a subsequent step.

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

--	3. Create a table `annual_plans` from `trackers` table:
--	- In this third table, our goal is to specify the timestamp when the customers initiate their annual subscriptions and when their subscription renewals take place. This operation closely mirrors the one with `monthly_plans` table and it will continue to establish the foundation for us to precisely calculate the customer's payments later.
--		- Establish the core by including the `customer_id`, `plan_id`, and `first_date`.
--		- Include another `first_date` column, rename it as `start_date`, and apply recursive common table expression to generate the timestamps for annual subscription renewals, with the constraint on `d_date`.
--		- Add a column `estimated_new_start_date`, which signifies the estimated timestamps for annually subscription renewals, without being confined by `d_date`. The purpose behind this will be explained in a subsequent step.

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

--	4. Create a table `payment_calculations` from `monthly_plans`, `annual_plans`, and `plans` tables:
--	- In this fourth table, our objective is to combine all the subscription initiate and renewal timestamps for customers across both types of subscription plans, monthly and annually. Additionally, we will create and calculate certain factors that will play as key metrics to calculate the customer's payments in the next step.
--		- Apply the `UNION ALL` operation and establish the core by including the `customer_id`, `plan_id`, and `start_date`.
-- 		- Rename the `start_date` column as `payment_date` for better alignment with the context.
-- 		- Include the `plan_name` alongside their respective `customer_id`, `plan_id`, and `payment_date`.
-- 		- Add a column `previous_plan_id`, which signifies the subscription `plan_id` of the preceding period..
-- 		- Add a column `estimated_day_between_previous_plan`, which calculate the number of days between `start_date` of the previous subscription periods and theirs `estimated_renew_start_date`.	
--		- Add a column `actual_day_between_previous_plan`, which calculate the number of days between `start_date` of the previous subscription periods and `start_date` of the current periods.
--		- Add a column `previous_price`, which signifies the price of the subscription plan using in the preceding period.
--		- Include the `plan_name` and `price` alongside their respective `plan_id` using in the current period.
--		- Add a column `payment`, which assigns the sequential numbers of each customer's subscription payment.

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

--	5. Create a table `payments` from `payment_calculations` table:
--	- In this concluding table, our goal is to take into account all the factors prepared in the previous stage to calculate the payment price for each customer, aggregate the data to generate the desired dataset that matches the example output.
--		- Eshtablish the desired data by including `customer_id`, `plan_id`, `plan_name`, `payment_date`, and `payment`.
--		- Add a column `price`, which not only signifies the cost of the subsciption plan being used in the current period but also accounts for any plan upgrades that occur within the same period, with the price of the new plan being reduced by the current paid amount.

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
