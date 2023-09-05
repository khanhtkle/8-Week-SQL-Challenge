----------------------------------------
-- C. Challenge Payment Question --
----------------------------------------
-- 		The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
-- 			- Monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan.
-- 			- Upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start iMONTHediately.
-- 			- Upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period.
-- 			- Once a customer churns they will no longer make payments.

-- 	1. Create a table `trackers` from `subscriptions` table :

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

-- 	2. Create a table `monthly_plans` from `trackers` table:

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

-- 	3. Create a table `annual_plans` from `trackers` table:

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

-- 	4. Create a table `payment_calculations` from `monthly_plans`, `annual_plans`, and `plans` tables:

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

-- 	5. Create a table `payments` from `payment_calculations` table:

DROP TABLE IF EXISTS foodie_fi.payments;
CREATE TABLE foodie_fi.payments AS
  (SELECT customer_id,
          plan_id,
          plan_name,
          payment_date,
          CASE
              WHEN previous_plan_id < plan_id
                   AND estimated_day_between_previous_plan < actual_day_between_previous_plan THEN price - previous_price
              ELSE price
          END AS price,
          payment
   FROM foodie_fi.payment_calculations AS pc);
   
SELECT *
FROM foodie_fi.payments
WHERE YEAR(payment_date) = 2020;
