----------------------------------------
-- A. Customer Nodes Exploration --
----------------------------------------
-- 	1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS unique_node_count
FROM data_bank.customer_nodes;

-- 	2. What is the number of nodes per region?

SELECT cn.region_id,
       region_name,
       COUNT(DISTINCT node_id) AS node_count
FROM data_bank.customer_nodes AS cn
JOIN data_bank.regions re ON re.region_id = cn.region_id
GROUP BY 1, 2;

-- 	3. How many customers are allocated to each region?

SELECT cn.region_id,
       region_name,
       COUNT(DISTINCT customer_id) AS customer_count
FROM data_bank.customer_nodes AS cn
JOIN data_bank.regions re ON re.region_id = cn.region_id
GROUP BY 1, 2;

-- 	4. How many days on average are customers reallocated to a different node?

SELECT CEILING(AVG(end_date - start_date) + 1) AS avg_day_until_the_next_allocation
FROM data_bank.customer_nodes_aggregated;

-- 	5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH day_count_until_the_next_allocation_cte AS
  (SELECT *,
          end_date - start_date + 1 AS day_count_until_the_next_allocation
   FROM data_bank.customer_nodes_aggregated)
SELECT DISTINCT dc.region_id,
       region_name,
       CEILING(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY day_count_until_the_next_allocation)) AS median,
       CEILING(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY day_count_until_the_next_allocation)) AS eightieth_percentile,
       CEILING(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY day_count_until_the_next_allocation)) AS ninetyfifth_percentile
FROM day_count_until_the_next_allocation_cte AS dc
JOIN data_bank.regions re ON re.region_id = dc.region_id
GROUP BY 1, 2
ORDER BY 1;
