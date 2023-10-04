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

SELECT CEILING(AVG(DATEDIFF(end_date, start_date) + 1)) AS avg_day_until_the_next_allocation
FROM data_bank.customer_nodes_aggregated;

-- 	5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH day_count_until_the_next_allocation_cte AS
  (SELECT *,
          DATEDIFF(end_date, start_date) + 1 AS day_count_until_the_next_allocation,
          ROW_NUMBER () OVER (PARTITION BY region_id
                              ORDER BY DATEDIFF(end_date, start_date) + 1) AS value_position
   FROM data_bank.customer_nodes_aggregated),
     total_value_count_cte AS
  (SELECT region_id,
          COUNT(*) AS total_value_count
   FROM data_bank.customer_nodes_aggregated
   GROUP BY 1),
     percentile_condition_cte AS (
   SELECT dc.region_id,
          CAST(MIN(ABS(value_position / total_value_count - 0.5)) AS DECIMAL(9,4)) AS median_condition,
          CAST(MIN(ABS(value_position / total_value_count - 0.8)) AS DECIMAL(9,4)) AS eightieth_percentile_condition,
          CAST(MIN(ABS(value_position / total_value_count - 0.95)) AS DECIMAL(9,4)) AS ninetyfifth_percentile_condition
   FROM day_count_until_the_next_allocation_cte AS dc
   JOIN total_value_count_cte AS tv ON tv.region_id = dc.region_id
   GROUP BY 1),  
     percentile_test_value_cte AS
  (SELECT dc.*,
          CAST(ABS(value_position / total_value_count - 0.5) AS DECIMAL(9,4)) AS median_test_value,
          CAST(ABS(value_position / total_value_count - 0.8) AS DECIMAL(9,4)) AS eightieth_percentile_test_value,
          CAST(ABS(value_position / total_value_count - 0.95) AS DECIMAL(9,4)) AS ninetyfifth_percentile_test_value
   FROM day_count_until_the_next_allocation_cte AS dc
   JOIN total_value_count_cte AS tv ON tv.region_id = dc.region_id) ,
     median_percentile AS
  (SELECT DISTINCT pt.region_id,
		  FIRST_VALUE(day_count_until_the_next_allocation) OVER (PARTITION BY pt.region_id 
															     ORDER BY day_count_until_the_next_allocation DESC) AS median
   FROM percentile_test_value_cte AS pt
   JOIN percentile_condition_cte AS pc ON pc.region_id = pt.region_id
    AND pt.median_test_value = pc.median_condition),
     eightieth_percentile_cte AS
  (SELECT DISTINCT pt.region_id,
		  FIRST_VALUE(day_count_until_the_next_allocation) OVER (PARTITION BY pt.region_id 
																 ORDER BY day_count_until_the_next_allocation DESC) AS eightieth_percentile
   FROM percentile_test_value_cte AS pt
   JOIN percentile_condition_cte AS pc ON pc.region_id = pt.region_id
    AND pt.eightieth_percentile_test_value = pc.eightieth_percentile_condition)
SELECT DISTINCT pt.region_id,
	   region_name,
	   median,
	   eightieth_percentile,
	   FIRST_VALUE(day_count_until_the_next_allocation) OVER (PARTITION BY pt.region_id 
															  ORDER BY day_count_until_the_next_allocation DESC) AS ninetyfifth_percentile
FROM percentile_test_value_cte AS pt
JOIN percentile_condition_cte AS pc ON pc.region_id = pt.region_id
								   AND pt.ninetyfifth_percentile_test_value = pc.ninetyfifth_percentile_condition
JOIN median_percentile AS mp ON mp.region_id = pt.region_id
JOIN eightieth_percentile_cte AS ep ON ep.region_id = pt.region_id
JOIN data_bank.regions re ON re.region_id = pt.region_id;		
