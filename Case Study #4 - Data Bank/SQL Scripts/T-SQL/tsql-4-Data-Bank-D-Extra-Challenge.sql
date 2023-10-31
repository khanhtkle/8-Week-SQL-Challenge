-------------------------------------
-- D. Extra Challenge --
-------------------------------------
--	Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.
--	If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?
--	Special notes:
--		- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

-- nci)

DROP TABLE IF EXISTS data_bank.dbo.balance_with_daily_n_c_i_reward;
SELECT customer_id,
       date, 
       CAST(balance * (1 + CAST(0.06 AS DECIMAL(9,4)) / 366) AS DECIMAL(9,4)) AS balance_with_daily_n_c_i_reward
INTO data_bank.dbo.balance_with_daily_n_c_i_reward
FROM data_bank.dbo.balance_by_day
WHERE MONTH(date) < 5;

SELECT *
FROM data_bank.dbo.balance_with_daily_n_c_i_reward
ORDER BY customer_id, 
	 date;

SELECT FORMAT(date, 'yyyy, MMMM') AS month,
       CAST(SUM(balance_with_daily_n_c_i_reward) AS DECIMAL(10,0)) AS data_required
FROM data_bank.dbo.balance_with_daily_n_c_i_reward
GROUP BY FORMAT(date, 'yyyy, MMMM'),
         MONTH(date)
ORDER BY MONTH(date);

-- nci)

DROP TABLE IF EXISTS data_bank.dbo.first_and_last_balance_by_day;
SELECT customer_id,
       MIN(date) AS first_date,
       MAX(date) AS last_date
INTO data_bank.dbo.first_and_last_balance_by_day
FROM data_bank.dbo.balance_by_day
WHERE MONTH(date) < 5
GROUP BY customer_id;

SELECT *
FROM data_bank.dbo.first_and_last_balance_by_day
ORDER BY customer_id;


DROP TABLE IF EXISTS data_bank.dbo.balance_with_daily_c_i_reward;
WITH recursive_cte AS
  (SELECT fl.customer_id,
          first_date AS date,
          last_date,
          total_txn_amount_by_day,
          CAST(balance * (1 + CAST(0.06 AS DECIMAL(9, 4)) / 366) AS DECIMAL(9, 4)) AS balance_with_daily_c_i_reward
   FROM data_bank.dbo.first_and_last_balance_by_day AS fl
   JOIN data_bank.dbo.balance_by_day AS bd ON bd.customer_id = fl.customer_id
   					  AND bd.date = fl.first_date
   UNION ALL
   SELECT re.customer_id,
          DATEADD(dd, 1, re.date),
          last_date,
          bd.total_txn_amount_by_day,
          CASE
              WHEN bd.total_txn_amount_by_day IS NULL THEN CAST(balance_with_daily_c_i_reward * (1 + CAST(0.06 AS DECIMAL(9, 4)) / 366) AS DECIMAL(9, 4))
              ELSE CAST((balance_with_daily_c_i_reward + bd.total_txn_amount_by_day) * (1 + CAST(0.06 AS DECIMAL(9, 4)) / 366) AS DECIMAL(9, 4))
          END
   FROM recursive_cte AS re
   JOIN data_bank.dbo.balance_by_day AS bd ON bd.customer_id = re.customer_id
                                          AND bd.date = DATEADD(dd, 1, re.date)
   WHERE DATEADD(dd, 1, re.date) <= last_date)
SELECT re.customer_id,
       re.date,
       re.total_txn_amount_by_day,
       balance_with_daily_c_i_reward INTO data_bank.dbo.balance_with_daily_c_i_reward
FROM recursive_cte AS re
JOIN data_bank.dbo.balance_by_day AS bd ON bd.customer_id = re.customer_id
                                       AND bd.date = re.date OPTION (MAXRECURSION 1000);

SELECT *
FROM data_bank.dbo.balance_with_daily_c_i_reward
ORDER BY customer_id,
         date;

SELECT FORMAT(date, 'yyyy, MMMM') AS month,
       CAST(SUM(balance_with_daily_c_i_reward) AS DECIMAL(10,0)) AS data_required
FROM data_bank.dbo.balance_with_daily_c_i_reward
GROUP BY FORMAT(date, 'yyyy, MMMM'),
         MONTH(date)
ORDER BY MONTH(date);
