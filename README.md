# Customer Orders & Repeat Purchase Analysis

## Project overview
This SQL Server project analyzes customer order behavior, repeat purchases, delivered revenue, city and acquisition-channel performance, product-category performance, and the time between purchases.

**Dataset disclaimer:** The included dataset is synthetic and intended for practice and portfolio demonstration. It is not real company or customer data.

## Business problem
An e-commerce business wants to understand repeat purchasing and customer value. The analysis uses SQL to answer:
- How many customers have completed delivered orders?
- What share of purchasing customers make more than one delivered purchase?
- How much delivered revenue comes from repeat customers?
- Which cities and acquisition channels perform best?
- Which product categories contribute the most delivered revenue?
- How many days typically pass between delivered purchases?
- Which customers contribute the most delivered revenue?

## Dataset
- `customers.csv` — 600 customer records.
- `orders.csv` — 2,400 order records.

### Main fields
**customers.csv:** `customer_id`, `customer_name`, `city`, `signup_date`, `acquisition_channel`

**orders.csv:** `order_id`, `customer_id`, `order_date`, `product_category`, `product_name`, `quantity`, `unit_price`, `discount_pct`, `total_amount`, `order_status`, `payment_method`

## Tools
- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- SQL: joins, CTEs, aggregate functions, CASE expressions, HAVING, subqueries, `LAG()`, `RANK()`, date calculations

## Business rule
For completed-purchase and revenue analysis, only rows where `order_status = 'Delivered'` are included. Cancelled, returned, and processing orders are excluded from delivered revenue. The script also includes a separate status breakdown.

## Repository files
- `customers.csv` — customer data
- `orders.csv` — order data
- `customer_repeat_purchase_analysis.sql` — data quality checks and analytical queries
- `README.md` — project documentation

## How to run
1. Create a SQL Server database named `CustomerAnalyticsDB`.
2. Import `customers.csv` into `dbo.customers` and `orders.csv` into `dbo.orders`.
3. Open `customer_repeat_purchase_analysis.sql` in SSMS.
4. Execute the script in sections and inspect each result set.
5. Record verified findings and business recommendations before publishing your final conclusions.

The CSV files are expected to be imported into tables with the column names used in the SQL script. A sample table schema is available in the project's setup instructions from the project guide.

## Suggested business recommendations
Base recommendations on the results you verify:
- Test targeted re-engagement campaigns for one-time purchasers.
- Compare repeat-purchase rates across acquisition channels before reallocating marketing spend.
- Use purchase-gap analysis to inform the timing of reminders or replenishment campaigns.
- Investigate city and category differences before setting local promotions.
- Protect high-value customer relationships with relevant loyalty experiments.

These are hypotheses to evaluate, not claims that an intervention has already improved performance.

## Portfolio note
Add a concise summary of verified findings after running the queries. Do not invent results or imply that synthetic data came from a real employer.
