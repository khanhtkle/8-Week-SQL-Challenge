# :bank: Case Study 4 - Data Bank

## B. Customer Transactions

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Data Cleaning

```tsql
DROP TABLE IF EXISTS data_bank.dbo.customer_transactions_extended;
WITH opening_account_date_cte AS
  (SELECT DISTINCT customer_id,
          MIN(txn_date) OVER (PARTITION BY customer_id
                              ORDER BY txn_date) AS opening_account_date
   FROM data_bank.dbo.customer_transactions),
     recursive_p_start_cte AS
  (SELECT customer_id,
          opening_account_date,
          opening_account_date AS p_start
   FROM opening_account_date_cte
   UNION ALL 
   SELECT customer_id,
	  opening_account_date,
	  DATEADD(mm, 1, p_start)
   FROM recursive_p_start_cte
   WHERE MONTH(DATEADD(mm, 1, p_start)) < 5),
     recursive_date_cte AS
  (SELECT customer_id,
          p_start,
          p_start AS date,
          DATEADD(dd, -1, DATEADD(mm, 1, p_start)) AS p_end
   FROM recursive_p_start_cte
   UNION ALL 
   SELECT customer_id,
	  p_start,
	  DATEADD(dd, 1, date),
	  p_end
   FROM recursive_date_cte
   WHERE DATEADD(dd, 1, date) <= p_end),
     customer_transactions_row_number_cte AS
  (SELECT *,
	  ROW_NUMBER() OVER (PARTITION BY customer_id 
			     ORDER BY txn_date) AS customer_transactions_row_number
   FROM data_bank.dbo.customer_transactions),
     balance_calculating_cte AS
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
                         ORDER BY date, customer_transactions_row_number) AS d_txn_amount,
          SUM(CASE
		  WHEN txn_type = 'deposit' THEN txn_amount
                  ELSE -txn_amount
              END) OVER (PARTITION BY rd.customer_id
			 ORDER BY date, customer_transactions_row_number 
			 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance,
          customer_transactions_row_number
   FROM recursive_date_cte AS rd
   LEFT JOIN customer_transactions_row_number_cte AS ct ON ct.customer_id = rd.customer_id
						       AND ct.txn_date = rd.date)
SELECT *,
       LEAD(date) OVER (PARTITION BY customer_id
                        ORDER BY date, customer_transactions_row_number) AS next_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id, p_start, p_end, balance
                          ORDER BY date) AS balance_unchanged_p_day_count,
       DATEDIFF(dd, p_start, p_end) + 1 AS p_month_day_count,
       ROW_NUMBER() OVER (PARTITION BY customer_id, MONTH(date), balance
			  ORDER BY date) AS balance_unchanged_day_count,
       DATEDIFF(dd, CAST(FORMAT(date, 'yyyy-MM-01') AS DATE), EOMONTH(date)) + 1 AS month_day_count 
INTO data_bank.dbo.customer_transactions_extended
FROM balance_calculating_cte;

SELECT * 
FROM data_bank.dbo.customer_transactions_extended
ORDER BY customer_id, 
	 date, 
	 customer_transactions_row_number;
```
| customer_id | p_start    | date       | p_end      | txn_type | txn_amount | d_txn_amount | balance | customer_transactions_row_number | next_date  | balance_unchanged_p_day_count | p_month_day_count | balance_unchanged_day_count | month_day_count |
|-------------|------------|------------|------------|----------|------------|--------------|---------|----------------------------------|------------|-------------------------------|-------------------|-----------------------------|-----------------|
| 1           | 2020-01-02 | 2020-01-02 | 2020-02-01 | deposit  | 312        | 312          | 312     | 1                                | 2020-01-03 | 1                             | 31                | 1                           | 31              |
| 1           | 2020-01-02 | 2020-01-03 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-04 | 2                             | 31                | 2                           | 31              |
| 1           | 2020-01-02 | 2020-01-04 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-05 | 3                             | 31                | 3                           | 31              |
| 1           | 2020-01-02 | 2020-01-05 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-06 | 4                             | 31                | 4                           | 31              |
| 1           | 2020-01-02 | 2020-01-06 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-07 | 5                             | 31                | 5                           | 31              |
| 1           | 2020-01-02 | 2020-01-07 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-08 | 6                             | 31                | 6                           | 31              |
| 1           | 2020-01-02 | 2020-01-08 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-09 | 7                             | 31                | 7                           | 31              |
| 1           | 2020-01-02 | 2020-01-09 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-10 | 8                             | 31                | 8                           | 31              |
| 1           | 2020-01-02 | 2020-01-10 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-11 | 9                             | 31                | 9                           | 31              |
| 1           | 2020-01-02 | 2020-01-11 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-12 | 10                            | 31                | 10                          | 31              |
| 1           | 2020-01-02 | 2020-01-12 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-13 | 11                            | 31                | 11                          | 31              |
| 1           | 2020-01-02 | 2020-01-13 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-14 | 12                            | 31                | 12                          | 31              |
| 1           | 2020-01-02 | 2020-01-14 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-15 | 13                            | 31                | 13                          | 31              |
| 1           | 2020-01-02 | 2020-01-15 | 2020-02-01 | NULL     | NULL       | NULL         | 312     | NULL                             | 2020-01-16 | 14                            | 31                | 14                          | 31              |

