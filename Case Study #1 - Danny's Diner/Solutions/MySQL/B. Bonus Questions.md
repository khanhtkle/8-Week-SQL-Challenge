# :ramen: Case Study 1 - Danny's Diner 

## B. Bonus Questions 

<picture>
  <img src="https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white">
</picture>

### Q1. Join All The Things - Create a table that has these columns: customer_id, order_date, product_name, price, member (Y/N).
```MySQL
SELECT sa.customer_id,
       order_date,
       product_name,
       price,
       CASE
           WHEN order_date < join_date
                OR join_date IS NULL THEN 'N'
           ELSE 'Y'
       END AS member
FROM dannys_diner.sales AS sa
JOIN dannys_diner.menu AS mn ON mn.product_id = sa.product_id
LEFT JOIN dannys_diner.members AS mb ON mb.customer_id = sa.customer_id
ORDER BY sa.customer_id,
         order_date,
         product_name;
```
| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

### Q2. Rank All The Things - Based on the table above, add one column: ranking.
```MySQL
SELECT sa.customer_id,
       order_date,
       product_name,
       price,
       CASE
           WHEN order_date < join_date
                OR join_date IS NULL THEN 'N'
           ELSE 'Y'
       END AS member,
       CASE
           WHEN order_date < join_date
                OR join_date IS NULL THEN NULL
           ELSE DENSE_RANK() OVER (PARTITION BY (CASE
                                                     WHEN order_date < join_date
                                                          OR join_date IS NULL THEN NULL
                                                     ELSE sa.customer_id
                                                 END)
                                   ORDER BY order_date)
       END AS ranking
FROM dannys_diner.dbo.sales AS sa
JOIN dannys_diner.dbo.menu AS mn ON mn.product_id = sa.product_id
LEFT JOIN dannys_diner.dbo.members AS mb ON mb.customer_id = sa.customer_id
ORDER BY sa.customer_id,
         order_date,
         product_name;
```
| customer_id | order_date | product_name | price | member | ranking |
|-------------|------------|--------------|-------|--------|---------|
| A           | 2021-01-01 | curry        | 15    | N      | NULL    |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | NULL    |
| B           | 2021-01-02 | curry        | 15    | N      | NULL    |
| B           | 2021-01-04 | sushi        | 10    | N      | NULL    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07 | ramen        | 12    | N      | NULL    |
