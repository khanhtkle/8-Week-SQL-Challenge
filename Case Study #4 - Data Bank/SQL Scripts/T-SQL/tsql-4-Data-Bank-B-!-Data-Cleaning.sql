----------------------------------------------------
-- B. Data Cleaning: Data Allocation Challenge --
----------------------------------------------------
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
