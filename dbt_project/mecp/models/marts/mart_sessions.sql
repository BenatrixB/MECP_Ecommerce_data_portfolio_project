/* 
EXPECTED MODEL: mart_sessions 
EXPECTED MODEL SCHEMA:

Stulpelis              | Šaltinis           | Aprašymas
-----------------------|--------------------|---------------------------
website_session_id     | int_sessions       | PK
created_at             | int_sessions       | Sesijos data
user_id                | int_sessions       | Vartotojas
is_repeat_session      | int_sessions       | Repeat session flag
utm_source             | int_sessions       | Acquisition channel
utm_campaign           | int_sessions       | Acquisition campaign
device_type            | int_sessions       | Device tipas
order_id               | int_orders         | NULL jei nepirko
price_usd              | int_orders         | NULL jei nepirko
is_conversion          | calculated         | 1 jei yra order, 0 jei ne
session_year           | calculated         | EXTRACT(year FROM created_at)
session_month          | calculated         | EXTRACT(month FROM created_at)

IMPORTED TABLE SCHEMAS:
int_website_sessions schema: website_session_id, created_at, user_id, is_repeat_session, utm_source, utm_campaign, utm_content, device_type, http_referer
int_orders schema: order_id, created_at, website_session_id, user_id, primary_product_id, items_purchased, price_usd, cogs_usd
*/
-- IMPORTED MODELS
WITH web_sessions AS(
    SELECT
        *
    FROM
        {{ref('int_website_sessions')}}
),
orders AS(
    SELECT
        *
    FROM
        {{ref('int_orders')}}
),
-- COLUMN/TRANSFORMATION LOGIC
joined_df AS(
    SELECT
    ws.*,
    o.order_id,
    o.price_usd,
    CASE 
        WHEN order_id IS NOT NULL THEN  1
        ELSE  0
    END AS is_conversion,
    EXTRACT(year FROM ws.created_at) AS session_year,
    EXTRACT(month FROM ws.created_at) AS session_month
    FROM
        web_sessions AS ws
    LEFT JOIN
        orders AS o
    ON
        ws.website_session_id = o.website_session_id
),
final_df AS(
    SELECT
        website_session_id AS session_id,
        created_at,
        user_id,
        is_repeat_session,
        utm_source AS acquisition_channel,
        utm_campaign AS acquisition_campaign,
        device_type,
        order_id,
        price_usd,
        is_conversion,
        session_year,
        session_month
    FROM
        joined_df
)
SELECT
    *
FROM
    final_df