> Note: The presented dataset comprises 14 out of 60,901 rows of the `customer_transactions_extended` table.

</br>

```tsql
DROP TABLE IF EXISTS data_bank.dbo.balance_by_day;
SELECT customer_id,
       p_start, 
       date, 
       p_end,
       d_txn_amount AS total_txn_amount_by_day,
       balance 
INTO data_bank.dbo.balance_by_day
FROM data_bank.dbo.customer_transactions_extended
WHERE next_date IS NULL
      OR date != next_date;

SELECT * 
FROM data_bank.dbo.balance_by_day
ORDER BY customer_id, 
	 date;
```
| customer_id | p_start    | date       | p_end      | total_txn_amount_by_day | balance |
|-------------|------------|------------|------------|-------------------------|---------|
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
| 1           | 2020-01-02 | 2020-01-12 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-13 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-14 | 2020-02-01 | NULL                    | 312     |
| 1           | 2020-01-02 | 2020-01-15 | 2020-02-01 | NULL                    | 312     |

> Note: The presented dataset comprises 14 out of 60,490 rows of the `balance_by_day` table.

--- 
### Q1. What is the unique count and total amount for each transaction type?
```tsql
SELECT txn_type,
       COUNT(*) AS unique_txn_count,
       SUM(txn_amount) AS total_txn_amount
FROM data_bank.dbo.customer_transactions
GROUP BY txn_type
ORDER BY txn_type;
```
| txn_type   | unique_txn_count | total_txn_amount |
|------------|------------------|------------------|
| deposit    | 2671             | 1359168          |
| purchase   | 1617             | 806537           |
| withdrawal | 1580             | 793003           |

---
### Q2. What is the average total historical deposit counts and amounts for all customers?
```tsql
SELECT SUM(1) AS deposit_txn_count,
       (SELECT COUNT(DISTINCT customer_id) 
	FROM data_bank.dbo.customer_transactions) AS total_customer_count,
       SUM(txn_amount) AS total_deposit_txn_amount,
       FLOOR(SUM(1.0) / (SELECT COUNT(DISTINCT customer_id) 
			 FROM data_bank.dbo.customer_transactions)) AS avg_deposit_txn_per_customer,
       CAST(ROUND(SUM(1.0 * txn_amount) / (SELECT COUNT(DISTINCT customer_id) 
					   FROM data_bank.dbo.customer_transactions), 1) AS REAL) AS avg_deposit_txn_per_customer,
       CAST(ROUND(AVG(1.0 * txn_amount), 1) AS REAL) AS avg_txn_amount_per_deposit_txn
FROM data_bank.dbo.customer_transactions
WHERE txn_type = 'deposit';
```
| deposit_txn_count | total_customer_count | total_deposit_txn_amount | avg_deposit_txn_per_customer | avg_deposit_txn_per_customer | avg_txn_amount_per_deposit_txn |
|-------------------|----------------------|--------------------------|------------------------------|------------------------------|--------------------------------|
| 2671              | 500                  | 1359168                  | 5                            | 2718.3                       | 508.9                          |

---
### Q3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```tsql
WITH txn_count_cte AS
  (SELECT FORMAT(txn_date, 'MMMM, yyyy') AS month,
          MONTH(txn_date) AS month_index,
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
   FROM data_bank.dbo.customer_transactions
   GROUP BY FORMAT(txn_date, 'MMMM, yyyy'),
	    MONTH(txn_date),
            customer_id)
SELECT month,
       COUNT(customer_id) AS high_volume_customer_count
FROM txn_count_cte
WHERE deposit_txn_count > 1
  AND (purchase_txn_count >= 1
       OR withdrawal_txn_count >= 1)
GROUP BY month,
         month_index
ORDER BY month_index;
```
| month          | high_volume_customer_count |
|----------------|----------------------------|
| January, 2020  | 168                        |
| February, 2020 | 181                        |
| March, 2020    | 192                        |
| April, 2020    | 70                         |

---
### Q4. What is the closing balance for each customer at the end of the month?
```tsql
SELECT customer_id,
       FORMAT(date, 'MMMM, yyyy') AS month,
       balance
FROM data_bank.dbo.balance_by_day
WHERE date = EOMONTH(date)
GROUP BY customer_id,
         FORMAT(date, 'MMMM, yyyy'),
         MONTH(date),
	 balance
