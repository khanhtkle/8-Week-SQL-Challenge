----------------------------------------------------
-- B. Data Cleaning: Data Allocation Challenge --
----------------------------------------------------
DROP TABLE IF EXISTS data_bank.opening_account_date;
CREATE TABLE data_bank.opening_account_date AS
  (SELECT DISTINCT customer_id,
          MIN(txn_date) OVER (PARTITION BY customer_id
                              ORDER BY txn_date) AS opening_account_date
   FROM data_bank.customer_transactions
   ORDER BY 1);

SELECT *
FROM data_bank.opening_account_date;


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
             DATE_ADD(p_start, INTERVAL 1 MONTH)
      FROM recursive_p_start_cte
      WHERE MONTH(DATE_ADD(p_start, INTERVAL 1 MONTH)) < 5) 
   SELECT *
   FROM recursive_p_start_cte
   ORDER BY 1, 3);
   
SELECT *
FROM data_bank.recursive_p_start;


DROP TABLE IF EXISTS data_bank.recursive_date;
CREATE TABLE data_bank.recursive_date AS
  (WITH RECURSIVE recursive_date_cte AS
     (SELECT customer_id,
             p_start,
             p_start AS date,
             DATE_ADD(DATE_ADD(p_start, INTERVAL 1 MONTH), INTERVAL -1 DAY) AS p_end
      FROM data_bank.recursive_p_start
      UNION ALL 
      SELECT customer_id,
	     p_start,
             DATE_ADD(date, INTERVAL 1 DAY),
             p_end
      FROM recursive_date_cte
      WHERE DATE_ADD(date, INTERVAL 1 DAY) <= p_end) 
   SELECT *
   FROM recursive_date_cte
   ORDER BY 1, 3);

SELECT *
FROM data_bank.recursive_date;


ALTER TABLE data_bank.customer_transactions
DROP COLUMN record_id;

ALTER TABLE data_bank.customer_transactions
ADD COLUMN record_id INTEGER;

SET SQL_SAFE_UPDATES = 0;
SET @x = 0;
UPDATE data_bank.customer_transactions 
SET record_id = (@x:=@x+1);

SELECT *
FROM data_bank.customer_transactions;


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
	     record_id
      FROM data_bank.recursive_date AS rd
      LEFT JOIN data_bank.customer_transactions AS ct ON ct.customer_id = rd.customer_id
						     AND ct.txn_date = rd.date) 
   SELECT *,
	  LEAD(date) OVER (PARTITION BY customer_id
			   ORDER BY date, record_id) AS next_date,
	  ROW_NUMBER() OVER (PARTITION BY customer_id, p_start, p_end, balance
			     ORDER BY date) AS balance_unchanged_p_day_count,
	  DATEDIFF(p_end, p_start) + 1 AS p_month_day_count,
	  ROW_NUMBER() OVER (PARTITION BY customer_id, MONTH(date), balance
			     ORDER BY date) AS balance_unchanged_day_count,
	  DATEDIFF(LAST_DAY(date), CAST(DATE_FORMAT(date, '%Y-%m-01') AS DATE)) + 1 AS month_day_count
   FROM balance_calculating_cte
   ORDER BY 1, 3, 9);

SELECT *
FROM data_bank.customer_transactions_extended;


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
