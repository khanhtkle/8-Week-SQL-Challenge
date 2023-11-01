# :bank: Case Study 4 - Data Bank

## A. Customer Nodes Exploration

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Data Cleaning

Create a table `customer_nodes_aggregated`:
- In this procedure, our goal is to remove invalid data (data with year of `end_date` in 9999) and refine `start_date` and `end_date` for data instances where their `node_id` remains unchanged after data allocation (e.g. data with `customer_id` set to 24, 26, 27,...). This will allow us to easily calculate metrics relevant to customer nodes and data allocation in the future.

	- Set up the 1<sup>st</sup> a common expression table `table node_date_filtering_1_cte` from `customer_nodes` table:
  		- Establish the core data by including the `customer_id`, `region_id`, `node_id`, `start_date` and `end_date`.
  		- Create a column `previous_node_id` to indicate the `node_id` in the previous data allocation of each customer.
 		- Create a column `next_node_id` to indicate the `node_id` in the next data allocation of each customer.
 		- Filter and exclude data where the value `end_date` is in 9999.
  	
   - Set up the 2<sup>nd</sup> common expression table `table node_date_filtering_2_cte` from `node_date_filtering_1_cte` table:
	  	- Establish the core data by including the `customer_id`, `region_id`, `node_id`, `start_date` and `end_date`.
	  	- Create a column `previous_node_id_2` to indicate the `node_id` of the row currently standing above.
	  	- Create a column `next_node_id_2` to indicate the `node_id` of the row currently standing below.
	  	- Create a column `next_end_date` to indicate the `end_date` of the row currently standing below.
  		- Filter and exclude data where their `node_id` is similar to either `previous_node_id` or `next_node_id`.
   	
    - Select and filter the desired data from `node_date_filtering_2_cte` table:
   		- Establish the core data by including the `customer_id`, `region_id`, `node_id`, `start_date`.
   	 	- Create a column 'end_date' to indicate:
   	 		- if `node_id` is similar with `next_node_id`, its value will equal to 'next_end_date`.
   	   		- if `node_id` is similar with `next_node_id`, its value will equal to 'next_end_date`.
   	   		- otherwise, keep its value similar with value of `end_date` from `node_date_filtering_2_cte`.
   	  	- Filter and exclude data where their newly created `end_date` is `NULL`.
```tsql
DROP TABLE IF EXISTS data_bank.dbo.customer_nodes_aggregated;
WITH node_date_filtering_1_cte AS
  (SELECT customer_id,
          region_id,
          node_id,
          LAG(node_id) OVER (PARTITION BY customer_id
                             ORDER BY start_date) AS previous_node_id,
          LEAD(node_id) OVER (PARTITION BY customer_id
                              ORDER BY start_date) AS next_node_id,
          start_date,
          end_date
   FROM data_bank.dbo.customer_nodes
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
INTO data_bank.dbo.customer_nodes_aggregated
FROM node_date_filtering_2_cte
WHERE CASE
          WHEN node_id = next_node_id_2 THEN next_end_date
          WHEN node_id = previous_node_id_2 THEN NULL
          ELSE end_date
      END IS NOT NULL;

SELECT * 
FROM data_bank.dbo.customer_nodes_aggregated
ORDER BY customer_id,
         start_date;
```
| customer_id | region_id | node_id | start_date | end_date   |
|-------------|-----------|---------|:-----------|:-----------|
| 1           | 3         | 4       | 2020-01-02 | 2020-01-14 |
| 1           | 3         | 2       | 2020-01-15 | 2020-01-16 |
| 1           | 3         | 5       | 2020-01-17 | 2020-01-28 |
| 1           | 3         | 3       | 2020-01-29 | 2020-02-18 |
| 1           | 3         | 2       | 2020-02-19 | 2020-03-16 |
| 2           | 3         | 5       | 2020-01-03 | 2020-01-17 |
| 2           | 3         | 3       | 2020-01-18 | 2020-02-21 |
| 2           | 3         | 5       | 2020-02-22 | 2020-03-07 |
| 2           | 3         | 2       | 2020-03-08 | 2020-03-12 |
| 2           | 3         | 4       | 2020-03-13 | 2020-03-13 |

> Note: The presented dataset comprises 10 out of 2,491 rows of the `customer_nodes_aggregated` table.

--- 
### Q1. How many unique nodes are there on the Data Bank system?
```tsql
SELECT COUNT(DISTINCT node_id) AS unique_node_count
FROM data_bank.dbo.customer_nodes;
```
| unique_node_count |
|-------------------|
| 5                 |

---
### Q2. What is the number of nodes per region?
```tsql
SELECT cn.region_id,
       region_name,
       COUNT(DISTINCT node_id) AS node_count
FROM data_bank.dbo.customer_nodes AS cn
JOIN data_bank.dbo.regions re ON re.region_id = cn.region_id
GROUP BY cn.region_id,
         region_name
ORDER BY region_id;
```
| region_id | region_name | node_count |
|-----------|-------------|------------|
| 1         | Australia   | 5          |
| 2         | America     | 5          |
| 3         | Africa      | 5          |
| 4         | Asia        | 5          |
| 5         | Europe      | 5          |

---
### Q3. How many customers are allocated to each region?
```tsql
SELECT cn.region_id,
       region_name,
       COUNT(DISTINCT customer_id) AS customer_count
FROM data_bank.dbo.customer_nodes AS cn
JOIN data_bank.dbo.regions re ON re.region_id = cn.region_id
GROUP BY cn.region_id,
         region_name
ORDER BY region_id;
```
| region_id | region_name | customer_count |
|-----------|-------------|----------------|
| 1         | Australia   | 110            |
| 2         | America     | 105            |
| 3         | Africa      | 102            |
| 4         | Asia        | 95             |
| 5         | Europe      | 88             |

---
### Q4. How many days on average are customers reallocated to a different node?
```tsql
SELECT CEILING(AVG(1.0 * DATEDIFF(dd, start_date, end_date) + 1)) AS avg_day_until_the_next_allocation
FROM data_bank.dbo.customer_nodes_aggregated;
```
| avg_day_until_the_next_allocation |
|-----------------------------------|
| 19                                |

---
### Q5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```tsql
WITH day_count_until_the_next_allocation_cte AS
  (SELECT *,
          DATEDIFF(dd, start_date, end_date) + 1 AS day_count_until_the_next_allocation
   FROM data_bank.dbo.customer_nodes_aggregated)
SELECT DISTINCT dc.region_id,
       region_name,
       CEILING(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY day_count_until_the_next_allocation) OVER (PARTITION BY dc.region_id)) AS median,
       CEILING(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY day_count_until_the_next_allocation) OVER (PARTITION BY dc.region_id)) AS eightieth_percentile,
       CEILING(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY day_count_until_the_next_allocation) OVER (PARTITION BY dc.region_id)) AS ninetyfifth_percentile
FROM day_count_until_the_next_allocation_cte AS dc
JOIN data_bank.dbo.regions re ON re.region_id = dc.region_id
ORDER BY region_id;
```
| region_id | region_name | median | eightieth_percentile | ninetyfifth_percentile |
|-----------|-------------|--------|----------------------|------------------------|
| 1         | Australia   | 18     | 27                   | 42                     |
| 2         | America     | 18     | 27                   | 38                     |
| 3         | Africa      | 18     | 28                   | 40                     |
| 4         | Asia        | 18     | 27                   | 41                     |
| 5         | Europe      | 19     | 28                   | 39                     |

---
My solution for **[B. Customer Transactions](B.%20Customer%20Transactions.md)**.
