# :bank: Case Study 4 - Data Bank

## C. Data Allocation Challenge

<picture>
  <img src="https://img.shields.io/badge/mysql-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
### - Option 1: data is allocated based off the amount of money at the end of the previous month
### - Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
### - Option 3: data is updated real-time
### For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
### - running customer balance column that includes the impact each transaction
### - customer balance at the end of each month
### - minimum, average and maximum values of the running balance for each customer
### Using all of the data available - how much data would have been required for each option on a monthly basis?

</br>

```mysql
DROP TABLE IF EXISTS data_bank.balance_by_txn;
CREATE TABLE data_bank.balance_by_txn AS
  (SELECT customer_id, 
	  date, 
	  txn_type,
	  txn_amount,
	  balance,
	  record_id
   FROM data_bank.customer_transactions_extended
   WHERE txn_type IS NOT NULL
   ORDER BY 1, 2, 6);

SELECT *
FROM data_bank.balance_by_txn;
```
| customer_id | date&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | txn_type   | txn_amount | balance | record_id |
|-------------|------------|:-----------|------------|---------|-----------|
| 1           | 2020-01-02 | deposit    | 312        | 312     | 62        |
| 1           | 2020-03-05 | purchase   | 612        | -300    | 1174      |
| 1           | 2020-03-17 | deposit    | 324        | 24      | 1175      |
| 1           | 2020-03-19 | purchase   | 664        | -640    | 1176      |
| 2           | 2020-01-03 | deposit    | 549        | 549     | 287       |
| 2           | 2020-03-24 | deposit    | 61         | 610     | 3600      |
| 3           | 2020-01-27 | deposit    | 144        | 144     | 234       |
| 3           | 2020-02-22 | purchase   | 965        | -821    | 3053      |
| 3           | 2020-03-05 | withdrawal | 213        | -1034   | 3055      |
| 3           | 2020-03-19 | withdrawal | 188        | -1222   | 3056      |

> Note: The presented dataset comprises 10 out of 5,868 rows of the `balance_by_txn` table.

</br>

```mysql
SELECT DATE_FORMAT(date, '%M, %Y') AS month,
       SUM(balance) AS data_required
FROM data_bank.balance_by_txn
GROUP BY 1, MONTH(date)
ORDER BY MONTH(date);
```
| month          | data_required |
|:---------------|---------------|
| January, 2020  | 413460        |
| February, 2020 | 36267         |
| March, 2020    | -880321       |
| April, 2020    | -486481       |

</br>

```mysql
DROP TABLE IF EXISTS data_bank.balance_by_end_of_previous_month;
CREATE TABLE data_bank.balance_by_end_of_previous_month AS
  (WITH balance_by_previous_month_cte AS
     (SELECT DISTINCT customer_id,
             CAST(DATE_FORMAT(MIN(date) OVER (PARTITION BY customer_id
                                              ORDER BY date), '%Y-%m-01') AS DATE) AS date,
             0 AS balance
      FROM data_bank.balance_by_day
      UNION 
      SELECT customer_id,
             DATE_ADD(date, INTERVAL 1 DAY),
             balance
      FROM data_bank.balance_by_day
      WHERE date = LAST_DAY(date)) 
   SELECT customer_id,
          DATE_FORMAT(date, '%M, %Y') AS month,
	  MONTH(date) AS month_index,
	  balance AS balance_by_end_of_previous_month
   FROM balance_by_previous_month_cte
   ORDER BY 1, 3);

SELECT *
FROM data_bank.balance_by_end_of_previous_month;
```
| customer_id | month          | month_index | balance_by_end_of_previous_month |
|-------------|:---------------|-------------|----------------------------------|
| 1           | 2020, January  | 1           | 0                                |
| 1           | 2020, February | 2           | 312                              |
| 1           | 2020, March    | 3           | 312                              |
| 1           | 2020, April    | 4           | -640                             |
| 1           | 2020, May      | 5           | -640                             |
| 2           | 2020, January  | 1           | 0                                |
| 2           | 2020, February | 2           | 549                              |
| 2           | 2020, March    | 3           | 549                              |
| 2           | 2020, April    | 4           | 610                              |
| 2           | 2020, May      | 5           | 610                              |

> Note: The presented dataset comprises 14 out of 2,500 rows of the `balance_by_end_of_previous_month` table.

</br>

