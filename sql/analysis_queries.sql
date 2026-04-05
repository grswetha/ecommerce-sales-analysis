-- ============================================
-- E-Commerce Sales Analysis — SQL Queries
-- Dataset: Brazilian E-Commerce (Olist)
-- Author: Swetha G
-- ============================================

-- Query 1: Top 10 categories by revenue
SELECT 
    product_category_name_english AS category,
    COUNT(DISTINCT order_id)      AS total_orders,
    ROUND(SUM(price), 2)          AS total_revenue,
    ROUND(AVG(price), 2)          AS avg_order_value
FROM master_orders
WHERE product_category_name_english != 'unknown'
GROUP BY product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- -----------------------------------------------

-- Query 2: Monthly revenue and order trend
SELECT
    order_year_month,
    COUNT(DISTINCT order_id)   AS total_orders,
    ROUND(SUM(price), 2)       AS total_revenue,
    ROUND(AVG(price), 2)       AS avg_order_value
FROM master_orders
GROUP BY order_year_month
ORDER BY order_year_month;

-- -----------------------------------------------

-- Query 3: Revenue and delivery performance by state
SELECT
    customer_state                          AS state,
    COUNT(DISTINCT order_id)               AS total_orders,
    ROUND(SUM(price), 2)                   AS total_revenue,
    ROUND(AVG(price), 2)                   AS avg_order_value,
    ROUND(AVG(delivery_days), 1)           AS avg_delivery_days,
    ROUND(
        SUM(CASE WHEN delivered_on_time = 1 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 1
    )                                      AS on_time_pct
FROM master_orders
GROUP BY customer_state
ORDER BY total_revenue DESC
LIMIT 10;

-- -----------------------------------------------

-- Query 4: Delivery speed breakdown using CTE
WITH delivery_summary AS (
    SELECT
        order_id,
        delivery_days,
        delivered_on_time,
        CASE
            WHEN delivery_days <= 7  THEN 'Fast (0-7 days)'
            WHEN delivery_days <= 14 THEN 'Normal (8-14 days)'
            WHEN delivery_days <= 21 THEN 'Slow (15-21 days)'
            ELSE 'Very slow (21+ days)'
        END AS delivery_bucket
    FROM master_orders
    WHERE delivery_days IS NOT NULL
      AND delivery_days >= 0
)
SELECT
    delivery_bucket,
    COUNT(DISTINCT order_id)  AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1
    )                         AS pct_of_orders
FROM delivery_summary
GROUP BY delivery_bucket
ORDER BY MIN(delivery_days);

-- -----------------------------------------------

-- Query 5: Category revenue share (% of total)
WITH category_totals AS (
    SELECT
        product_category_name_english           AS category,
        ROUND(SUM(price), 2)                    AS category_revenue
    FROM master_orders
    WHERE product_category_name_english != 'unknown'
    GROUP BY product_category_name_english
),
grand_total AS (
    SELECT SUM(price) AS total FROM master_orders
)
SELECT
    c.category,
    c.category_revenue,
    ROUND(c.category_revenue * 100.0 / g.total, 2) AS revenue_share_pct
FROM category_totals c, grand_total g
ORDER BY c.category_revenue DESC
LIMIT 10;
