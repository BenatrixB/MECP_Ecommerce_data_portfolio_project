-- stg_products product information dimension view 
WITH source AS(
    SELECT
        *
    FROM
        {{source('raw', 'products')}}
),
stg_products_df AS(
    SELECT
        product_id, -- PK
        created_at::timestamp AS created_at,
        product_name
    FROM
        source
)
SELECT
    *
FROM
    stg_products_df