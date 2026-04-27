# 📊 E-commerce Sales Funnel Analysis Project


### Project Overview
  
This project analyzes user behavior data to understand how customers move through different stages of a sales funnel — from product view to purchase.
Using **event-level transactional data**, the project identifies conversion rates, drop-off points, and revenue insights to support data-driven business decisions.

The goal of this project is to:

* Understand customer journey behavior
* Measure stage-wise conversion rates
* Identify drop-off points in the funnel
* Generate actionable business insights

### What's Covered
- Funnel stage volumes & conversion rates
- Drop-off analysis
- Traffic source performance
- Time-to-convert metrics
- Revenue KPIs (AOV, revenue per visitor)
- Weekly trends
- Cart abandonment rate
### Dataset information

Source: [user_events](dataset/user_events.csv)

Total Records: `9,381`

Table name: `user_events`

| Column Name    | Data Type | Description                                            |
| -------------- | --------- | ------------------------------------------------------ |
| event_id       | Integer   | Unique identifier for each event                       |
| user_id        | Integer   | Unique user identifier                                 |
| event_type     | Text      | Type of event (view, add_to_cart, purchase)            |
| event_date     | Date      | Date of user interaction                               |
| product_id     | Integer   | Product involved in the event                          |
| amount         | Float     | Revenue value (only for purchase events)               |
| traffic_source | Text      | Channel source (organic, paid, social, referral, etc.) |


