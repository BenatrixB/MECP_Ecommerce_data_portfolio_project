WITH source AS (
    SELECT
        *
    FROM
        {{source('raw', 'orders') }}
),
stg_orders AS(
    SELECT
        order_id,
        created_at::timestamp as created_at,
        website_session_id,
        user_id,
        primary_product_id,
        items_purchased,
        price_usd:: numeric(10, 2) as price_usd,
        cogs_usd:: numeric(10, 2) as cogs_usd
    FROM
        source
)
SELECT
    *
FROM
    stg_orders