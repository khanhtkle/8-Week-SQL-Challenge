-------------------------------------
-- D. Extra Challenge --
-------------------------------------
-- 	Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.
-- 	If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?
-- 	Special notes:
-- 		- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

-- nci)

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

SELECT TO_CHAR(date, 'FMMonth, yyyy') AS month,
       SUM(balance_with_daily_n_c_i_reward)::DECIMAL(10, 0) AS data_required
FROM data_bank.balance_with_daily_n_c_i_reward
GROUP BY 1, DATE_PART('month', date)
ORDER BY DATE_PART('month', date);

-- nci)

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

SELECT TO_CHAR(date, 'FMMonth, yyyy') AS month,
       SUM(balance_with_daily_c_i_reward)::DECIMAL(10, 0) AS data_required
FROM data_bank.balance_with_daily_c_i_reward
GROUP BY 1, DATE_PART('month', date)
ORDER BY DATE_PART('month', date);
