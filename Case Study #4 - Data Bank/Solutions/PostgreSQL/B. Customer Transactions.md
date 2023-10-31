# :bank: Case Study 4 - Data Bank

## B. Customer Transactions

<picture>
  <img src="https://img.shields.io/badge/postgresql-4169e1?style=for-the-badge&logo=postgresql&logoColor=white">
</picture>

### Data Cleaning
```pgsql
DROP TABLE IF EXISTS data_bank.opening_account_date;
CREATE TABLE data_bank.opening_account_date AS
  (SELECT DISTINCT customer_id,
          MIN(txn_date) OVER (PARTITION BY customer_id
                              ORDER BY txn_date) AS opening_account_date
   FROM data_bank.customer_transactions
   ORDER BY 1);

SELECT *
FROM data_bank.opening_account_date;
```
| customer_id | opening_account_date |
|-------------|----------------------|
| 1           | 2020-01-02           |
| 2           | 2020-01-03           |
| 3           | 2020-01-27           |
| 4           | 2020-01-07           |
| 5           | 2020-01-15           |
| 6           | 2020-01-11           |
| 7           | 2020-01-20           |
| 8           | 2020-01-15           |
| 9           | 2020-01-21           |
| 10          | 2020-01-13           |

> Note: The presented dataset comprises 10 out of 500 rows of the `opening_account_date` table.

</br>

```pgsql
DROP TABLE IF EXISTS data_bank.recursive_p_start;
CREATE TABLE data_bank.recursive_p_start AS
  (WITH RECURSIVE recursive_p_start_cte AS
     (SELECT customer_id,
             opening_account_date,
             opening_account_date AS p_start
      FROM data_bank.opening_account_date
      UNION ALL 
      SELECT customer_id,
             opening_account_date,
             (p_start + INTERVAL '1 month')::DATE
      FROM recursive_p_start_cte
      WHERE DATE_PART('month', p_start + INTERVAL '1 month') < 5) 
   SELECT *
   FROM recursive_p_start_cte
   ORDER BY 1, 3);

SELECT *
FROM data_bank.recursive_p_start;
```
| customer_id | opening_account_date | p_start    |
|-------------|----------------------|:-----------|
| 1           | 2020-01-02           | 2020-01-02 |
| 1           | 2020-01-02           | 2020-02-02 |
| 1           | 2020-01-02           | 2020-03-02 |
| 1           | 2020-01-02           | 2020-04-02 |
| 2           | 2020-01-03           | 2020-01-03 |
| 2           | 2020-01-03           | 2020-02-03 |
| 2           | 2020-01-03           | 2020-03-03 |
| 2           | 2020-01-03           | 2020-04-03 |
| 3           | 2020-01-27           | 2020-01-27 |
| 3           | 2020-01-27           | 2020-02-27 |

> Note: The presented dataset comprises 10 out of 2,000 rows of the `recursive_p_start` table.

</br>

```pgsql
DROP TABLE IF EXISTS data_bank.recursive_date;
CREATE TABLE data_bank.recursive_date AS
  (WITH RECURSIVE recursive_date_cte AS
     (SELECT customer_id,
             p_start,
             p_start AS date,
             (p_start + INTERVAL '1 month - 1 day')::DATE AS p_end
      FROM data_bank.recursive_p_start
      UNION ALL 
      SELECT customer_id,
             p_start,
             (date + INTERVAL '1 day')::DATE,
             p_end
      FROM recursive_date_cte
      WHERE date + INTERVAL '1 day' <= p_end) 
   SELECT *
   FROM recursive_date_cte
   ORDER BY 1, 3);

SELECT *
FROM data_bank.recursive_date;
```
| customer_id | p_start    | date       | p_end      |
|-------------|:-----------|:-----------|:-----------|
| 1           | 2020-01-02 | 2020-01-02 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-03 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-04 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-05 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-06 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-07 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-08 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-09 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-10 | 2020-02-01 |
| 1           | 2020-01-02 | 2020-01-11 | 2020-02-01 |

> Note: The presented dataset comprises 10 out of 60,490 rows of the `recursive_date` table.

</br>

