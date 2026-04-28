
### 1. What events exist in the dataset and how active is each one?

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/1.png)

- 5 distinct event types confirm a clean 5-stage funnel. Page views are 6 times more frequent than purchases - expected for an e-commerce dataset of this scale.

### 2. What are the raw funnel stage volumes over the last 30 days?

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/2.png)

- Count distinct users who reached each stage (page view -> cart -> checkout -> payment -> purchase) in the rolling 30-day window.
- 4K visitors in 30 days narrows to 709 purchasers.

### 3. What is the conversion rate across the funnel?

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/3.png)

- View -> cart at 31% is the weakest step — nearly 2 in 3 visitors never add anything. Once in checkout, users convert well (72–74%). Product discovery & merchandising is the top priority.
### 4. Where is the biggest drop-off in the funnel?

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/4.png)

- View -> cart loses 2,953 users (69%) — more than the next three stages combined. This is the #1 optimisation opportunity.
### 5. Which traffic sources drive the most visitors, cart adds, and purchases?

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/5.png)

- Emails converts at 34% despite low volume — strongest purchase rate. Social media is weakest at 3%.
### 6. Which traffic source has the best overall purchase conversion rate?

![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/6.png)
### 7. How long does a converted user take to move from view to purchase?
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/7.png)
### 8. How does journey speed vary by traffic source for converted users?
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/8.png)
### 9. What is the total revenue, average order value, and revenue per visitor?
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/9.png)
### 10. Which traffic source generates the most revenue and highest AOV?
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/10.png)
### 11. How do revenue KPIs trend week over week?
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/11.png)
### 12. What share of users who added to cart ultimately purchased? (cart abandonment)
![imagge](https://github.com/amansuren/sales-funnel-analysis-using-SQL/blob/87d370d742d3faf134538b961edc87302add99b1/screenshots/12.png)
