SELECT * FROM `sql-project-487019.funnel_data_01.user_events` LIMIT 100

--1. What events exist in the dataset and how active is each one?

SELECT
  event_type,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users,
  MIN(event_date) AS earliest,
  MAX(event_date) AS latest
FROM `sql-project-487019.funnel_data_01.user_events`
GROUP BY event_type

-- 2. What are the raw funnel stage volumes over the last 30 days?

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

-- 3. What is the conversion rate across the funnel?

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


--4. Where is the biggest drop-off in the funnel?

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


--5. Which traffic sources drive the most visitors, cart adds, and purchases?

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

--6. Which traffic source has the best overall purchase conversion rate?

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
LIMIT 1

--7. How long does a converted user take to move from view to purchase?

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

--8. How does journey speed vary by traffic source for converted users?

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
ORDER BY avg_journey_minutes

--9. What is the total revenue, average order value, and revenue per visitor?

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
FROM funnel_revenue

--10. Which traffic source generates the most revenue and highest AOV?

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
ORDER BY total_revenue DESC

--11. How do revenue KPIs trend week over week?

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
ORDER BY week_start

--12. What share of users who added to cart ultimately purchased? (cart abandonment)

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
FROM cart_users
