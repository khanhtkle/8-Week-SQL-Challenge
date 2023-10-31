----------------------------------------------------
-- B. Data Cleaning: Data Allocation Challenge --
----------------------------------------------------
DROP TABLE IF EXISTS data_bank.dbo.opening_account_date;
SELECT DISTINCT customer_id,
       MIN(txn_date) OVER (PARTITION BY customer_id
                           ORDER BY txn_date) AS opening_account_date 
INTO data_bank.dbo.opening_account_date
FROM data_bank.dbo.customer_transactions;

SELECT *
FROM data_bank.dbo.opening_account_date
ORDER BY customer_id;


DROP TABLE IF EXISTS data_bank.dbo.recursive_p_start;
WITH recursive_p_start_cte AS
  (SELECT customer_id,
          opening_account_date,
          opening_account_date AS p_start
   FROM data_bank.dbo.opening_account_date
   UNION ALL 
   SELECT customer_id,
          opening_account_date,
          DATEADD(mm, 1, p_start)
   FROM recursive_p_start_cte
   WHERE MONTH(DATEADD(mm, 1, p_start)) < 5)
SELECT * 
INTO data_bank.dbo.recursive_p_start
FROM recursive_p_start_cte;

SELECT *
FROM data_bank.dbo.recursive_p_start
ORDER BY customer_id,
         p_start;


DROP TABLE IF EXISTS data_bank.dbo.recursive_date;
WITH recursive_date_cte AS
  (SELECT customer_id,
          p_start,
          p_start AS date,
          DATEADD(dd, -1, DATEADD(mm, 1, p_start)) AS p_end
   FROM data_bank.dbo.recursive_p_start
   UNION ALL 
   SELECT customer_id,
          p_start,
	  DATEADD(dd, 1, date),
	  p_end
   FROM recursive_date_cte
   WHERE DATEADD(dd, 1, date) <= p_end)
SELECT * I
INTO data_bank.dbo.recursive_date
FROM recursive_date_cte;

SELECT *
FROM data_bank.dbo.recursive_date
ORDER BY customer_id, 
	 date;


ALTER TABLE data_bank.dbo.customer_transactions
DROP COLUMN IF EXISTS record_id;
GO
	
ALTER TABLE data_bank.dbo.customer_transactions 
ADD record_id INTEGER IDENTITY(1, 1);
GO
	
DROP TABLE IF EXISTS data_bank.dbo.customer_transactions_extended;
WITH balance_calculating_cte AS
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
          record_id
   FROM data_bank.dbo.recursive_date AS rd
   LEFT JOIN data_bank.dbo.customer_transactions AS ct ON ct.customer_id = rd.customer_id
   						      AND ct.txn_date = rd.date)
SELECT *,
       LEAD(date) OVER (PARTITION BY customer_id
                        ORDER BY date, record_id) AS next_date,
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
ORDER BY customer_id, date, record_id;

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