ORDER BY customer_id,
         MONTH(date);
```
| customer_id | month          | balance |
|-------------|----------------|---------|
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
| 3           | March, 2020    | -1222   |
| 3           | April, 2020    | -729    |
| 4           | January, 2020  | 848     |
| 4           | February, 2020 | 848     |

> Note: The presented dataset comprises 14 out of 2,000 rows of of the resulting table.

---
### Q5. What is the percentage of customers who increase their closing balance by more than 5%?
```tsql
WITH first_and_last_txn_date_cte AS
  (SELECT customer_id,
          MIN(date) AS first_txn_date,
          MAX(date) AS last_txn_date
   FROM data_bank.dbo.balance_by_day
   WHERE total_txn_amount_by_day IS NOT NULL
   GROUP BY customer_id)
SELECT fl.customer_id,
       first_txn_date,
       bd1.balance AS balance_by_first_txn_date,
       last_txn_date,
       bd2.balance AS last_balance_by_last_txn_date
FROM first_and_last_txn_date_cte AS fl
JOIN data_bank.dbo.balance_by_day AS bd1 ON bd1.customer_id = fl.customer_id
					AND bd1.date = fl.first_txn_date
JOIN data_bank.dbo.balance_by_day AS bd2 ON bd2.customer_id = fl.customer_id
					AND bd2.date = fl.last_txn_date
WHERE bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5
ORDER BY customer_id;
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
| 36          | 2020-01-30     | 149                       | 2020-04-28    | 427                           |
| 39          | 2020-01-22     | 1429                      | 2020-04-17    | 2516                          |
| 41          | 2020-01-30     | 790                       | 2020-04-25    | 2525                          |
| 43          | 2020-01-28     | 318                       | 2020-04-24    | 545                           |

> Note: The presented dataset comprises 14 out of 161 rows of of the resulting table.

</br>

```tsql
WITH first_and_last_txn_date_cte AS
  (SELECT customer_id,
          MIN(date) AS first_txn_date,
          MAX(date) AS last_txn_date
   FROM data_bank.dbo.balance_by_day
   WHERE total_txn_amount_by_day IS NOT NULL
   GROUP BY customer_id)
SELECT COUNT(fl.customer_id) AS increasing_balance_customer_count,
       (SELECT COUNT(DISTINCT customer_id) 
	FROM data_bank.dbo.balance_by_day) AS total_customer_count,
       CAST(100.0 * COUNT(fl.customer_id) / (SELECT COUNT(DISTINCT customer_id) 
					     FROM data_bank.dbo.balance_by_day) AS DECIMAL(5,1)) AS increasing_balance_customer_pct
FROM first_and_last_txn_date_cte AS fl
JOIN data_bank.dbo.balance_by_day AS bd1 ON bd1.customer_id = fl.customer_id
					AND bd1.date = fl.first_txn_date
JOIN data_bank.dbo.balance_by_day AS bd2 ON bd2.customer_id = fl.customer_id
					AND bd2.date = fl.last_txn_date
WHERE bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5;
```
| increasing_balance_customer_count | total_customer_count | increasing_balance_customer_pct |
|-----------------------------------|----------------------|---------------------------------|
| 161                               | 500                  | 32.2                            |

</br>

```tsql
SELECT customer_id,
       date AS end_of_month_date,
       balance
FROM data_bank.dbo.balance_by_day
WHERE date = EOMONTH(date)
  AND balance = 0;
```
| customer_id | end_of_month_date | balance |
|-------------|-------------------|---------|
| 250         | 2020-02-29        | 0       |
| 306         | 2020-03-31        | 0       |

</br>

```tsql
SELECT bd1.customer_id,
       bd1.date AS start_of_month_date,
       bd1.balance,
       bd2.date end_of_month_date,
       bd2.balance
FROM data_bank.dbo.balance_by_day AS bd1 
JOIN data_bank.dbo.balance_by_day AS bd2 ON bd1.customer_id = bd2.customer_id
WHERE bd1.date = EOMONTH(bd1.date)
  AND bd2.date = EOMONTH(bd2.date)
  AND MONTH(bd1.date) = 1
  AND MONTH(bd2.date) = 4
  AND bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5
ORDER BY customer_id, 
	 start_of_month_date;
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
| 39          | 2020-01-31          | 1429    | 2020-04-30        | 2516    |
| 51          | 2020-01-31          | 301     | 2020-04-30        | 1364    |
| 52          | 2020-01-31          | 1140    | 2020-04-30        | 2612    |
| 53          | 2020-01-31          | 22      | 2020-04-30        | 227     |

> Note: The presented dataset comprises 14 out of 117 rows of of the resulting table.

</br>

```tsql
SELECT COUNT(bd1.customer_id) AS increasing_balance_customer_count,
       (SELECT COUNT(DISTINCT customer_id) 
	FROM data_bank.dbo.balance_by_day) AS total_customer_count,
       CAST(100.0 * COUNT(bd1.customer_id) / (SELECT COUNT(DISTINCT customer_id) 
					      FROM data_bank.dbo.balance_by_day) AS DECIMAL(5,1)) AS increasing_balance_customer_pct
