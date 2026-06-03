/*
Stulpelis            | Šaltinis                  | Aprašymas
---------------------|---------------------------|---------------------------
order_id             | stg_orders                | PK
created_at           | stg_orders                | Užsakymo data
user_id              | stg_orders                | Vartotojas
website_session_id   | stg_orders                | Sesija
primary_product_id   | stg_orders                | Pagrindinis produktas
items_purchased      | stg_orders                | Kiek items
price_usd            | stg_orders                | Bruto revenue
cogs_usd             | stg_orders                | Agregated COGS
gross_margin_usd     | calculated                | price_usd - cogs_usd
gross_margin_pct     | calculated                | gross_margin_usd / price_usd
refund_amt_usd       | stg_order_item_refunds    | Agregated refunds
net_revenue_usd      | calculated                | price_usd - refund_amt_usd
order_year           | calculated                | EXTRACT(year FROM created_at)
order_month          | calculated                | EXTRACT(month FROM created_at)
order_day_of_week    | calculated                | EXTRACT(dow FROM created_at)
*/


-- MODEL REF SELECT
WITH orders AS(
    SELECT
    *
    FROM
        {{ref('int_orders')}}
),
refunds AS(
    SELECT
    *
    FROM
    {{ref('int_order_item_refunds')}}
),

-- DERIVED COLUMN LOGIC
gross_margin AS(
    SELECT
    *,
    price_usd - cogs_usd AS gross_margin_usd
    FROM
        orders
),
gross_margin_pct AS(
    SELECT
    *,
    gross_margin_usd / price_usd AS gross_margin_pct
    FROM
        gross_margin
),
refund_amt AS(
    SELECT
        order_id AS ref_order_id,
        SUM(refund_amt_usd) AS refund_amt_usd
    FROM
        refunds
    GROUP BY
        order_id
),
net_revenue_usd AS(
    SELECT
        *,
        o.price_usd - COALESCE(r.refund_amt_usd, 0) AS net_revenue_usd
    FROM
        gross_margin_pct AS o
    LEFT JOIN refund_amt AS r
        ON o.order_id = r.ref_order_id
),
yoy_df AS(
    SELECT
        *,
        EXTRACT(year FROM created_at) AS order_year,
        EXTRACT(month FROM created_at) AS order_month,
        EXTRACT(dow FROM created_at) AS order_day_of_week
    FROM
        net_revenue_usd
),
final_df AS(
    SELECT
        order_id,
        created_at,
        user_id,
        website_session_id,
        primary_product_id,
        items_purchased,
        price_usd,
        cogs_usd,
        gross_margin_usd,
        gross_margin_pct,
        refund_amt_usd,
        net_revenue_usd,
        order_year,
        order_month,
        order_day_of_week
    FROM
    yoy_df   
)
SELECT
    *
FROM
    final_df