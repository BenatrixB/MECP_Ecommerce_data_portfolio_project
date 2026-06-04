/*
mart_funnel — viena eilutė per sesiją

Stulpelis              | Šaltinis                  | Aprašymas
-----------------------|---------------------------|---------------------------
session_id             | int_website_sessions      | PK
created_at             | int_website_sessions      | Sesijos data
device_type            | int_website_sessions      | desktop / mobile
utm_source             | int_website_sessions      | Acquisition channel
lander_variant         | int_website_pageviews     | /home, /lander-1..5 (pirmas pageview)
reached_landing        | int_website_pageviews     | 1 jei aplankė landing page
reached_products       | int_website_pageviews     | 1 jei aplankė /products
reached_product_page   | int_website_pageviews     | 1 jei aplankė produkto puslapį
reached_cart           | int_website_pageviews     | 1 jei aplankė /cart
reached_shipping       | int_website_pageviews     | 1 jei aplankė /shipping
reached_billing        | int_website_pageviews     | 1 jei aplankė /billing arba /billing-2
reached_thankyou       | int_website_pageviews     | 1 jei aplankė /thank-you-for-your-order
billing_variant        | int_website_pageviews     | /billing arba /billing-2
is_conversion          | int_orders                | 1 jei yra order šiai sesijai
session_year           | calculated                | EXTRACT(year FROM created_at)
session_month          | calculated                | EXTRACT(month FROM created_at)

IMPORTED VIEW SCHEMAS:
int_website_sessions: website_session_id, created_at, user_id, is_repeat_session, utm_source, utm_campaign, utm_content, device_type, http_referer
int_website_pageviews: website_pageview_id, created_at, website_session_id, pageview_url
int_orders: order_id, created_at, website_session_id, user_id, primary_product_id, items_purchased, price_usd, cogs_usd
*/

-- IMPORTED VIEWS SELECTION
WITH web_sessions AS(
    SELECT
        *
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
        website_session_id,
        order_id,
        price_usd
    FROM
        {{ ref('int_orders') }}
),
-- DERIVED LOGIC
sessions_df AS (
    SELECT
        website_session_id,
        created_at AS session_date,
        device_type,
        utm_source AS acquisition_channel
    FROM
        web_sessions
),
lander AS(
    SELECT
        website_session_id,
        pageview_url AS lander_variant
    FROM(
        SELECT
            website_session_id,
            pageview_url,
            ROW_NUMBER() OVER(
                PARTITION BY website_session_id
                ORDER BY created_at ASC
            ) AS rn
        FROM web_pageviews
    ) p
    WHERE rn = 1
),
session_flags AS(
    SELECT
        website_session_id,
        MAX(CASE WHEN pageview_url IN ('/home', '/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5') THEN 1 ELSE 0 END) AS reached_landing,
        MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END) AS reached_products,
        MAX(CASE WHEN pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear', '/the-birthday-sugar-panda', '/the-hudson-river-mini-bear') THEN 1 ELSE 0 END) AS reached_product_page,
        MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS reached_cart,
        MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS reached_shipping,
        MAX(CASE WHEN pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END) AS reached_billing,
        MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS reached_thankyou,
        MAX(CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END) AS billing_variant
    FROM web_pageviews
    GROUP BY website_session_id
),
joined_df AS(
    SELECT
        sd.*,
        l.lander_variant,
        sf.reached_landing,
        sf.reached_products,
        sf.reached_product_page,
        sf.reached_cart,
        sf.reached_shipping,
        sf.reached_billing,
        sf.reached_thankyou,
        sf.billing_variant,
        CASE
            WHEN o.order_id IS NOT NULL THEN 1
            ELSE 0
        END AS is_conversion,
        EXTRACT(year FROM session_date) AS session_year,
        EXTRACT(month FROM session_date) AS session_month
    FROM
        sessions_df AS sd
    LEFT JOIN
        lander AS l
    ON
        sd.website_session_id = l.website_session_id
    LEFT JOIN
        session_flags AS sf
    ON
        sd.website_session_id = sf.website_session_id
    LEFT JOIN 
        orders AS o
    ON
        sd.website_session_id = o.website_session_id
),
-- FINAL DATAFRAME STRUCTURE
final_df AS(
    SELECT
        website_session_id,
        session_date,
        device_type,
        acquisition_channel,
        lander_variant,
        reached_landing,
        reached_products,
        reached_product_page,
        reached_cart,
        reached_shipping,
        reached_billing,
        reached_thankyou,
        billing_variant,
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