WITH source AS (
    SELECT
        *
    FROM
        {{ref('stg_order_item_refunds')}}
)
SELECT
    *
FROM
    source