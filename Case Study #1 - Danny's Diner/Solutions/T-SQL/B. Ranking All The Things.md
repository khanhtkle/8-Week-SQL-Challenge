# :ramen: Case Study 1 - Danny's Diner 

## B. Ranking All The Things

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Danny also requires further information about the `ranking` of customer products, but he purposely does not need the `ranking` for non-member purchases so he expects `NULL` values for the records when customers are not yet part of the loyalty program.

To retrieve the datset that look like the example outputs:
- Establish the core by including the `customer_id` and `order_date` from `sales` table.
- Include `product_name` and `price` from 'menu' alongside their respective 'customer_id' and 'order_date'.
- Add a column `member`, which siginifies a customer's membership status as `'Y'` when the customer's `order_date` is later than their `join_date` from `member` table, and `'N'` when it's sooner.
- Add a `ranking` column, which assigns sequential numbers to each customer's orders, with `NULL` values expected for non-member purchases.
```tsql
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
