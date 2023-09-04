----------------------------------------
-- C. Challenge Payment Question --
----------------------------------------
--		The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
--			- Monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan.
--			- Upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately.
--			- Upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period.
--			- Once a customer churns they will no longer make payments.

--	1. Create a table `trackers` from `subscriptions` table :

DROP TABLE IF EXISTS foodie_fi.dbo.trackers;
SELECT customer_id,
       plan_id,
       start_date AS first_date,
       CASE
           WHEN plan_id = 4 THEN start_date
           ELSE LEAD(start_date, 1, GETDATE()) OVER (PARTITION BY customer_id
                                                     ORDER BY start_date)
       END AS d_date INTO foodie_fi.dbo.trackers
FROM foodie_fi.dbo.subscriptions;

SELECT *
FROM foodie_fi.dbo.trackers;

--	2. Create a table `monthly_plans` from `trackers` table:

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
       END AS estimated_renew_start_date INTO foodie_fi.dbo.annual_plans
FROM recursive_cte;

SELECT *
FROM foodie_fi.dbo.annual_plans
ORDER BY customer_id,
         start_date;

--	4. Create a table `payment_calculations` from `monthly_plans`, `annual_plans`, and `plans` tables:

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
			  ORDER BY start_date) AS payment INTO foodie_fi.dbo.payment_calculations
FROM expanded_trackers_cte AS et
JOIN foodie_fi.dbo.plans AS pl ON pl.plan_id = et.plan_id;

SELECT * 
FROM foodie_fi.dbo.payment_calculations;

--	5. Create a table `payments` from `payment_calculations` table:

DROP TABLE IF EXISTS foodie_fi.dbo.payments;
SELECT customer_id,
       plan_id,
       plan_name,
       payment_date,
       CASE
           WHEN previous_plan_id < plan_id
                AND estimated_day_between_previous_plan < actual_day_between_previous_plan THEN price - previous_price
           ELSE price
       END AS price,
       payment 
INTO foodie_fi.dbo.payments
FROM foodie_fi.dbo.payment_calculations AS pc;

SELECT *
FROM foodie_fi.dbo.payments
WHERE YEAR(payment_date) = 2020;
