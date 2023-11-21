# :fish: Case Study 6 - Clique Bait

## C. Campaigns Analysis

<picture>
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white">
</picture>

### Generate a table that has 1 single row for every unique `visit_id` record and has the following columns:
- #### `user_id`
- #### `visit_id`
- #### `visit_start_time`: the earliest `event_time` for each visit
- #### `page_views`: count of page views for each visit
- #### `art_adds`: count of product cart add events for each visit
- #### `purchase`: 1/0 flag if a purchase event exists for each visit
- #### `campaign_name`: map the visit to a campaign if the `visit_start_time falls` between the `start_date` and `end_date`
- #### `impression`: count of ad impressions for each visit
- #### `click`: count of ad clicks for each visit
- #### `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart

### Some ideas to investigate further include:
- ### Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event.
- ### Does clicking on an impression lead to higher purchase rates?
- ### What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
- ### What metrics can you use to quantify the success or failure of each campaign compared to each other?

</br>

```tsql

```

---
