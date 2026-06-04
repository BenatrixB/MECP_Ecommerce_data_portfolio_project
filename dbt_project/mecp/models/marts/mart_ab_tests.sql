/*
EXPECTED SCHEMA

mart_ab_tests — viena eilutė per sesiją per variantą

Stulpelis              | Šaltinis                  | Aprašymas
-----------------------|---------------------------|---------------------------
session_id             | int_website_sessions      | PK
created_at             | int_website_sessions      | Sesijos data
device_type            | int_website_sessions      | desktop / mobile
utm_source             | int_website_sessions      | Acquisition channel
test_type              | calculated                | 'lander' arba 'billing'
variant                | int_website_pageviews     | /lander-1..5 arba /billing, /billing-2
is_conversion          | int_orders                | 1 jei yra order
revenue                | int_orders                | price_usd arba NULL
session_year           | calculated                | EXTRACT(year FROM created_at)
session_month          | calculated                | EXTRACT(month FROM created_at)
*/

-- IMPORTED MODELS
WITH web_sessions AS(
    SELECT
        website_session_id,
        created_at,
        device_type,
        utm_source
    FROM
        {{ref('int_website_sessions')}}
),
web_pageviews AS(
    SELECT
        *
    FROM
        {{ref('int_website_pageviews')}}
),
orders AS(
    SELECT
        *
    FROM
        {{ref('int_orders')}}
),
-- DERIVED LOGIC
test_type_variant AS(
    SELECT
        website_session_id,
        CASE 
            WHEN pageview_url IN('/billing', '/billing-2') THEN  'billing'
            WHEN pageview_url IN('/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5' ) THEN 'lander'
            ELSE NULL
        END AS test_type,
        pageview_url AS variant
    FROM
        web_pageviews
    WHERE
        pageview_url IN('/billing', '/billing-2', '/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5')
),
joined_df AS(
    SELECT
        ws.*,
        tv.test_type,
        tv.variant,
        CASE 
            WHEN o.order_id IS NOT NULL THEN 1
            ELSE 0
        END AS is_conversion,
        o.price_usd AS revenue
    FROM
        web_sessions AS ws
    INNER JOIN
        test_type_variant AS tv
    ON 
        ws.website_session_id = tv.website_session_id
    LEFT JOIN
        orders AS o
    ON
        ws.website_session_id = o.website_session_id 
),
-- FINAL MODEL DATAFRAME
final_df AS (
    SELECT
        website_session_id,
        created_at,
        device_type,
        utm_source,
        test_type,
        variant,
        is_conversion,
        revenue,
        EXTRACT(year FROM created_at) AS session_year,
        EXTRACT(month FROM created_at) AS session_month
    FROM
        joined_df
)
SELECT
 *
FROM
    final_df