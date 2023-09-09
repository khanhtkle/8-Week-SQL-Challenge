# :avocado: Case Study 3 - Foodie-Fi

## B. Data Analysis Questions

<picture>
  <img src="https://img.shields.io/badge/mysql-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### 1. How many customers has Foodie-Fi ever had?
```mysql
SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM foodie_fi.subscriptions;
```
| customer_count |
|----------------|
| 1000           |

---
### 2. What is the monthly distribution of `trial` plan `start_date` values for our dataset? Use the start of the month as the group by value.
```mysql
SELECT YEAR(start_date) AS year,
       MONTHNAME(start_date) AS month,
       DATE_FORMAT(start_date, '%Y-%m-01') AS start_of_month,
       COUNT(*) AS trial_plan_count
FROM foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY 1, 2, 3, MONTH(start_date)
ORDER BY MONTH(start_date);
```
| year | month     | start_of_month | trial_plan_count |
|------|-----------|----------------|------------------|
| 2020 | January   | 2020-01-01     | 88               |
| 2020 | February  | 2020-02-01     | 68               |
| 2020 | March     | 2020-03-01     | 94               |
| 2020 | April     | 2020-04-01     | 81               |
| 2020 | May       | 2020-05-01     | 88               |
| 2020 | June      | 2020-06-01     | 79               |
| 2020 | July      | 2020-07-01     | 89               |
| 2020 | August    | 2020-08-01     | 88               |
| 2020 | September | 2020-09-01     | 87               |
| 2020 | October   | 2020-10-01     | 79               |
| 2020 | November  | 2020-11-01     | 75               |
| 2020 | December  | 2020-12-01     | 84               |

---
### 3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`.
```mysql
SELECT YEAR(start_date) AS year,
       su.plan_id,
       plan_name,
       COUNT(*) AS event_count
FROM foodie_fi.subscriptions AS su
JOIN foodie_fi.plans AS pl ON pl.plan_id = su.plan_id
WHERE YEAR(start_date) > 2020
GROUP BY 1, 2, 3
ORDER BY 2;
```
| year | plan_id | plan_name     | event_count |
|------|---------|---------------|-------------|
| 2021 | 1       | basic monthly | 8           |
| 2021 | 2       | pro monthly   | 60          |
| 2021 | 3       | pro annual    | 63          |
| 2021 | 4       | churn         | 71          |

---
### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```mysql
SELECT SUM(CASE
               WHEN plan_id = 4 THEN 1
           END) AS total_churned_customer_count,
       CAST(100.0 * SUM(CASE
                            WHEN plan_id = 4 THEN 1
                        END) / COUNT(DISTINCT customer_id) AS DECIMAL(5,1)) AS total_churn_pct
FROM foodie_fi.subscriptions;
```
| total_churned_customer_count | total_churn_pct |
|------------------------------|-----------------|
| 307                          | 30.7            |

---
### 5. How many customers have churned straight after their initial free trial? What percentage is this rounded to the nearest whole number?
```mysql
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
```
| post_trial_churned_customer_count | post_trial_churned_customer_pct |
|-----------------------------------|---------------------------------|
| 92                                | 9.2                             |

---
### 6. What is the number and percentage of customer plans after their initial free trial?
```mysql
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
GROUP BY 1, 2
ORDER BY 1;
```
| plan_id | plan_name     | post_trial_selection_count | post_trial_selection_pct |
|---------|---------------|----------------------------|--------------------------|
| 1       | basic monthly | 546                        | 54.6                     |
| 2       | pro monthly   | 325                        | 32.5                     |
| 3       | pro annual    | 37                         | 3.7                      |
| 4       | churn         | 92                         | 9.2                      |

---
### 7. What is the customer count and percentage breakdown of all 5 `plan_name` values at 2020-12-31?
```mysql
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
```
| plan_id | plan_name     | plan_usage_count | plan_usage_pct |
|---------|---------------|------------------|----------------|
| 0       | trial         | 19               | 1.9            |
| 1       | basic monthly | 224              | 22.4           |
| 2       | pro monthly   | 326              | 32.6           |
| 3       | pro annual    | 195              | 19.5           |
| 4       | churn         | 236              | 23.6           |

---
### 8. How many customers have upgraded to an `annual` plan in 2020?
```mysql
SELECT COUNT(*) AS upgraded_customer_2020_count
FROM foodie_fi.subscriptions
WHERE plan_id = 3
  AND YEAR(start_date) = 2020;
```
| upgraded_customer_2020_count |
|------------------------------|
| 195                          |

---
### 9. How many days on average does it take for a customer to an `annual` plan from the day they join Foodie-Fi?
```mysql
SELECT CEILING(AVG(TIMESTAMPDIFF(DAY, s1.start_date, s2.start_date))) AS avg_days_to_upgrade_to_annual_plan
FROM foodie_fi.subscriptions AS s1
JOIN foodie_fi.subscriptions AS s2 ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0
  AND s2.plan_id = 3;
```
| avg_days_to_upgrade_to_annual_plan |
|------------------------------------|
| 105                                |

---
### 10. Can you further breakdown this average value into 30 day periods? (i.e. 0-30 days, 31-60 days etc)
```mysql
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
```
| period       | avg_days_to_upgrade_to_annual_plan |
|--------------|------------------------------------|
| 0-30 days    | 10                                 |
| 31-60 days   | 43                                 |
| 61-90 days   | 72                                 |
| 91-120 days  | 101                                |
| 121-150 days | 134                                |
| 151-180 days | 163                                |
| 181-210 days | 191                                |
| 211-240 days | 225                                |
| 241-270 days | 258                                |
| 271-300 days | 285                                |
| 301-330 days | 327                                |
| 331-360 days | 346                                |

---
### 11. How many customers downgraded from a `pro monthly` to a `basic monthly` plan in 2020?
```mysql
SELECT COUNT(*) AS downgraded_customer_count_2020
FROM foodie_fi.subscriptions AS s1
JOIN foodie_fi.subscriptions AS s2 ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 3
  AND s2.plan_id = 2
  AND s1.start_date < s2.start_date
  AND YEAR(s2.start_date) = 2020;
```
| downgraded_customer_count_2020 |
|--------------------------------|
| 0                              |

---
My solution for **[C. Challenge Payment Question](C.%20Challenge%20Payment%20Question.md)**.
