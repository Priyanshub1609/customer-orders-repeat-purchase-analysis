/*
PROJECT 3: Customer Orders & Repeat Purchase Analysis
Platform: Microsoft SQL Server / SSMS
Dataset: Synthetic practice data

Business rule:
- Delivered orders are used for completed-purchase and revenue KPIs.
- Cancelled, Returned, and Processing orders are excluded from delivered revenue.
*/

USE CustomerAnalyticsDB;
GO

/* 0. DATA QUALITY CHECKS */
SELECT COUNT(*) AS total_customers FROM dbo.customers;
SELECT COUNT(*) AS total_orders FROM dbo.orders;

SELECT order_status, COUNT(*) AS order_count
FROM dbo.orders
GROUP BY order_status
ORDER BY order_count DESC;

-- Check duplicate customer IDs
SELECT customer_id, COUNT(*) AS occurrences
FROM dbo.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check duplicate order IDs
SELECT order_id, COUNT(*) AS occurrences
FROM dbo.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Orders whose customer ID is missing from the customer table
SELECT o.order_id, o.customer_id
FROM dbo.orders AS o
LEFT JOIN dbo.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


/* 1. OVERALL BUSINESS KPIs */
SELECT
    COUNT(DISTINCT order_id) AS total_orders_all_statuses,
    COUNT(DISTINCT CASE WHEN order_status = 'Delivered' THEN order_id END) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END) AS cancelled_orders,
    COUNT(DISTINCT CASE WHEN order_status = 'Returned' THEN order_id END) AS returned_orders,
    COUNT(DISTINCT CASE WHEN order_status = 'Processing' THEN order_id END) AS processing_orders
FROM dbo.orders;

SELECT
    COUNT(DISTINCT order_id) AS delivered_orders,
    COUNT(DISTINCT customer_id) AS customers_with_delivered_orders,
    SUM(total_amount) AS delivered_revenue,
    SUM(quantity) AS delivered_units,
    AVG(total_amount) AS average_delivered_order_value
FROM dbo.orders
WHERE order_status = 'Delivered';


/* 2. CUSTOMER ORDER FREQUENCY */
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS delivered_order_count,
        SUM(total_amount) AS delivered_revenue
    FROM dbo.orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN delivered_order_count = 1 THEN 'One-time customer'
        WHEN delivered_order_count > 1 THEN 'Repeat customer'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    SUM(delivered_revenue) AS segment_revenue,
    AVG(CAST(delivered_order_count AS DECIMAL(10,2))) AS avg_delivered_orders_per_customer
FROM customer_order_counts
GROUP BY
    CASE
        WHEN delivered_order_count = 1 THEN 'One-time customer'
        WHEN delivered_order_count > 1 THEN 'Repeat customer'
    END
ORDER BY customer_count DESC;

-- Repeat customer list
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.acquisition_channel,
    COUNT(DISTINCT o.order_id) AS delivered_order_count,
    SUM(o.total_amount) AS delivered_revenue
FROM dbo.customers AS c
JOIN dbo.orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name, c.city, c.acquisition_channel
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY delivered_order_count DESC, delivered_revenue DESC;


/* 3. REPEAT PURCHASE RATE AND REVENUE CONTRIBUTION */
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS delivered_order_count,
        SUM(total_amount) AS delivered_revenue
    FROM dbo.orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
customer_segments AS (
    SELECT
        customer_id,
        delivered_order_count,
        delivered_revenue,
        CASE WHEN delivered_order_count > 1 THEN 1 ELSE 0 END AS is_repeat_customer
    FROM customer_order_counts
),
totals AS (
    SELECT
        COUNT(*) AS customers_with_delivered_orders,
        SUM(is_repeat_customer) AS repeat_customers,
        SUM(delivered_revenue) AS total_delivered_revenue,
        SUM(CASE WHEN is_repeat_customer = 1 THEN delivered_revenue ELSE 0 END) AS repeat_customer_revenue
    FROM customer_segments
)
SELECT
    customers_with_delivered_orders,
    repeat_customers,
    CAST(100.0 * repeat_customers / NULLIF(customers_with_delivered_orders, 0) AS DECIMAL(6,2))
        AS repeat_customer_pct_of_customers_with_delivered_orders,
    total_delivered_revenue,
    repeat_customer_revenue,
    CAST(100.0 * repeat_customer_revenue / NULLIF(total_delivered_revenue, 0) AS DECIMAL(6,2))
        AS repeat_customer_revenue_pct
