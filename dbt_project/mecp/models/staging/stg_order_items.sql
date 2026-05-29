-- stg_order_items inter-dimension view connects products to orders
WITH source AS (
    SELECT
        *
    FROM
        {{source('raw', 'order_items')}}
),
stg_order_items_df AS(
    SELECT
        order_item_id, -- PK
        created_at:: timestamp AS created_at,
        order_id, -- FK
        product_id, -- FK
        is_primary_item, -- Binary 1 or 0
        price_usd::numeric(10, 2) AS price_usd, 
        cogs_usd::numeric(10, 2) AS cogs_usd
    FROM
        {{source('raw', 'order_items')}}
)
SELECT
*
FROM
    stg_order_items_df