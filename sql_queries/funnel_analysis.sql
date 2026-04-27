SELECT * FROM `sql-project-487019.funnel_data_01.user_events` LIMIT 100

SELECT 
  event_type,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users,
  MIN(event_date) AS earliest,
  MAX(event_date) AS latest
FROM `sql-project-487019.funnel_data_01.user_events`
GROUP BY event_type

-- define sales funnel and the different stages
WITH
  max_event_date_cte AS (
    SELECT MAX(event_date) AS latest_event_date
    FROM `sql-project-487019.funnel_data_01.user_events`
  ),
  funnel_stages AS (
    SELECT
      COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END)
        AS stage_1_views,
      COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END)
        AS stage_2_cart,
      COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END)
        AS stage_3_checkout,
      COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END)
        AS stage_4_payment,
      COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END)
        AS stage_5_purchase
    FROM `sql-project-487019.funnel_data_01.user_events`, max_event_date_cte
    WHERE
      event_date >= TIMESTAMP(
        DATE_SUB(DATE(max_event_date_cte.latest_event_date), INTERVAL 30 DAY))
  )
SELECT * FROM funnel_stages


-- Calculating conversion rates throughout sales funnel
WITH funnel_stages AS (
  
  SELECT 

    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase

  FROM `sql-project-487019.funnel_data_01.user_events`
  
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))

)
SELECT 

  stage_1_views,
  
  stage_2_cart,
  ROUND(stage_2_cart * 100 / stage_1_views ) AS view_to_cart_rate,

  stage_3_checkout,
  ROUND(stage_3_checkout * 100 / stage_2_cart ) AS cart_to_checkout_rate,

  stage_4_payment,
  ROUND(stage_4_payment * 100 / stage_3_checkout) AS checkout_to_payment_rate,
  
  stage_5_purchase,
  ROUND(stage_5_purchase * 100 / stage_4_payment) AS payment_to_purchase_rate,

  ROUND(stage_5_purchase * 100 / stage_1_views ) AS overall_conversion_rate

FROM funnel_stages
 


-- types of traffic source
SELECT distinct traffic_source FROM `sql-project-487019.funnel_data_01.user_events` LIMIT 100 --sources of traffic

-- Analysing the funnel by traffic source

WITH source_funnel AS (
  
  SELECT
    traffic_source,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases
  
  FROM `sql-project-487019.funnel_data_01.user_events`
  
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY traffic_source

)
SELECT
  traffic_source,
  views,
  carts,
  purchases,
  ROUND(carts * 100 / views ) AS cart_conversion_rate,
  ROUND(purchases * 100 / views ) AS purchase_conversion_rate,
  ROUND(purchases * 100 / carts ) AS cart_to_purchase_conversion_rate
FROM source_funnel
ORDER BY purchases DESC 




-- Time to conversion in different stages of funnel

WITH user_journey AS (
  SELECT
    user_id,
    MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS view_time,
    MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
    MIN(CASE WHEN event_type = 'purchase' THEN event_date END) AS purchase_time
  
  FROM `sql-project-487019.funnel_data_01.user_events`
  
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
  GROUP BY user_id
  HAVING MIN (CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)

SELECT
  COUNT(*) as converted_users,
  ROUND(AVG(timestamp_diff(cart_time, view_time, MINUTE)),2) AS avg_view_to_cart_minutes,
  ROUND(AVG(timestamp_diff(purchase_time, cart_time, MINUTE)),2) AS avg_cart_to_purchase_minutes,
  ROUND(AVG(timestamp_diff(purchase_time, view_time, MINUTE)),2) AS avg_total_journey_minutes

FROM user_journey

-- Revenue funnel analysis

WITH funnel_revenue AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyers,
    SUM(CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS total_orders

  FROM `sql-project-487019.funnel_data_01.user_events`
  
  WHERE event_date >= TIMESTAMP(DATE_SUB('2026-02-03', INTERVAL 30 DAY))
)

SELECT 
  total_visitors,
  total_buyers,
  total_orders,
  ROUND(total_revenue,2) AS total_revenue,
  ROUND(total_revenue / total_orders, 2) AS avg_order_value,
  ROUND(total_revenue / total_buyers, 2) AS revenue_per_buyer,
  ROUND(total_revenue / total_visitors, 2) AS revenue_per_visitor

FROM funnel_revenue