```mysql
SELECT month, 
       SUM(balance_by_end_of_previous_month) AS data_required
FROM data_bank.balance_by_end_of_previous_month
GROUP BY 1, month_index
ORDER BY month_index;
```
| month          | data_required |
|:---------------|---------------|
| 2020, January  | 0             |
| 2020, February | 126091        |
| 2020, March    | -13708        |
| 2020, April    | -184592       |
| 2020, May      | -240372       |

</br>

```mysql
DROP TABLE IF EXISTS data_bank.monthly_avg_balance;
CREATE TABLE data_bank.monthly_avg_balance AS (
SELECT customer_id,
       DATE_FORMAT(date, '%M, %Y') AS month,
       MONTH(date) AS month_index,
       MIN(balance) AS min_balance,
       CAST(ROUND(AVG(balance), 1) AS REAL) AS avg_balance,
       MAX(balance) AS max_balance
FROM data_bank.balance_by_day
WHERE MONTH(date) < 5
GROUP BY 1, 2, 3
ORDER BY 1, 3);

SELECT * 
FROM data_bank.monthly_avg_balance;
```
| customer_id | month&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | month_index | min_balance | avg_balance | max_balance |
|-------------|----------------|-------------|-------------|-------------|-------------|
| 1           | 2020, January  | 1           | 312         | 312         | 312         |
| 1           | 2020, February | 2           | 312         | 312         | 312         |
| 1           | 2020, March    | 3           | -640        | -342.7      | 312         |
| 1           | 2020, April    | 4           | -640        | -640        | -640        |
| 2           | 2020, January  | 1           | 549         | 549         | 549         |
| 2           | 2020, February | 2           | 549         | 549         | 549         |
| 2           | 2020, March    | 3           | 549         | 564.7       | 610         |
| 2           | 2020, April    | 4           | 610         | 610         | 610         |
| 3           | 2020, January  | 1           | 144         | 144         | 144         |
| 3           | 2020, February | 2           | -821        | -122.2      | 144         |

> Note: The presented dataset comprises 10 out of 2,000 rows of the `monthly_avg_balance` table.

</br>

```mysql
DROP TABLE IF EXISTS data_bank.p_monthly_avg_balance;
CREATE TABLE data_bank.p_monthly_avg_balance AS (
SELECT customer_id,
       DATE_FORMAT(p_start, '%M, %Y') AS p_month,
       MONTH(p_start) AS p_month_index,
       MIN(balance) AS p_min_balance,
       CAST(ROUND(AVG(balance), 1) AS REAL) AS p_avg_balance,
       MAX(balance) AS p_max_balance
FROM data_bank.balance_by_day
GROUP BY 1, p_start
ORDER BY 1, p_start);

SELECT * 
FROM data_bank.p_monthly_avg_balance;
```
| customer_id | p_month&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | p_month_index | p_min_balance | p_avg_balance | p_max_balance |
|-------------|----------------|---------------|---------------|---------------|---------------|
| 1           | 2020, January  | 1             | 312           | 312           | 312           |
| 1           | 2020, February | 2             | 312           | 312           | 312           |
| 1           | 2020, March    | 3             | -640          | -373.4        | 312           |
| 1           | 2020, April    | 4             | -640          | -640          | -640          |
| 2           | 2020, January  | 1             | 549           | 549           | 549           |
| 2           | 2020, February | 2             | 549           | 549           | 549           |
| 2           | 2020, March    | 3             | 549           | 568.7         | 610           |
| 2           | 2020, April    | 4             | 610           | 610           | 610           |
| 3           | 2020, January  | 1             | -821          | -11.6         | 144           |
| 3           | 2020, February | 2             | -1222         | -1034.4       | -821          |

> Note: The presented dataset comprises 10 out of 2,000 rows of the `p_monthly_avg_balance` table.

</br>

```mysql
SELECT month,
       CEILING(SUM(avg_balance)) AS data_required
FROM data_bank.monthly_avg_balance
GROUP BY 1;
```
| month          | data_required |
|:---------------|---------------|
| 2020, January  | 188651        |
| 2020, February | 65434         |
| 2020, March    | -92013        |
| 2020, April    | -229858       |

</br>

```mysql
SELECT p_month, 
       CEILING(SUM(p_avg_balance)) AS data_required
FROM data_bank.p_monthly_avg_balance
GROUP BY 1;
```
| p_month        | data_required |
|:---------------|---------------|
| 2020, January  | 150641        |
| 2020, February | -5533         |
| 2020, March    | -165013       |
| 2020, April    | -240372       |

---
My solution for **[D. Extra Challenge](D.%20Extra%20Challenge.md)**.
