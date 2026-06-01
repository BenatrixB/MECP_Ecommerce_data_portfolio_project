WITH source AS(
    SELECT
        *
    FROM
        {{ref('stg_order_items')}}
)
SELECT
    *
FROM
    source