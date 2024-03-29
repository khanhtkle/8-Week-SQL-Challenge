-------------------------------------
-- B. Customer Transactions
-------------------------------------
-- 	1. What is the unique count and total amount for each transaction type?

SELECT txn_type,
       COUNT(*) AS unique_txn_count,
       SUM(txn_amount) AS total_txn_amount
FROM data_bank.customer_transactions
GROUP BY 1
ORDER BY 1;

-- 	2. What is the average total historical deposit counts and amounts for all customers?

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

-- 	3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

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

-- 	4. What is the closing balance for each customer at the end of the month?

SELECT customer_id,
       TO_CHAR(date, 'FMMonth, yyyy') AS month,
       balance
FROM data_bank.balance_by_day
WHERE date = DATE_TRUNC('month', date) + INTERVAL '1 month - 1 day'
GROUP BY 1, 2, DATE_PART('month', date), 3
ORDER BY 1, DATE_PART('month', date);

-- 	5. What is the percentage of customers who increase their closing balance by more than 5%?
-- 	a1)

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

-- 	a2)

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

-- 	b!)

SELECT customer_id,
       date AS end_of_month_date,
       balance
FROM data_bank.balance_by_day
WHERE date = DATE_TRUNC('month', date) + INTERVAL '1 month - 1 day'
  AND balance = 0;

-- 	b1)

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

-- 	b2)

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

-- 	c1)

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

-- 	c2)

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
