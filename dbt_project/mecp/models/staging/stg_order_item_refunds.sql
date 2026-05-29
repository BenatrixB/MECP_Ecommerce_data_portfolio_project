-- stg_order_item_refunds refund fact view 
WITH source AS(
    SELECT
        *
    FROM
        {{source('raw', 'order_item_refunds')}}
),
    stg_order_item_refunds_df AS(
    SELECT
        order_item_refund_id, -- PK
        created_at:: timestamp AS created_at,
        order_item_id, -- FK
        order_id, -- FK
        refund_amount_usd:: numeric(10, 2) AS refund_amt_usd
    FROM
            source
)
SELECT
    *
FROM
    stg_order_item_refunds_df