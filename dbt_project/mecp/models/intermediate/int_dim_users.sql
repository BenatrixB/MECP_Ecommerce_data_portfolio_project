/*
DATA STRUCTURE TO BE CREATED
user_id PK (INT) PK
-- Web session tbl
first_session_date (DATE) - from sessions rank by date or row num by date and take first one
acquisation_channel (STR) - ? first session channel utm_channel?
acquisation_device (STR) - from sessions first session's device_type
-- Orders tbl
first_order_date (DATE) from orders first order by rank or row num by created_at date
is_buyer (FLG/INT) user_id exists in sessions, but does not exist in orders (no buy 0, yes buy 1)
is_repeat_buyer (FLG/INT) user ordered  a few times, so user_id count in order's is >1 (Maybe with having)
total_orders(INT) count of orders or user_id_instances in orders table
total_revenue(FLOAT) (Total revenue from user) SUM all revenue of all orders of user_id
*/


WITH sessions AS (
    SELECT
        *
    FROM
        {{ ref('stg_website_sessions') }}
),
first_session AS (
    SELECT
        user_id,
        created_at AS first_session_date,
        utm_source AS acquisition_channel,
        utm_campaign AS acquisition_campaign,
        device_type AS acquisition_device
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY user_id
                ORDER BY created_at ASC
            ) AS rn
        FROM sessions
    ) s
    WHERE rn = 1
),
orders AS (
    SELECT
        *
    FROM
        {{ ref('stg_orders') }}
),
first_order AS (
    SELECT
        user_id,
        created_at AS first_order_date
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY user_id
                ORDER BY created_at ASC
            ) AS rn
        FROM orders
    ) o
    WHERE rn = 1
),
order_stats AS (
    SELECT
        user_id,
        COUNT(*) AS total_orders,
        SUM(price_usd) AS total_revenue,
        CASE WHEN COUNT(*) > 1 THEN 1 ELSE 0 END AS is_repeat_buyer
    FROM orders
    GROUP BY 
        user_id
)
SELECT
    fs.user_id,
    fs.first_session_date,
    fs.acquisition_channel,
    fs.acquisition_campaign,
    fs.acquisition_device,
    fo.first_order_date,
    CASE 
        WHEN fo.user_id IS NOT NULL THEN 1 
        ELSE 0 
    END AS is_buyer,
    COALESCE(os.is_repeat_buyer, 0) AS is_repeat_buyer,
    COALESCE(os.total_orders, 0) AS total_orders,
    COALESCE(os.total_revenue, 0) AS total_revenue
FROM first_session AS fs
LEFT JOIN 
    first_order AS fo 
    ON fs.user_id = fo.user_id
LEFT JOIN 
    order_stats AS os 
    ON fs.user_id = os.user_id
