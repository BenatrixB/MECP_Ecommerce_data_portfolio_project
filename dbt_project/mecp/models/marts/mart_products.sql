/*
MODEL - mart_products 

Stulpelis              | Šaltinis           | Aprašymas
-----------------------|--------------------|---------------------------
product_id             | int_order_items    | PK (kartu su mėnesiu)
product_name           | int_products       | Produkto pavadinimas
order_year             | calculated         | EXTRACT(year FROM created_at)
order_month            | calculated         | EXTRACT(month FROM created_at)
total_revenue          | calculated         | SUM(price_usd)
total_cogs             | calculated         | SUM(cogs_usd)
gross_margin_usd       | calculated         | total_revenue - total_cogs
gross_margin_pct       | calculated         | gross_margin_usd / total_revenue
units_sold             | calculated         | COUNT(order_item_id)
total_refund_amt       | int_order_item_refunds | SUM(refund_amt_usd)
refund_count           | calculated         | COUNT(refund_id)
refund_rate_pct        | calculated         | refund_count / units_sold
net_revenue            | calculated         | total_revenue - total_refund_amt
*/

-- IMPORTED TABLE SCHEMAS:
-- int_products view schema: product_id, created_at, product_name
-- int_order_items schema: order_item_id, created_at, order_id, product_id, is_primary_item, price_usd, cogs_usd
-- int_order_item_refunds schema: order_item_refund_id, created_at, order_item_id, order_id, refund_amt_usd

-- IMPORTED MODEL SELECTION
WITH order_items AS(
    SELECT
        *
    FROM
        {{ref('int_order_items')}}
),
products AS(
    SELECT
        product_id AS p_product_id,
        product_name
    FROM
        {{ref('int_products')}}
),
refunds AS(
    SELECT
        *
    FROM
        {{ref('int_order_item_refunds')}}
),
-- DERIVED COLUMN LOGIC
-- Order_items source
order_items_timeline_sum AS(
    SELECT
        product_id,
        EXTRACT(year FROM created_at) AS order_year,
        EXTRACT(month FROM created_at) AS order_month,
        SUM(price_usd) AS total_revenue,
        SUM(cogs_usd) AS total_cogs,
        COUNT(order_item_id)AS units_sold
    FROM
        order_items 
    GROUP BY
        product_id,
        EXTRACT(year FROM created_at),
        EXTRACT(month FROM created_at)
),
gross_margin_usd AS(
    SELECT
        *,
        total_revenue - total_cogs AS gross_margin_usd
    FROM
        order_items_timeline_sum
),
gross_margin_pct AS(
    SELECT
        *,
        gross_margin_usd / total_revenue AS gross_margin_pct
    FROM
        gross_margin_usd
),
-- Refund source
refund_with_product AS(
    SELECT
        oi.product_id,
        EXTRACT(year FROM r.created_at) AS ref_order_year,
        EXTRACT(month FROM r.created_at) AS ref_order_month,
        r.refund_amt_usd,
        r.order_item_refund_id
    FROM
        refunds AS r
    LEFT JOIN
        order_items AS oi
    ON r.order_item_id = oi.order_item_id
),
refund_sum AS(
    SELECT
        product_id AS ref_product_id,
        ref_order_year,
        ref_order_month,
        SUM(refund_amt_usd) AS total_refund_amt,
        COUNT(order_item_refund_id) AS refund_count
    FROM
        refund_with_product
    GROUP BY
        product_id,
        ref_order_year,
        ref_order_month
),
joined_df AS(
    SELECT
        *,
        COALESCE(rs.refund_count, 0) / oi.units_sold AS refund_rate_pct,
        oi.total_revenue - rs.total_refund_amt AS net_revenue
    FROM
        gross_margin_pct AS oi
    LEFT JOIN refund_sum AS rs
        ON oi.product_id = rs.ref_product_id
        AND oi.order_year = rs.ref_order_year
        AND oi.order_month = rs.ref_order_month
    LEFT JOIN
        products as p
    ON oi.product_id = p.p_product_id
),
-- FINAL DATAFRAME SCHEMA
final_df AS(
    SELECT
        product_id,
        product_name,
        order_year,
        order_month,
        total_revenue,
        total_cogs,
        gross_margin_usd,
        gross_margin_pct,
        units_sold,
        total_refund_amt,
        refund_count,
        refund_rate_pct,
        net_revenue
    FROM
        joined_df
)
SELECT
    *
FROM
    final_df