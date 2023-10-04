----------------------------------------------------
-- A. Data Cleaning: Customer Nodes Exploration --
----------------------------------------------------
DROP TABLE IF EXISTS data_bank.customer_nodes_aggregated;
CREATE TABLE data_bank.customer_nodes_aggregated AS
  (WITH node_date_filtering_1_cte AS
     (SELECT customer_id,
             region_id,
             node_id,
             LAG(node_id) OVER (PARTITION BY customer_id
                                ORDER BY start_date) AS previous_node_id,
			 LEAD(node_id) OVER (PARTITION BY customer_id
								 ORDER BY start_date) AS next_node_id,
			 start_date,
			 end_date
      FROM data_bank.customer_nodes
      WHERE YEAR(end_date) != 9999),
        node_date_filtering_2_cte AS
     (SELECT customer_id,
             region_id,
             node_id,
             start_date,
             end_date,
             LAG(node_id) OVER (PARTITION BY customer_id
                                ORDER BY start_date) AS previous_node_id_2,
			 LEAD(node_id) OVER (PARTITION BY customer_id
								 ORDER BY start_date) AS next_node_id_2,
			 LEAD(end_date) OVER (PARTITION BY customer_id
								  ORDER BY start_date) AS next_end_date
      FROM node_date_filtering_1_cte
      WHERE (previous_node_id IS NULL
             OR next_node_id IS NULL
             OR node_id != previous_node_id
             OR node_id != next_node_id)) 
   SELECT customer_id,
		  region_id,
          node_id,
          start_date,
          CASE
			  WHEN node_id = next_node_id_2 THEN next_end_date
			  WHEN node_id = previous_node_id_2 THEN NULL
			  ELSE end_date
		  END AS end_date
   FROM node_date_filtering_2_cte
   WHERE CASE
             WHEN node_id = next_node_id_2 THEN next_end_date
             WHEN node_id = previous_node_id_2 THEN NULL
             ELSE end_date
         END IS NOT NULL)
ORDER BY 1, 4;

SELECT *
FROM data_bank.customer_nodes_aggregated;