FROM totals;


/* 4. TOP CUSTOMERS BY DELIVERED REVENUE */
SELECT TOP 10
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id) AS delivered_order_count,
    SUM(o.total_amount) AS delivered_revenue
FROM dbo.customers AS c
JOIN dbo.orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY delivered_revenue DESC;


/* 5. CITY PERFORMANCE */
SELECT
    c.city,
    COUNT(DISTINCT c.customer_id) AS customers_with_delivered_orders,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(o.total_amount) AS delivered_revenue,
    CAST(AVG(o.total_amount) AS DECIMAL(12,2)) AS average_delivered_order_value
FROM dbo.customers AS c
JOIN dbo.orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.city
ORDER BY delivered_revenue DESC;


/* 6. ACQUISITION CHANNEL PERFORMANCE */
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS customers_with_delivered_orders,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(o.total_amount) AS delivered_revenue,
    CAST(
        100.0 * COUNT(DISTINCT CASE WHEN x.delivered_order_count > 1 THEN c.customer_id END)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
        AS DECIMAL(6,2)
    ) AS repeat_customer_pct
FROM dbo.customers AS c
JOIN dbo.orders AS o
    ON c.customer_id = o.customer_id
JOIN (
    SELECT customer_id, COUNT(DISTINCT order_id) AS delivered_order_count
    FROM dbo.orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) AS x
    ON c.customer_id = x.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.acquisition_channel
ORDER BY delivered_revenue DESC;


/* 7. CATEGORY PERFORMANCE FOR DELIVERED ORDERS */
SELECT
    product_category,
    COUNT(DISTINCT order_id) AS delivered_orders,
    SUM(quantity) AS units_sold,
    SUM(total_amount) AS delivered_revenue,
    CAST(AVG(total_amount) AS DECIMAL(12,2)) AS average_order_amount
FROM dbo.orders
WHERE order_status = 'Delivered'
GROUP BY product_category
ORDER BY delivered_revenue DESC;


/* 8. MONTHLY ORDER AND REVENUE TREND */
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    COUNT(DISTINCT order_id) AS delivered_orders,
    COUNT(DISTINCT customer_id) AS active_customers,
    SUM(total_amount) AS delivered_revenue
FROM dbo.orders
WHERE order_status = 'Delivered'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


/* 9. TIME BETWEEN PURCHASES FOR EACH CUSTOMER */
WITH delivered_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS previous_delivered_order_date
    FROM dbo.orders
    WHERE order_status = 'Delivered'
)
SELECT
    customer_id,
    order_id,
    previous_delivered_order_date,
    order_date AS current_order_date,
    DATEDIFF(DAY, previous_delivered_order_date, order_date) AS days_since_previous_order
FROM delivered_orders
WHERE previous_delivered_order_date IS NOT NULL
ORDER BY customer_id, order_date;


/* 10. AVERAGE DAYS BETWEEN DELIVERED ORDERS */
WITH delivered_orders AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS previous_order_date
    FROM dbo.orders
    WHERE order_status = 'Delivered'
),
purchase_gaps AS (
    SELECT DATEDIFF(DAY, previous_order_date, order_date) AS days_between_orders
    FROM delivered_orders
    WHERE previous_order_date IS NOT NULL
)
SELECT
    COUNT(*) AS repeat_purchase_intervals,
    CAST(AVG(CAST(days_between_orders AS DECIMAL(10,2))) AS DECIMAL(10,2))
        AS average_days_between_purchases,
    MIN(days_between_orders) AS minimum_days_between_purchases,
    MAX(days_between_orders) AS maximum_days_between_purchases
FROM purchase_gaps;


/* 11. CUSTOMER ORDER RANKING */
WITH customer_revenue AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS delivered_order_count,
        SUM(total_amount) AS delivered_revenue
    FROM dbo.orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    customer_id,
    delivered_order_count,
    delivered_revenue,
    RANK() OVER (ORDER BY delivered_revenue DESC) AS revenue_rank
FROM customer_revenue
ORDER BY revenue_rank;


/* 12. CUSTOMERS WITH NO DELIVERED ORDERS */
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.acquisition_channel
FROM dbo.customers AS c
LEFT JOIN dbo.orders AS o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Delivered'
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