```pgsql
ALTER TABLE data_bank.customer_transactions
DROP COLUMN IF EXISTS record_id;

ALTER TABLE data_bank.customer_transactions
ADD record_id SERIAL PRIMARY KEY;

SELECT *
FROM data_bank.customer_transactions;
```
| customer_id | txn_date   | txn_type | txn_amount | record_id |
|-------------|:-----------|----------|------------|-----------|
| 429         | 2020-01-21 | deposit  | 82         | 1         |
| 155         | 2020-01-10 | deposit  | 712        | 2         |
| 398         | 2020-01-01 | deposit  | 196        | 3         |
| 255         | 2020-01-14 | deposit  | 563        | 4         |
| 185         | 2020-01-29 | deposit  | 626        | 5         |
| 309         | 2020-01-13 | deposit  | 995        | 6         |
| 312         | 2020-01-20 | deposit  | 485        | 7         |
| 376         | 2020-01-03 | deposit  | 706        | 8         |
| 188         | 2020-01-13 | deposit  | 601        | 9         |
| 138         | 2020-01-11 | deposit  | 520        | 10        |
| 373         | 2020-01-18 | deposit  | 596        | 11        |
| 361         | 2020-01-12 | deposit  | 797        | 12        |
| 169         | 2020-01-10 | deposit  | 628        | 13        |
| 402         | 2020-01-05 | deposit  | 435        | 14        |

> Note: The presented dataset comprises 10 out of 5,868 rows of the `customer_transactions` table.

```pgsql
DROP TABLE IF EXISTS data_bank.customer_transactions_extended;
CREATE TABLE data_bank.customer_transactions_extended AS
  (WITH balance_calculating_cte AS
     (SELECT rd.customer_id,
             p_start, 
             date, 
             p_end,
             txn_type,
             txn_amount,
             SUM(CASE
		     WHEN txn_type = 'deposit' THEN txn_amount
                     ELSE -txn_amount
		 END) OVER (PARTITION BY rd.customer_id, p_start, date
			    ORDER BY date, record_id) AS d_txn_amount,
	     SUM(CASE
		     WHEN txn_type = 'deposit' THEN txn_amount
                     ELSE -txn_amount
		 END) OVER (PARTITION BY rd.customer_id
			    ORDER BY date, record_id 
             		    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance, 
	     customer_transactions_row_number
      FROM data_bank.recursive_date AS rd
      LEFT JOIN data_bank.customer_transactions AS ct ON ct.customer_id = rd.customer_id
						     AND ct.txn_date = rd.date) 
   SELECT *,
	  LEAD(date) OVER (PARTITION BY customer_id
			   ORDER BY date, record_id) AS next_date,
	  ROW_NUMBER() OVER (PARTITION BY customer_id, p_start, p_end, balance
			     ORDER BY date) AS balance_unchanged_p_day_count,
	  p_end - p_start + 1 AS p_month_day_count,
	  ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_PART('month', date), balance
			     ORDER BY date) AS balance_unchanged_day_count,
	  (DATE_TRUNC('month', date) + INTERVAL '1 month - 1 day')::DATE - DATE_TRUNC('month', date)::DATE + 1 AS month_day_count
   FROM balance_calculating_cte
   ORDER BY 1, 3, 9);

SELECT *
FROM data_bank.customer_transactions_extended;
```
| customer_id | p_start&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | date&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | p_end&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | txn_type | txn_amount | d_txn_amount | balance | record_id | next_date&nbsp;&nbsp;&nbsp; | balance_unchanged_p_day_count | p_month_day_count | balance_unchanged_day_count | month_day_count |
|-------------|------------|------------|------------|----------|------------|--------------|---------|-----------|------------|-------------------------------|-------------------|-----------------------------|-----------------|
| 1           | 2020-01-02 | 2020-01-02 | 2020-02-01 | deposit  | 312        | 312          | 312     | 62        | 2020-01-03 | 1                             | 31                | 1                           | 31              |
| 1           | 2020-01-02 | 2020-01-03 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-04 | 2                             | 31                | 2                           | 31              |
| 1           | 2020-01-02 | 2020-01-04 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-05 | 3                             | 31                | 3                           | 31              |
| 1           | 2020-01-02 | 2020-01-05 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-06 | 4                             | 31                | 4                           | 31              |
| 1           | 2020-01-02 | 2020-01-06 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-07 | 5                             | 31                | 5                           | 31              |
| 1           | 2020-01-02 | 2020-01-07 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-08 | 6                             | 31                | 6                           | 31              |
| 1           | 2020-01-02 | 2020-01-08 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-09 | 7                             | 31                | 7                           | 31              |
| 1           | 2020-01-02 | 2020-01-09 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-10 | 8                             | 31                | 8                           | 31              |
| 1           | 2020-01-02 | 2020-01-10 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-11 | 9                             | 31                | 9                           | 31              |
| 1           | 2020-01-02 | 2020-01-11 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL      | 2020-01-12 | 10                            | 31                | 10                          | 31              |

