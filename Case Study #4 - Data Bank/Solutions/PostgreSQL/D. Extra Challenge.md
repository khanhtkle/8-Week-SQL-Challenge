# :bank: Case Study 4 - Data Bank

## D. Extra Challenge

<picture>
  <img src="https://img.shields.io/badge/postgresql-4169e1?style=for-the-badge&logo=postgresql&logoColor=white">
</picture>

### Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.
### If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?
### Special notes:
### - Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

</br>

```mysql
DROP TABLE IF EXISTS data_bank.balance_with_daily_n_c_i_reward;
CREATE TABLE data_bank.balance_with_daily_n_c_i_reward AS
  (SELECT customer_id, 
   	  date, 
   	  (balance * (1 + (0.06::DECIMAL(9, 4)) / 366))::DECIMAL(9, 4) AS balance_with_daily_n_c_i_reward
   FROM data_bank.balance_by_day
   WHERE DATE_PART('month', date) < 5
   ORDER BY 1, 2);
   
SELECT *
FROM data_bank.balance_with_daily_n_c_i_reward;
```
| customer_id | date       | balance_with_daily_n_c_i_reward |
|-------------|:-----------|---------------------------------|
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

> Note: The presented dataset comprises 10 out of 53,441 rows of the `balance_with_daily_n_c_i_reward` table.

</br>

```mysql
SELECT TO_CHAR(date, 'FMMonth, yyyy') AS month,
       SUM(balance_with_daily_n_c_i_reward)::DECIMAL(10, 0) AS data_required
FROM data_bank.balance_with_daily_n_c_i_reward
GROUP BY 1, DATE_PART('month', date)
ORDER BY DATE_PART('month', date);
```
| month          | data_required |
|:---------------|---------------|
| 2020, January  | 2911994       |
| 2020, February | 1897891       |
| 2020, March    | -2852900      |
| 2020, April    | -6896923      |

</br>

```mysql        
DROP TABLE IF EXISTS data_bank.first_and_last_balance_by_day;
CREATE TABLE data_bank.first_and_last_balance_by_day AS
  (SELECT customer_id,
          MIN(date) AS first_date,
          MAX(date) AS last_date
   FROM data_bank.balance_by_day
   WHERE DATE_PART('month', date) < 5
   GROUP BY customer_id
   ORDER BY 1);

SELECT *
FROM data_bank.first_and_last_balance_by_day;
```
| customer_id | first_date | last_date  |
|-------------|:-----------|:-----------|
| 1           | 2020-01-02 | 2020-04-30 |
| 2           | 2020-01-03 | 2020-04-30 |
| 3           | 2020-01-27 | 2020-04-30 |
| 4           | 2020-01-07 | 2020-04-30 |
| 5           | 2020-01-15 | 2020-04-30 |
| 6           | 2020-01-11 | 2020-04-30 |
| 7           | 2020-01-20 | 2020-04-30 |
| 8           | 2020-01-15 | 2020-04-30 |
| 9           | 2020-01-21 | 2020-04-30 |
| 10          | 2020-01-13 | 2020-04-30 |

> Note: The presented dataset comprises 10 out of 500 rows of the `first_and_last_balance_by_day` table.

</br>

```mysql    
DROP TABLE IF EXISTS data_bank.balance_with_daily_c_i_reward;
CREATE TABLE data_bank.balance_with_daily_c_i_reward AS
  (WITH RECURSIVE recursive_cte AS
     (SELECT fl.customer_id,
             first_date AS date,
             last_date,
             total_txn_amount_by_day,
             (balance * (1 + (0.06::DECIMAL(9, 4)) / 366))::DECIMAL(9, 4) AS balance_with_daily_c_i_reward
      FROM data_bank.first_and_last_balance_by_day AS fl
      JOIN data_bank.balance_by_day AS bd ON bd.customer_id = fl.customer_id
      				   	 AND bd.date = fl.first_date
      UNION ALL 
      SELECT re.customer_id,
	     (re.date + INTERVAL '1 day')::DATE,
             last_date,
             bd.total_txn_amount_by_day,
             CASE
                 WHEN bd.total_txn_amount_by_day IS NULL THEN balance_with_daily_c_i_reward * (1 + (0.06::DECIMAL(9, 4)) / 366)
                 ELSE (balance_with_daily_c_i_reward + bd.total_txn_amount_by_day) * (1 + (0.06::DECIMAL(9, 4)) / 366)
             END::DECIMAL(9, 4)
      FROM recursive_cte AS re
      JOIN data_bank.balance_by_day AS bd ON bd.customer_id = re.customer_id
                                         AND bd.date = re.date + INTERVAL '1 day'
      WHERE re.date + INTERVAL '1 day' <= last_date) 
   SELECT re.customer_id,
          re.date,
          re.total_txn_amount_by_day,
          balance_with_daily_c_i_reward
   FROM recursive_cte AS re
   JOIN data_bank.balance_by_day AS bd ON bd.customer_id = re.customer_id
                                      AND bd.date = re.date
   ORDER BY 1, 2);

SELECT *
FROM data_bank.balance_with_daily_c_i_reward;
```
| customer_id | date       | total_txn_amount_by_day | balance_with_daily_c_i_reward |
|-------------|:-----------|-------------------------|-------------------------------|
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

> Note: The presented dataset comprises 10 out of 53,441 rows of the `balance_with_daily_c_i_reward` table.

```mysql
SELECT TO_CHAR(date, 'FMMonth, yyyy') AS month,
       SUM(balance_with_daily_c_i_reward)::DECIMAL(10, 0) AS data_required
FROM data_bank.balance_with_daily_c_i_reward
GROUP BY 1, DATE_PART('month', date)
ORDER BY DATE_PART('month', date);
```
| month          | data_required |
|:---------------|---------------|
| 2020, January  | 2917352       |
| 2020, February | 1918000       |
| 2020, March    | -2833228      |
| 2020, April    | -6902959      |
