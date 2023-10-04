# :bank: Case Study 4 - Data Bank

## D. Extra Challenge

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.
### If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?
### Special notes:
### - Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

```tsql
DROP TABLE IF EXISTS data_bank.dbo.balance_with_daily_n_c_i_reward;
SELECT customer_id,
       date, 
       CAST(balance * (1 + CAST(0.06 AS DECIMAL(9,4)) / 366) AS DECIMAL(9,4)) AS balance_with_daily_n_c_i_reward
INTO data_bank.dbo.balance_with_daily_n_c_i_reward
FROM data_bank.dbo.balance_by_day
WHERE MONTH(date) < 5;

SELECT *
FROM data_bank.dbo.balance_with_daily_n_c_i_reward
ORDER BY customer_id, 
	 date;
```
| customer_id | date       | balance_with_daily_n_c_i_reward |
|-------------|------------|---------------------------------|
| 1           | 2020-01-02 | 312.0511                        |
| 1           | 2020-01-03 | 312.0511                        |
| 1           | 2020-01-04 | 312.0511                        |
| 1           | 2020-01-05 | 312.0511                        |
| 1           | 2020-01-06 | 312.0511                        |
| 1           | 2020-01-07 | 312.0511                        |
| 1           | 2020-01-08 | 312.0511                        |
| 1           | 2020-01-09 | 312.0511                        |
| 1           | 2020-01-10 | 312.0511                        |
| 1           | 2020-01-11 | 312.0511                        |
| 1           | 2020-01-12 | 312.0511                        |
| 1           | 2020-01-13 | 312.0511                        |
| 1           | 2020-01-14 | 312.0511                        |
| 1           | 2020-01-15 | 312.0511                        |

> Note: The presented dataset comprises 14 out of 53,441 rows of the `balance_with_daily_n_c_i_reward` table.

</br>

```tsql
SELECT FORMAT(date, 'yyyy, MMMM') AS month,
       MONTH(date) AS month_index,
       CAST(SUM(balance_with_daily_n_c_i_reward) AS DECIMAL(10,0)) AS data_required
FROM data_bank.dbo.balance_with_daily_n_c_i_reward
GROUP BY FORMAT(date, 'yyyy, MMMM'),
         MONTH(date)
ORDER BY MONTH(date);
```
| month          | month_index | data_required |
|----------------|-------------|---------------|
| 2020, January  | 1           | 2911994       |
| 2020, February | 2           | 1897891       |
| 2020, March    | 3           | -2852900      |
| 2020, April    | 4           | -6896923      |

</br>

```tsql        
DROP TABLE IF EXISTS data_bank.dbo.balance_with_daily_c_i_reward;
WITH first_and_last_balance_by_day_cte AS
  (SELECT customer_id,
          MIN(date) AS first_date,
          MAX(date) AS last_date
   FROM data_bank.dbo.balance_by_day
   WHERE MONTH(date) < 5
   GROUP BY customer_id),
     recursive_cte AS
  (SELECT fl.customer_id,
          first_date AS date,
          last_date,
          total_txn_amount_by_day,
          CAST(balance * (1 + CAST(0.06 AS DECIMAL(9,4)) / 366) AS DECIMAL(9,4)) AS balance_with_daily_c_i_reward
   FROM first_and_last_balance_by_day_cte AS fl
   JOIN data_bank.dbo.balance_by_day AS bd ON bd.customer_id = fl.customer_id
    AND bd.date = fl.first_date
   UNION ALL 
   SELECT re.customer_id,
          DATEADD(dd, 1, re.date),
          last_date,
          bd.total_txn_amount_by_day,
          CASE
	      WHEN bd.total_txn_amount_by_day IS NULL THEN CAST(balance_with_daily_c_i_reward * (1 + CAST(0.06 AS DECIMAL(9,4)) / 366) AS DECIMAL(9,4))
	      ELSE CAST((balance_with_daily_c_i_reward + bd.total_txn_amount_by_day) * (1 + CAST(0.06 AS DECIMAL(9,4)) / 366) AS DECIMAL(9,4))
          END
   FROM recursive_cte AS re
   JOIN data_bank.dbo.balance_by_day AS bd ON bd.customer_id = re.customer_id
    AND bd.date = DATEADD(dd, 1, re.date)
   WHERE DATEADD(dd, 1, re.date) <= last_date)
SELECT re.customer_id,
       re.date,
       re.total_txn_amount_by_day,
       balance_with_daily_c_i_reward 
INTO data_bank.dbo.balance_with_daily_c_i_reward
FROM recursive_cte AS re
JOIN data_bank.dbo.balance_by_day AS bd ON bd.customer_id = re.customer_id
 AND bd.date = re.date 
OPTION (MAXRECURSION 1000);

SELECT *
FROM data_bank.dbo.balance_with_daily_c_i_reward
ORDER BY customer_id, 
         date;
```
| customer_id | date       | total_txn_amount_by_day | balance_with_daily_c_i_reward |
|-------------|------------|-------------------------|-------------------------------|
| 1           | 2020-01-02 | 312                     | 312.0511                      |
| 1           | 2020-01-03 | NULL                    | 312.1023                      |
| 1           | 2020-01-04 | NULL                    | 312.1535                      |
| 1           | 2020-01-05 | NULL                    | 312.2047                      |
| 1           | 2020-01-06 | NULL                    | 312.2559                      |
| 1           | 2020-01-07 | NULL                    | 312.3071                      |
| 1           | 2020-01-08 | NULL                    | 312.3583                      |
| 1           | 2020-01-09 | NULL                    | 312.4095                      |
| 1           | 2020-01-10 | NULL                    | 312.4607                      |
| 1           | 2020-01-11 | NULL                    | 312.5119                      |
| 1           | 2020-01-12 | NULL                    | 312.5631                      |
| 1           | 2020-01-13 | NULL                    | 312.6143                      |
| 1           | 2020-01-14 | NULL                    | 312.6655                      |
| 1           | 2020-01-15 | NULL                    | 312.7168                      |

> Note: The presented dataset comprises 14 out of 53,441 rows of the `balance_with_daily_c_i_reward` table.

```tsql
SELECT FORMAT(date, 'yyyy, MMMM') AS month,
       MONTH(date) AS month_index,
       CAST(SUM(balance_with_daily_c_i_reward) AS DECIMAL(10,0)) AS data_required
FROM data_bank.dbo.balance_with_daily_c_i_reward
GROUP BY FORMAT(date, 'yyyy, MMMM'),
         MONTH(date)
ORDER BY MONTH(date);
```
| month          | month_index | data_required |
|----------------|-------------|---------------|
| 2020, January  | 1           | 2917352       |
| 2020, February | 2           | 1918000       |
| 2020, March    | 3           | -2833228      |
| 2020, April    | 4           | -6902959      |