FROM data_bank.dbo.balance_by_day AS bd1 
JOIN data_bank.dbo.balance_by_day AS bd2 ON bd1.customer_id = bd2.customer_id
WHERE bd1.date = EOMONTH(bd1.date)
  AND bd2.date = EOMONTH(bd2.date)
  AND MONTH(bd1.date) = 1
  AND MONTH(bd2.date) = 4
  AND bd2.balance > bd1.balance
  AND 100.0 * (bd2.balance - bd1.balance) / bd1.balance > 5;
```
| increasing_balance_customer_count | total_customer_count | increasing_balance_customer_pct |
|-----------------------------------|----------------------|---------------------------------|
| 117                               | 500                  | 23.4                            |

</br>

```tsql
WITH balance_within_month_order_cte AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY customer_id, MONTH(date)
                             ORDER BY date) AS balance_within_month_order_ASC,
	  ROW_NUMBER() OVER (PARTITION BY customer_id, MONTH(date)
                             ORDER BY date DESC) AS balance_within_month_order_DESC
   FROM data_bank.dbo.balance_by_day)
SELECT bm1.customer_id,
       bm1.date AS start_of_month_date,
       bm1.balance AS start_of_month_balance,
       bm2.date AS end_of_month_date,
       bm2.balance AS end_of_month_balance
FROM balance_within_month_order_cte AS bm1
JOIN balance_within_month_order_cte AS bm2 ON bm2.customer_id = bm1.customer_id
WHERE bm1.balance_within_month_order_ASC = 1
  AND bm2.balance_within_month_order_DESC = 1
  AND MONTH(bm1.date) = MONTH(bm2.date)
  AND bm2.date = EOMONTH(bm2.date)
  AND bm1.date < bm2.date
ORDER BY customer_id,
         start_of_month_date;
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
| 3           | 2020-03-01          | -821                   | 2020-03-31        | -1222                |
| 3           | 2020-04-01          | -1222                  | 2020-04-30        | -729                 |
| 4           | 2020-01-07          | 458                    | 2020-01-31        | 848                  |
| 4           | 2020-02-01          | 848                    | 2020-02-29        | 848                  |

> Note: The presented dataset comprises 14 out of 2,000 rows of of the resulting table.

</br>

```tsql
WITH balance_within_month_order_cte AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY customer_id, MONTH(date)
                             ORDER BY date) AS balance_within_month_order_ASC,
	  ROW_NUMBER() OVER (PARTITION BY customer_id, MONTH(date)
			     ORDER BY date DESC) AS balance_within_month_order_DESC
   FROM data_bank.dbo.balance_by_day),
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
     AND MONTH(bm1.date) = MONTH(bm2.date)
     AND bm2.date = EOMONTH(bm2.date)
     AND bm1.date < bm2.date),
     balance_change_calculating_cte AS
  (SELECT MONTH(start_of_month_date) AS month_index,
          FORMAT(start_of_month_date, 'MMMM, yyyy') AS month,
          SUM(CASE
                  WHEN start_of_month_balance != 0
                       AND end_of_month_balance > start_of_month_balance
                       AND 100.0 * (end_of_month_balance - start_of_month_balance) / start_of_month_balance > 5 THEN 1
                  ELSE 0
              END) AS increasing_balance_customer_count,
          COUNT(DISTINCT customer_id) AS total_customer_count
   FROM balance_within_month_cte
   GROUP BY MONTH(start_of_month_date),
            FORMAT(start_of_month_date, 'MMMM, yyyy'))
SELECT month,
       increasing_balance_customer_count,
       total_customer_count,
       CAST(100.0 * increasing_balance_customer_count / total_customer_count AS DECIMAL(5, 1)) AS increasing_balance_customer_pct
FROM balance_change_calculating_cte
ORDER BY month_index;
```
| month          | increasing_balance_customer_count | total_customer_count | increasing_balance_customer_pct |
|----------------|-----------------------------------|----------------------|---------------------------------|
| January, 2020  | 104                               | 500                  | 20.8                            |
| February, 2020 | 120                               | 500                  | 24.0                            |
| March, 2020    | 85                                | 500                  | 17.0                            |
| April, 2020    | 46                                | 500                  | 9.2                             |

---
My solution for **[C. Data Allocation Challenge](C.%20Data%20Allocation%20Challenge.md)**.
