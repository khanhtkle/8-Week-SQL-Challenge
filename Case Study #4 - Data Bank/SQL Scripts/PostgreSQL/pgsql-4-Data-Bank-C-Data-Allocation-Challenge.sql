----------------------------------------
-- C. Data Allocation Challenge --
----------------------------------------
-- 	To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
-- 		- Option 1: data is allocated based off the amount of money at the end of the previous month.
-- 		- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days.
-- 		- Option 3: data is updated real-time.
-- 	For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
-- 		- running customer balance column that includes the impact each transaction
-- 		- customer balance at the end of each month
-- 		- minimum, average and maximum values of the running balance for each customer
-- 	Using all of the data available - how much data would have been required for each option on a monthly basis?

-- 	e1)

DROP TABLE IF EXISTS data_bank.balance_by_txn;
CREATE TABLE data_bank.balance_by_txn AS (
SELECT customer_id,
       date,
       txn_type,
       txn_amount,
       balance,
       customer_transactions_row_number
FROM data_bank.customer_transactions_extended
WHERE txn_type IS NOT NULL
ORDER BY 1, 2, 6);

SELECT *
FROM data_bank.balance_by_txn;

-- 	o3)

SELECT TO_CHAR(date, 'FMMonth, yyyy') AS month,
       SUM(balance) AS data_required
FROM data_bank.balance_by_txn
GROUP BY 1;

-- e2)

DROP TABLE IF EXISTS data_bank.balance_by_end_of_previous_month;
CREATE TABLE data_bank.balance_by_end_of_previous_month AS
  (WITH balance_by_previous_month_cte AS
     (SELECT DISTINCT customer_id,
             DATE_TRUNC('month', (MIN(date) OVER (PARTITION BY customer_id
                                                  ORDER BY date)))::DATE AS date,
             0 AS balance
      FROM data_bank.balance_by_day
      UNION 
      SELECT customer_id,
             (date + INTERVAL '1 day')::DATE AS date,
             balance
      FROM data_bank.balance_by_day
      WHERE date = DATE_TRUNC('month', date) + INTERVAL '1 month - 1 day') 
   SELECT customer_id,
    	  TO_CHAR(date, 'FMMonth, yyyy') AS MONTH,
	  DATE_PART('month', date) AS month_index,
	  balance AS balance_by_end_of_previous_month
   FROM balance_by_previous_month_cte
   ORDER BY 1, 3);

SELECT * 
FROM data_bank.balance_by_end_of_previous_month;

-- 	o1)

SELECT month, 
       SUM(balance_by_end_of_previous_month) AS data_required
FROM data_bank.balance_by_end_of_previous_month
GROUP BY 1;

-- e3a)

DROP TABLE IF EXISTS data_bank.monthly_avg_balance;
CREATE TABLE data_bank.monthly_avg_balance AS (
SELECT customer_id,
       TO_CHAR(date, 'FMMonth, yyyy') AS month,
       DATE_PART('month', date) AS month_index,
       MIN(balance) AS min_balance,
       ROUND(AVG(balance), 1)::REAL AS avg_balance,
       MAX(balance) AS max_balance
FROM data_bank.balance_by_day
WHERE DATE_PART('month', date) < 5
GROUP BY 1, 2, 3
ORDER BY 1, 3);

SELECT * 
FROM data_bank.monthly_avg_balance;

-- e3b)

DROP TABLE IF EXISTS data_bank.p_monthly_avg_balance;
CREATE TABLE data_bank.p_monthly_avg_balance AS (
SELECT customer_id,
       TO_CHAR(p_start, 'FMMonth, yyyy') AS p_month,
       DATE_PART('month', p_start) AS p_month_index,
       MIN(balance) AS p_min_balance,
       ROUND(AVG(balance), 0) AS p_avg_balance,
       MAX(balance) AS p_max_balance
FROM data_bank.balance_by_day
GROUP BY 1, p_start
ORDER BY 1, p_start);

SELECT * 
FROM data_bank.p_monthly_avg_balance;

-- o2a)

SELECT month,
       CEILING(SUM(avg_balance)) AS data_required
FROM data_bank.monthly_avg_balance
GROUP BY 1, month_index
ORDER BY month_index;

-- o2b)

SELECT p_month, 
       CEILING(SUM(p_avg_balance)) AS data_required
FROM data_bank.p_monthly_avg_balance
GROUP BY 1, p_month_index
ORDER BY p_month_index;