> Note: The presented dataset comprises 10 out of 60,901 rows of the `customer_transactions_extended` table.

</br>

```pgsql
DROP TABLE IF EXISTS data_bank.balance_by_day;
CREATE TABLE data_bank.balance_by_day AS
  (SELECT customer_id,
          p_start, 
          date, 
          p_end,
	  d_txn_amount AS total_txn_amount_by_day,
	  balance
   FROM data_bank.customer_transactions_extended
   WHERE next_date IS NULL
	 OR date != next_date
   ORDER BY 1, 3);

SELECT *
FROM data_bank.balance_by_day;
```
| customer_id | p_start    | date       | p_end      | total_txn_amount_by_day | balance |
|-------------|:-----------|:-----------|:-----------|-------------------------|---------|
| 1           | 2020-01-02 | 2020-01-02 | 2020-02-01 | 312                     | 312     |
| 1           | 2020-01-02 | 2020-01-03 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-04 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-05 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-06 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-07 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-08 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-09 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-10 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-11 | 2020-02-01 | NULL                    | 312     |

> Note: The presented dataset comprises 10 out of 60,490 rows of the `balance_by_day` table.

--- 
### Q1. What is the unique count and total amount for each transaction type?
```pgsql
SELECT txn_type,
       COUNT(*) AS unique_txn_count,
       SUM(txn_amount) AS total_txn_amount
FROM data_bank.customer_transactions
GROUP BY 1
ORDER BY 1;
```
| txn_type   | unique_txn_count | total_txn_amount |
|:-----------|------------------|------------------|
| deposit    | 2671             | 1359168          |
| purchase   | 1617             | 806537           |
| withdrawal | 1580             | 793003           |

---
### Q2. What is the average total historical deposit counts and amounts for all customers?
```pgsql
SELECT SUM(1) AS deposit_txn_count,
       (SELECT COUNT(DISTINCT customer_id) 
	FROM data_bank.customer_transactions) AS total_customer_count,
       SUM(txn_amount) AS total_deposit_txn_amount,
       FLOOR(SUM(1.0) / (SELECT COUNT(DISTINCT customer_id) 
			 FROM data_bank.customer_transactions)) AS avg_deposit_txn_per_customer,
       CAST(ROUND(SUM(1.0 * txn_amount) / (SELECT COUNT(DISTINCT customer_id) 
					   FROM data_bank.customer_transactions), 1) AS REAL) AS avg_deposit_txn_per_customer,
       CAST(ROUND(AVG(1.0 * txn_amount), 1) AS REAL) AS avg_txn_amount_per_deposit_txn
FROM data_bank.customer_transactions
WHERE txn_type = 'deposit';
```
| deposit_txn_count | total_customer_count | total_deposit_txn_amount | avg_deposit_txn_per_customer | avg_deposit_txn_per_customer | avg_txn_amount_per_deposit_txn |
|-------------------|----------------------|--------------------------|------------------------------|------------------------------|--------------------------------|
| 2671              | 500                  | 1359168                  | 5                            | 2718.3                       | 508.9                          |

---
### Q3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```pgsql
WITH txn_count_cte AS
  (SELECT TO_CHAR(txn_date, 'FMMonth, yyyy') AS month,
          DATE_PART('month', txn_date) AS month_index,
          customer_id,
          SUM(CASE
                  WHEN txn_type = 'deposit' THEN 1
              END) AS deposit_txn_count,
          SUM(CASE
                  WHEN txn_type = 'purchase' THEN 1
              END) AS purchase_txn_count,
          SUM(CASE
                  WHEN txn_type = 'withdrawal' THEN 1
              END) AS withdrawal_txn_count
   FROM data_bank.customer_transactions
   GROUP BY 1, 2, 3)
SELECT month,
       COUNT(customer_id) AS high_volume_customer_count
