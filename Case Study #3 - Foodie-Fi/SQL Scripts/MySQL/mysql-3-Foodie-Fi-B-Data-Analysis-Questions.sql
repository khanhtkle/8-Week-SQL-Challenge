-------------------------------------
-- B. Data Analysis Questions --
-------------------------------------
-- 	1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM foodie_fi.subscriptions;

-- 	2. What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value

SELECT YEAR(start_date) AS year,
       MONTHNAME(start_date) AS month,
       DATE_FORMAT(start_date, '%Y-%m-01') AS start_of_month,
       COUNT(*) AS trial_plan_count
FROM foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY 1, 2, 3, MONTH(start_date)
ORDER BY MONTH(start_date);


-- 	3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`.

SELECT YEAR(start_date) AS year,
       su.plan_id,
       plan_name,
       COUNT(*) AS event_count
FROM foodie_fi.subscriptions AS su
JOIN foodie_fi.plans AS pl ON pl.plan_id = su.plan_id
WHERE YEAR(start_date) > 2020
GROUP BY 1, 2, 3
ORDER BY 2;

-- 	4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT SUM(CASE
               WHEN plan_id = 4 THEN 1
           END) AS total_churned_customer_count,
       CAST(100.0 * SUM(CASE
                            WHEN plan_id = 4 THEN 1
                        END) / COUNT(DISTINCT customer_id) AS DECIMAL(5,1)) AS total_churn_pct
FROM foodie_fi.subscriptions;

-- 	5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH next_plan_id_cte AS
  (SELECT customer_id,
          plan_id,
          LEAD(plan_id) OVER (PARTITION BY customer_id
			      ORDER BY start_date) AS next_plan_id
   FROM foodie_fi.subscriptions)
SELECT COUNT(*) AS post_trial_churned_customer_count, 
       CAST(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id)
				FROM foodie_fi.subscriptions) AS DECIMAL(5,1)) AS post_trial_churned_customer_pct
FROM next_plan_id_cte
WHERE plan_id = 0
  AND next_plan_id = 4;

-- 	6. What is the number and percentage of customer plans after their initial free trial?

WITH next_plan_id_cte AS
  (SELECT customer_id,
          plan_id,
          LEAD(plan_id) OVER (PARTITION BY customer_id
			      ORDER BY start_date) AS next_plan_id
   FROM foodie_fi.subscriptions)
SELECT next_plan_id AS plan_id,
	   plan_name,
	   COUNT(*) AS post_trial_selection_count,
       CAST(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id)
				FROM foodie_fi.subscriptions) AS DECIMAL(5,1)) AS post_trial_selection_pct
FROM next_plan_id_cte AS np
JOIN foodie_fi.plans AS pl ON pl.plan_id = np.next_plan_id
WHERE np.plan_id = 0
  AND next_plan_id != 4
GROUP BY 1, 2
ORDER BY 1;

-- 	7. What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020-12-31`?

WITH customer_status_cte AS
  (SELECT *,
          TIMESTAMPDIFF(DAY, start_date, '2020-12-31') AS remaining_days_til_2020_end,
          DENSE_RANK() OVER (PARTITION BY customer_id
                             ORDER BY TIMESTAMPDIFF(DAY, start_date, '2020-12-31')) AS plan_index
   FROM foodie_fi.subscriptions
   WHERE TIMESTAMPDIFF(DAY, start_date, '2020-12-31') >= 0)
SELECT cs.plan_id,
       plan_name,
       COUNT(*) AS plan_usage_count,
       CAST(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id)
				FROM foodie_fi.subscriptions) AS DECIMAL(5,1)) AS plan_usage_pct
FROM customer_status_cte AS cs
JOIN foodie_fi.plans AS pl ON pl.plan_id = cs.plan_id
WHERE plan_index = 1
GROUP BY 1, 2;

-- 	8. How many customers have upgraded to an annual plan in 2020?

SELECT COUNT(*) AS upgraded_customer_2020_count
FROM foodie_fi.subscriptions
WHERE plan_id = 3
  AND YEAR(start_date) = 2020;

-- 	9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

SELECT CEILING(AVG(TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date))) AS avg_days_to_upgrade_to_annual_plan
FROM foodie_fi.subscriptions AS s1
JOIN foodie_fi.subscriptions AS s2 ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0
  AND s2.plan_id = 3;

-- 	10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

SELECT CASE
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 0 AND 1 THEN '0-30 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 1 AND 2 THEN '31-60 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 2 AND 3 THEN '61-90 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 3 AND 4 THEN '91-120 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 4 AND 5 THEN '121-150 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 5 AND 6 THEN '151-180 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 6 AND 7 THEN '181-210 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 7 AND 8 THEN '211-240 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 8 AND 9 THEN '241-270 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 9 AND 10 THEN '271-300 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 10 AND 11 THEN '301-330 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 11 AND 12 THEN '331-360 days'
           WHEN TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date) / 30.0 BETWEEN 12 AND 13 THEN '361-390 days'
       END AS period,
       CEILING(AVG(TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date))) AS avg_days_to_upgrade_to_annual_plan
FROM foodie_fi.subscriptions AS s1
JOIN foodie_fi.subscriptions AS s2 ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0
  AND s2.plan_id = 3
GROUP BY 1
ORDER BY 2;

-- 	11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

SELECT COUNT(*) AS downgraded_customer_count_2020
FROM foodie_fi.subscriptions AS s1
JOIN foodie_fi.subscriptions AS s2 ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 3
  AND s2.plan_id = 2
  AND s1.start_date < s2.start_date
  AND YEAR(s2.start_date) = 2020;
