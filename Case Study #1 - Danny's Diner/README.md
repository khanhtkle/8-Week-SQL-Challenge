# 🍜 Case Study #1 - Danny's Diner

<div align="center">
  <picture>
    <img width="400" src="../IMG/1.png">
  </picture>
</div>

## 📚 Table of Contents <!-- omit in toc -->

- [:briefcase: Business Case](#briefcase-business-case)
- [:mag: Entity Relationship Diagram](#mag-entity-relationship-diagram)
- [:bookmark_tabs: Example Datasets](#bookmark_tabs-example-datasets)
- [:triangular_flag_on_post: Questions and Solution](#triangular_flag_on_post-questions-and-solution)
  
---

## :briefcase: Business Case

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

View the complete business case [HERE](https://8weeksqlchallenge.com/case-study-1).

---

## :mag: Entity Relationship Diagram

<div align="center">
  <picture>
    <img width="60%" src="../IMG/e1.png")>
  </picture>	
</div>

---

## :bookmark_tabs: Example Datasets

<div align="center">

**Table 1: Sales**

| customer_id | order_date | product_id |
| :---------- | :--------- | :--------- |
| A           | 2021-01-01 | 1          |
| A           | 2021-01-01 | 2          |
| A           | 2021-01-07 | 2          |
| A           | 2021-01-10 | 3          |
| A           | 2021-01-11 | 3          |
| A           | 2021-01-11 | 3          |
| B           | 2021-01-01 | 2          |
| B           | 2021-01-02 | 2          |
| B           | 2021-01-04 | 1          |
| B           | 2021-01-11 | 1          |
| B           | 2021-01-16 | 3          |
| B           | 2021-02-01 | 3          |
| C           | 2021-01-01 | 3          |
| C           | 2021-01-01 | 3          |
| C           | 2021-01-07 | 3          |

</div>

<br>

<div align="center">

**Table 2: Menu**

| product_id | product_name | price |
| :--------- | :----------- | :---- |
| 1          | sushi        | 10    |
| 2          | curry        | 15    |
| 3          | ramen        | 12    |

</div>

<br>

<div align="center">

**Table 3: Member**

| customer_id | join_date  |
| :---------- | :--------- |
| A           | 2021-01-07 |
| B           | 2021-01-09 |

</div>

---

## :triangular_flag_on_post: Questions and Solution

### A. Case Study Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
  not just sushi - how many points do customer A and B have at the end of January?

View my solution in:

[![MySQL Badge](https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white)](Solutions/MySQL/A.%20Case%20Study%20Questions.md)
[![PostgreSQL Badge](https://img.shields.io/badge/PostgreSQL-4169e1?style=for-the-badge&logo=postgresql&logoColor=white)](Solutions/PostgreSQL/A.%20Case%20Study%20Questions.md)
[![SMSS Badge](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white)](Solutions/T-SQL/A.%20Case%20Study%20Questions.md)

---

### B. Bonus Questions

1. Join All The Things - Create a table that has these columns: customer_id, order_date, product_name, price, member.
2. Rank All The Things - Based on the table above, add one column: ranking.

View my solutions in:
 
[![MySQL Badge](https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white)](Solutions/MySQL/B.%20Bonus%20Questions.md)
[![PostgreSQL Badge](https://img.shields.io/badge/PostgreSQL-4169e1?style=for-the-badge&logo=postgresql&logoColor=white)](Solutions/PostgreSQL/B.%20Bonus%20Questions.md)
[![SMSS Badge](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white)](Solutions/T-SQL/B.%20Bonus%20Questions.md)
