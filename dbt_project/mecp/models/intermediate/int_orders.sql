WITH source AS(
    SELECT
        *
    FROM
        {{ref( 'stg_orders')}}
)
SELECT
    *
FROM
    source