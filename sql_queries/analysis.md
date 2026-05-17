## Sales Funnel Analytics

## 📌 Solution

### 1. What events exist in the dataset and how active is each one?

``` sql
SELECT
  event_type,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users,
  MIN(event_date) AS earliest,
  MAX(event_date) AS latest
FROM `sql-project-487019.funnel_data_01.user_events`
GROUP BY event_type
```

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/1.png)


- 5 distinct event types confirm a clean 5-stage funnel. Page views are 6 times more frequent than purchases - expected for an e-commerce dataset of this scale.

### 2. What are the raw funnel stage volumes over the last 30 days?
```sql
WITH
  max_event_date_cte AS (
    SELECT MAX(event_date) AS latest_event_date
    FROM `sql-project-487019.funnel_data_01.user_events`
  ),
  funnel_stages AS (
    SELECT
      COUNT(DISTINCT CASE WHEN event_type = 'page_view'      THEN user_id END) AS stage_1_views,
      COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'    THEN user_id END) AS stage_2_cart,
      COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
      COUNT(DISTINCT CASE WHEN event_type = 'payment_info'   THEN user_id END) AS stage_4_payment,
      COUNT(DISTINCT CASE WHEN event_type = 'purchase'       THEN user_id END) AS stage_5_purchase
    FROM `sql-project-487019.funnel_data_01.user_events`, max_event_date_cte
    WHERE event_date >= TIMESTAMP(DATE_SUB(DATE(max_event_date_cte.latest_event_date), INTERVAL 30 DAY))
  )
SELECT * FROM funnel_stages
```

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/2.png)

- Count distinct users who reached each stage (page view -> cart -> checkout -> payment -> purchase) in the rolling 30-day window.
- 4K visitors in 30 days narrows to 709 purchasers.

### 3. What is the conversion rate across the funnel?
```sql
WITH funnel_stages AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view'      THEN user_id END) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'    THEN user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info'   THEN user_id END) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'       THEN user_id END) AS stage_5_purchase
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
)
SELECT
  stage_1_views,
  stage_2_cart,
  ROUND(stage_2_cart    * 100 / stage_1_views)     AS view_to_cart_rate,
  stage_3_checkout,
  ROUND(stage_3_checkout* 100 / stage_2_cart)      AS cart_to_checkout_rate,
  stage_4_payment,
  ROUND(stage_4_payment * 100 / stage_3_checkout)  AS checkout_to_payment_rate,
  stage_5_purchase,
  ROUND(stage_5_purchase* 100 / stage_4_payment)   AS payment_to_purchase_rate,
  ROUND(stage_5_purchase* 100 / stage_1_views)     AS overall_conversion_rate
FROM funnel_stages

```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/3.png)

- View -> cart at 31% is the weakest step — nearly 2 in 3 visitors never add anything. Once in checkout, users convert well (72–74%). Product discovery & merchandising is the top priority.
### 4. Where is the biggest drop-off in the funnel?

```sql
WITH funnel_stages AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view'      THEN user_id END) AS s1,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'    THEN user_id END) AS s2,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS s3,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info'   THEN user_id END) AS s4,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'       THEN user_id END) AS s5
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
),
dropoffs AS (
  SELECT 'view -> cart'         AS transition, s1 - s2 AS users_lost, ROUND((s1-s2)*100/s1) AS percent_lost FROM funnel_stages
  UNION ALL
  SELECT 'cart -> checkout' ,  s2 - s3, ROUND((s2-s3)*100/s2) FROM funnel_stages
  UNION ALL
  SELECT 'checkout -> payment' ,  s3 - s4, ROUND((s3-s4)*100/s3) FROM funnel_stages
  UNION ALL
  SELECT 'payment -> purchase' ,  s4 - s5, ROUND((s4-s5)*100/s4) FROM funnel_stages
)
SELECT * FROM dropoffs ORDER BY users_lost DESC
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/4.png)

- View -> cart loses 2,953 users (69%) — more than the next three stages combined. This is the #1 optimisation opportunity.

### 5. Which traffic sources drive the most visitors, cart adds, and purchases?
```sql
WITH source_funnel AS (
  SELECT
    traffic_source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view'  THEN user_id END) AS views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'THEN user_id END) AS carts,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'   THEN user_id END) AS purchases
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY traffic_source
)
SELECT
  traffic_source, views, carts, purchases,
  ROUND(carts     * 100 / views) AS cart_conversion_rate,
  ROUND(purchases * 100 / views) AS purchase_conversion_rate,
  ROUND(purchases * 100 / carts) AS cart_to_purchase_rate
FROM source_funnel
ORDER BY purchases DESC
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/5.png)

- Emails converts at 34% despite low volume — strongest purchase rate. Social media is weakest at 3%.