FROM txn_count_cte
WHERE deposit_txn_count > 1
  AND (purchase_txn_count >= 1
       OR withdrawal_txn_count >= 1)
GROUP BY 1, month_index
ORDER BY month_index;
```
| month          | high_volume_customer_count |
|:---------------|----------------------------|
| January, 2020  | 168                        |
| February, 2020 | 181                        |
| March, 2020    | 192                        |
| April, 2020    | 70                         |

---
### Q4. What is the closing balance for each customer at the end of the month?
```pgsql
SELECT customer_id,
       TO_CHAR(date, 'FMMonth, yyyy') AS month,
       balance
FROM data_bank.balance_by_day
WHERE date = DATE_TRUNC('month', date) + INTERVAL '1 month - 1 day'
GROUP BY 1, 2, DATE_PART('month', date), 3
ORDER BY 1, DATE_PART('month', date);
```
| customer_id | month          | balance |
|-------------|:---------------|---------|
| 1           | January, 2020  | 312     |
| 1           | February, 2020 | 312     |
| 1           | March, 2020    | -640    |
| 1           | April, 2020    | -640    |
| 2           | January, 2020  | 549     |
| 2           | February, 2020 | 549     |
| 2           | March, 2020    | 610     |
| 2           | April, 2020    | 610     |
| 3           | January, 2020  | 144     |
| 3           | February, 2020 | -821    |

> Note: The presented dataset comprises 10 out of 2,000 rows of of the resulting table.

---
### Q5. What is the percentage of customers who increase their closing balance by more than 5%?
```pgsql
WITH first_and_last_txn_date_cte AS
  (SELECT customer_id,
          MIN(date) AS first_txn_date,
          MAX(date) AS last_txn_date
   FROM data_bank.balance_by_day
   WHERE total_txn_amount_by_day IS NOT NULL
   GROUP BY 1)
SELECT fl.customer_id,
       first_txn_date,
       bd1.balance AS balance_by_first_txn_date,
       last_txn_date,
       bd2.balance AS last_balance_by_last_txn_date
FROM first_and_last_txn_date_cte AS fl
JOIN data_bank.balance_by_day AS bd1 ON bd1.customer_id = fl.customer_id
				    AND bd1.date = fl.first_txn_date
JOIN data_bank.balance_by_day AS bd2 ON bd2.customer_id = fl.customer_id
				    AND bd2.date = fl.last_txn_date
WHERE bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5
ORDER BY 1;
```
| customer_id | first_txn_date | balance_by_first_txn_date | last_txn_date | last_balance_by_last_txn_date |
|-------------|----------------|---------------------------|---------------|-------------------------------|
| 2           | 2020-01-03     | 549                       | 2020-03-24    | 610                           |
| 4           | 2020-01-07     | 458                       | 2020-03-25    | 655                           |
| 7           | 2020-01-20     | 964                       | 2020-04-17    | 2623                          |
| 9           | 2020-01-21     | 669                       | 2020-04-16    | 862                           |
| 12          | 2020-01-13     | 202                       | 2020-03-23    | 295                           |
| 13          | 2020-01-02     | 566                       | 2020-03-16    | 1405                          |
| 14          | 2020-01-25     | 205                       | 2020-04-05    | 989                           |
| 15          | 2020-01-25     | 379                       | 2020-04-02    | 1102                          |
| 30          | 2020-01-26     | 33                        | 2020-04-24    | 508                           |
| 33          | 2020-01-24     | 473                       | 2020-04-22    | 989                           |

> Note: The presented dataset comprises 10 out of 161 rows of of the resulting table.

</br>

```pgsql
WITH first_and_last_txn_date_cte AS
  (SELECT customer_id,
          MIN(date) AS first_txn_date,
          MAX(date) AS last_txn_date
   FROM data_bank.balance_by_day
   WHERE total_txn_amount_by_day IS NOT NULL
   GROUP BY 1)
SELECT COUNT(fl.customer_id) AS increasing_balance_customer_count,
       (SELECT COUNT(DISTINCT customer_id) 
	FROM data_bank.balance_by_day) AS total_customer_count,
       (100.0 * COUNT(fl.customer_id) / (SELECT COUNT(DISTINCT customer_id) 
					 FROM data_bank.balance_by_day))::DECIMAL(5,1) AS increasing_balance_customer_pct
