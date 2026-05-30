# Data Dictionary - user_events

- **Dataset:** [user_events.csv](dataset/user_events.csv) · **Platform:** BigQuery
- **Data:** Synthetic 30-day e-commerce events (Dec 2025 – Feb 2026)



## Columns

| Column | Type | Description |
|--------|------|-------------|
| `event_id` | INTEGER | Unique ID for each event row |
| `user_id` | INTEGER | Unique ID per user - one user has multiple events |
| `event_type` | STRING | Funnel stage (see reference below) |
| `event_date` | TIMESTAMP | UTC timestamp of the event |
| `product_id` | INTEGER | Product involved - all records use product `101` |
| `amount` | FLOAT | Order value in USD - **only populated on `purchase` events**, NULL otherwise |
| `traffic_source` | STRING | Marketing channel: `email`, `paid_ads`, `organic`, `social_media` |

---

## Funnel Stages (`event_type`)

| # | Value | Meaning |
|---|-------|---------|
| 1 | `page_view` | User viewed a product page |
| 2 | `add_to_cart` | User added item to cart |
| 3 | `checkout_start` | User began checkout |
| 4 | `payment_info` | User entered payment details |
| 5 | `purchase` | Order completed - `amount` populated here |

> A complete journey = 5 rows (one per stage). Drop-offs have fewer rows.