### 6. Which traffic source has the best overall purchase conversion rate?
```sql
WITH source_funnel AS (
  SELECT
    traffic_source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'  THEN user_id END) AS purchases
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY traffic_source
)
SELECT
  traffic_source,
  views,
  purchases,
  ROUND(purchases * 100.0 / views, 2) AS purchase_conversion_rate
FROM source_funnel
WHERE views > 0
ORDER BY purchase_conversion_rate DESC
LIMIT 1;
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/6.png)
### 7. How long does a converted user take to move from view to purchase?
```sql
WITH user_journey AS (
  SELECT
    user_id,
    MIN(CASE WHEN event_type = 'page_view'  THEN event_date END) AS view_time,
    MIN(CASE WHEN event_type = 'add_to_cart'THEN event_date END) AS cart_time,
    MIN(CASE WHEN event_type = 'purchase'   THEN event_date END) AS purchase_time
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)
SELECT
  COUNT(*) AS converted_users,
  ROUND(AVG(TIMESTAMP_DIFF(cart_time,     view_time,    MINUTE)), 2) AS avg_view_to_cart_min,
  ROUND(AVG(TIMESTAMP_DIFF(purchase_time, cart_time,    MINUTE)), 2) AS avg_cart_to_purchase_min,
  ROUND(AVG(TIMESTAMP_DIFF(purchase_time, view_time,    MINUTE)), 2) AS avg_total_journey_min
FROM user_journey;
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/7.png)
### 8. How does journey speed vary by traffic source for converted users?
```sql
WITH user_journey AS (
  SELECT
    user_id,
    MAX(traffic_source) AS traffic_source,
    MIN(CASE WHEN event_type = 'page_view'  THEN event_date END) AS view_time,
    MIN(CASE WHEN event_type = 'purchase'   THEN event_date END) AS purchase_time
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)
SELECT
  traffic_source,
  COUNT(*) AS converted_users,
  ROUND(AVG(TIMESTAMP_DIFF(purchase_time, view_time, MINUTE)), 1) AS avg_journey_minutes
FROM user_journey
GROUP BY traffic_source
ORDER BY avg_journey_minutes;
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/8.png)
### 9. What is the total revenue, average order value, and revenue per visitor?
```sql
WITH funnel_revenue AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'  THEN user_id END) AS total_buyers,
    SUM  (CASE WHEN event_type = 'purchase'  THEN amount   END) AS total_revenue,
    COUNT(CASE WHEN event_type = 'purchase'  THEN 1       END) AS total_orders
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
)
SELECT
  total_visitors,
  total_buyers,
  total_orders,
  ROUND(total_revenue,                    2) AS total_revenue,
  ROUND(total_revenue / total_orders,     2) AS avg_order_value,
  ROUND(total_revenue / total_buyers,     2) AS revenue_per_buyer,
  ROUND(total_revenue / total_visitors,   2) AS revenue_per_visitor
FROM funnel_revenue;
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/9.png)
### 10. Which traffic source generates the most revenue and highest AOV?
```sql
WITH source_revenue AS (
  SELECT
    traffic_source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS visitors,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END)                   AS orders,
    SUM  (CASE WHEN event_type = 'purchase' THEN amount END)              AS revenue
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY traffic_source
)
SELECT
  traffic_source,
  visitors,
  orders,
  ROUND(revenue,               2) AS total_revenue,
  ROUND(revenue / orders,      2) AS avg_order_value,
  ROUND(revenue / visitors,    2) AS revenue_per_visitor
FROM source_revenue
WHERE orders > 0
ORDER BY total_revenue DESC;
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/10.png)
### 11. How do revenue KPIs trend week over week?
```sql
SELECT
  DATE_TRUNC(event_date, WEEK) AS week_start,
  COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS visitors,
  COUNT(CASE WHEN event_type = 'purchase' THEN 1 END)                   AS orders,
  ROUND(SUM(CASE WHEN event_type = 'purchase' THEN amount END), 2)     AS revenue,
  ROUND(
    SUM(CASE WHEN event_type = 'purchase' THEN amount END) /
    NULLIF(COUNT(CASE WHEN event_type = 'purchase' THEN 1 END), 0), 2
  ) AS avg_order_value
FROM `sql-project-487019.funnel_data_01.user_events`
WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
GROUP BY week_start
ORDER BY week_start;
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/11.png)
### 12. What share of users who added to cart ultimately purchased? (cart abandonment)
```sql
WITH cart_users AS (
  SELECT
    user_id,
    MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
    MAX(CASE WHEN event_type = 'purchase'    THEN 1 ELSE 0 END) AS purchased
  FROM `sql-project-487019.funnel_data_01.user_events`
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY user_id
)
SELECT
  COUNTIF(added_to_cart = 1)                  AS cart_users,
  COUNTIF(added_to_cart = 1 AND purchased = 1)          AS cart_converters,
  COUNTIF(added_to_cart = 1 AND purchased = 0)             AS cart_abandoners,
  ROUND(COUNTIF(added_to_cart=1 AND purchased=0) * 100.0
        / NULLIF(COUNTIF(added_to_cart=1), 0), 1)              AS cart_abandonment_rate_pct
FROM cart_users;
```
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/12.png)