FROM first_and_last_txn_date_cte AS fl
JOIN data_bank.balance_by_day AS bd1 ON bd1.customer_id = fl.customer_id
				    AND bd1.date = fl.first_txn_date
JOIN data_bank.balance_by_day AS bd2 ON bd2.customer_id = fl.customer_id
				    AND bd2.date = fl.last_txn_date
WHERE bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5;
```
| increasing_balance_customer_count | total_customer_count | increasing_balance_customer_pct |
|-----------------------------------|----------------------|---------------------------------|
| 161                               | 500                  | 32.2                            |

</br>

```pgsql
SELECT customer_id,
       date AS end_of_month_date,
       balance
FROM data_bank.balance_by_day
WHERE date = DATE_TRUNC('month', date) + INTERVAL '1 month - 1 day'
  AND balance = 0;
```
| customer_id | end_of_month_date | balance |
|-------------|-------------------|---------|
| 250         | 2020-02-29        | 0       |
| 306         | 2020-03-31        | 0       |

</br>

```pgsql
SELECT bd1.customer_id,
       bd1.date AS start_of_month_date,
       bd1.balance,
       bd2.date end_of_month_date,
       bd2.balance
FROM data_bank.balance_by_day AS bd1 
JOIN data_bank.balance_by_day AS bd2 ON bd1.customer_id = bd2.customer_id
WHERE bd1.date = DATE_TRUNC('month', bd1.date) + INTERVAL '1 month - 1 day'
  AND bd2.date = DATE_TRUNC('month', bd2.date) + INTERVAL '1 month - 1 day'
  AND DATE_PART('month', bd1.date) = 1
  AND DATE_PART('month', bd2.date) = 4
  AND bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5
ORDER BY 1, 2;
```
| customer_id | start_of_month_date | balance | end_of_month_date | balance |
|-------------|---------------------|---------|-------------------|---------|
| 2           | 2020-01-31          | 549     | 2020-04-30        | 610     |
| 7           | 2020-01-31          | 964     | 2020-04-30        | 2623    |
| 12          | 2020-01-31          | 92      | 2020-04-30        | 295     |
| 13          | 2020-01-31          | 780     | 2020-04-30        | 1405    |
| 14          | 2020-01-31          | 205     | 2020-04-30        | 989     |
| 15          | 2020-01-31          | 379     | 2020-04-30        | 1102    |
| 20          | 2020-01-31          | 465     | 2020-04-30        | 776     |
| 30          | 2020-01-31          | 33      | 2020-04-30        | 508     |
| 33          | 2020-01-31          | 473     | 2020-04-30        | 989     |
| 36          | 2020-01-31          | 149     | 2020-04-30        | 427     |

> Note: The presented dataset comprises 10 out of 117 rows of of the resulting table.

</br>

```pgsql
SELECT COUNT(bd1.customer_id) AS increasing_balance_customer_count,
       (SELECT COUNT(DISTINCT customer_id) 
	FROM data_bank.balance_by_day) AS total_customer_count,
       (100.0 * COUNT(bd1.customer_id) / (SELECT COUNT(DISTINCT customer_id) 
					  FROM data_bank.balance_by_day))::DECIMAL(5,1) AS increasing_balance_customer_pct
FROM data_bank.balance_by_day AS bd1 
JOIN data_bank.balance_by_day AS bd2 ON bd1.customer_id = bd2.customer_id
WHERE bd1.date = DATE_TRUNC('month', bd1.date) + INTERVAL '1 month - 1 day'
  AND bd2.date = DATE_TRUNC('month', bd2.date) + INTERVAL '1 month - 1 day'
  AND DATE_PART('month', bd1.date) = 1
  AND DATE_PART('month', bd2.date) = 4
  AND bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5;
```
| increasing_balance_customer_count | total_customer_count | increasing_balance_customer_pct |
|-----------------------------------|----------------------|---------------------------------|
| 117                               | 500                  | 23.4                            |

</br>

```pgsql
WITH balance_within_month_order_cte AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_PART('month', date)
                             ORDER BY date) AS balance_within_month_order_ASC,
          ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_PART('month', date)
                             ORDER BY date DESC) AS balance_within_month_order_DESC
   FROM data_bank.balance_by_day)
