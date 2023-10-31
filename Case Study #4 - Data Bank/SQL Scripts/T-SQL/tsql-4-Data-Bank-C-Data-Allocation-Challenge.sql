----------------------------------------
-- C. Data Allocation Challenge --
----------------------------------------
--	To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
--		- Option 1: data is allocated based off the amount of money at the end of the previous month.
--		- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days.
--		- Option 3: data is updated real-time.
--	For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
--		- running customer balance column that includes the impact each transaction
--		- customer balance at the end of each month
--		- minimum, average and maximum values of the running balance for each customer
--	Using all of the data available - how much data would have been required for each option on a monthly basis?

--	e1)

DROP TABLE IF EXISTS data_bank.dbo.balance_by_txn;
SELECT customer_id,
       date,
       txn_type,
       txn_amount,
       balance,
       record_id
INTO data_bank.dbo.balance_by_txn
FROM data_bank.dbo.customer_transactions_extended
WHERE txn_type IS NOT NULL;

SELECT *
FROM data_bank.dbo.balance_by_txn
ORDER BY customer_id,
         date,
	 record_id;

--	o3)

SELECT FORMAT(date, 'MMMM, yyyy') AS month,
       SUM(balance) AS data_required
FROM data_bank.dbo.balance_by_txn
GROUP BY FORMAT(date, 'MMMM, yyyy'),
         MONTH(date)
ORDER BY MONTH(date);

-- e2)

DROP TABLE IF EXISTS data_bank.dbo.balance_by_end_of_previous_month;
WITH balance_by_previous_month_cte AS
  (SELECT DISTINCT customer_id,
          CAST(FORMAT(MIN(date) OVER (PARTITION BY customer_id
                                      ORDER BY date), 'yyyy-MM-01') AS DATE) AS date,
          0 AS balance
   FROM data_bank.dbo.balance_by_day
   UNION 
   SELECT customer_id,
          DATEADD(dd, 1, date),
          balance
   FROM data_bank.dbo.balance_by_day
   WHERE date = EOMONTH(date))
SELECT customer_id,
       FORMAT(date, 'yyyy, MMMM') AS month,
       MONTH(date) AS month_index,
       balance AS balance_by_end_of_previous_month 
INTO data_bank.dbo.balance_by_end_of_previous_month
FROM balance_by_previous_month_cte;

SELECT * 
FROM data_bank.dbo.balance_by_end_of_previous_month
ORDER BY customer_id, 
	 month_index;

--	o1)

SELECT month, 
       SUM(balance_by_end_of_previous_month) AS data_required
FROM data_bank.dbo.balance_by_end_of_previous_month
GROUP BY month,
	 month_index
ORDER BY month_index;

-- e3a)

DROP TABLE IF EXISTS data_bank.dbo.monthly_avg_balance;
SELECT customer_id,
       FORMAT(date, 'yyyy, MMMM') AS month,
       MONTH(date) AS month_index,
       MIN(balance) AS min_balance,
       CAST(ROUND(AVG(1.0 * balance), 1) AS REAL) AS avg_balance,
       MAX(balance) AS max_balance
INTO data_bank.dbo.monthly_avg_balance
FROM data_bank.dbo.balance_by_day
WHERE MONTH(date) < 5
GROUP BY customer_id,
	 FORMAT(date, 'yyyy, MMMM'),
         MONTH(date);

SELECT * 
FROM data_bank.dbo.monthly_avg_balance
ORDER BY customer_id,
         month_index;

-- e3b)

DROP TABLE IF EXISTS data_bank.dbo.p_monthly_avg_balance;
SELECT customer_id,
       FORMAT(p_start, 'yyyy, MMMM') AS p_month,
       MONTH(p_start) AS p_month_index,
       MIN(balance) AS p_min_balance,
       CAST(ROUND(AVG(1.0 * balance), 1) AS REAL) AS p_avg_balance,
       MAX(balance) AS p_max_balance
INTO data_bank.dbo.p_monthly_avg_balance
FROM data_bank.dbo.balance_by_day
GROUP BY customer_id,
         p_start;

SELECT * 
FROM data_bank.dbo.p_monthly_avg_balance
ORDER BY customer_id,
         p_month_index;

-- o2a)

SELECT month,
       CEILING(SUM(avg_balance)) AS data_required
FROM data_bank.dbo.monthly_avg_balance
GROUP BY month,
         month_index
ORDER BY month_index;

-- o2b)

SELECT p_month, 
       CEILING(SUM(p_avg_balance)) AS data_required
FROM data_bank.dbo.p_monthly_avg_balance
GROUP BY p_month,
	 p_month_index
ORDER BY p_month_index;
