WITH source AS (
    SELECT
        *
    FROM
        {{ref('stg_products')}}
)
SELECT
    *
FROM
    source