SELECT bm1.customer_id,
       bm1.date AS start_of_month_date,
       bm1.balance AS start_of_month_balance,
       bm2.date AS end_of_month_date,
       bm2.balance AS end_of_month_balance
FROM balance_within_month_order_cte AS bm1
JOIN balance_within_month_order_cte AS bm2 ON bm2.customer_id = bm1.customer_id
WHERE bm1.balance_within_month_order_ASC = 1
  AND bm2.balance_within_month_order_DESC = 1
  AND DATE_PART('month', bm1.date) = DATE_PART('month', bm2.date)
  AND bm2.date = DATE_TRUNC('month', bm2.date) + INTERVAL '1 month - 1 day'
  AND bm1.date < bm2.date
ORDER BY 1, 2;
```
| customer_id | start_of_month_date | start_of_month_balance | end_of_month_date | end_of_month_balance |
|-------------|---------------------|------------------------|-------------------|----------------------|
| 1           | 2020-01-02          | 312                    | 2020-01-31        | 312                  |
| 1           | 2020-02-01          | 312                    | 2020-02-29        | 312                  |
| 1           | 2020-03-01          | 312                    | 2020-03-31        | -640                 |
| 1           | 2020-04-01          | -640                   | 2020-04-30        | -640                 |
| 2           | 2020-01-03          | 549                    | 2020-01-31        | 549                  |
| 2           | 2020-02-01          | 549                    | 2020-02-29        | 549                  |
| 2           | 2020-03-01          | 549                    | 2020-03-31        | 610                  |
| 2           | 2020-04-01          | 610                    | 2020-04-30        | 610                  |
| 3           | 2020-01-27          | 144                    | 2020-01-31        | 144                  |
| 3           | 2020-02-01          | 144                    | 2020-02-29        | -821                 |

> Note: The presented dataset comprises 10 out of 2,000 rows of of the resulting table.

</br>

```pgsql
WITH balance_within_month_order_cte AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_PART('month', date)
                             ORDER BY date) AS balance_within_month_order_ASC,
	  ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_PART('month', date)
			     ORDER BY date DESC) AS balance_within_month_order_DESC
   FROM data_bank.balance_by_day),
     balance_within_month_cte AS
  (SELECT bm1.customer_id,
          bm1.date AS start_of_month_date,
          bm1.balance AS start_of_month_balance,
          bm2.date AS end_of_month_date,
          bm2.balance AS end_of_month_balance
   FROM balance_within_month_order_cte AS bm1
   JOIN balance_within_month_order_cte AS bm2 ON bm2.customer_id = bm1.customer_id
   WHERE bm1.balance_within_month_order_ASC = 1
     AND bm2.balance_within_month_order_DESC = 1
     AND DATE_PART('month', bm1.date) = DATE_PART('month', bm2.date)
     AND bm2.date = DATE_TRUNC('month', bm2.date) + INTERVAL '1 month - 1 day'
     AND bm1.date < bm2.date),
     balance_change_calculating_cte AS
  (SELECT TO_CHAR(start_of_month_date, 'FMMonth, yyyy') AS month,
          DATE_PART('month', start_of_month_date) AS month_index,
          SUM(CASE
                  WHEN start_of_month_balance != 0
                       AND end_of_month_balance > start_of_month_balance
                       AND 100.0 * (end_of_month_balance - start_of_month_balance) / start_of_month_balance > 5 THEN 1
                  ELSE 0
              END) AS increasing_balance_customer_count,
          COUNT(DISTINCT customer_id) AS total_customer_count
   FROM balance_within_month_cte
   GROUP BY 1, 2)
SELECT month,
       increasing_balance_customer_count,
       total_customer_count,
       (100.0 * increasing_balance_customer_count / total_customer_count)::DECIMAL(5, 1) AS increasing_balance_customer_pct
FROM balance_change_calculating_cte
ORDER BY month_index;
```
| month          | increasing_balance_customer_count | total_customer_count | increasing_balance_customer_pct |
|:---------------|-----------------------------------|----------------------|---------------------------------|
| January, 2020  | 104                               | 500                  | 20.8                            |
| February, 2020 | 120                               | 500                  | 24.0                            |
| March, 2020    | 85                                | 500                  | 17.0                            |
| April, 2020    | 46                                | 500                  | 9.2                             |

---
My solution for **[C. Data Allocation Challenge](C.%20Data%20Allocation%20Challenge.md)**.
