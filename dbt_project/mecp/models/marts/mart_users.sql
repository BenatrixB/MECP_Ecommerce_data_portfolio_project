/* EXPECTED SCHEMA
mart_users — viena eilutė per vartotoją

Stulpelis              | Šaltinis              | Aprašymas
-----------------------|-----------------------|---------------------------
user_id                | int_dim_users         | PK
first_session_date     | int_dim_users         | Acquisition data
acquisition_channel    | int_dim_users         | utm_source
acquisition_campaign   | int_dim_users         | utm_campaign
acquisition_device     | int_dim_users         | device_type
first_order_date       | int_dim_users         | Pirmo pirkimo data
is_buyer               | int_dim_users         | 0/1
is_repeat_buyer        | int_dim_users         | 0/1
total_orders           | int_dim_users         | Užsakymų skaičius
total_revenue          | int_dim_users         | Bendra išlaida
recency_days           | calculated            | Dienų nuo paskutinio pirkimo
frequency              | int_dim_users         | = total_orders
monetary               | int_dim_users         | = total_revenue
rfm_recency_score      | calculated            | 1-5
rfm_frequency_score    | calculated            | 1-5
rfm_monetary_score     | calculated            | 1-5
customer_segment       | calculated            | Champion/Loyal/At Risk/Lost
cohort_month           | calculated            | DATE_TRUNC('month', first_order_date)
ltv                    | int_dim_users         | = total_revenue
*/

-- IMPORTED SELECTION
WITH dim_users AS(
    SELECT
        *
    FROM
        {{ ref('int_dim_users') }}
),
last_order AS(
    SELECT
        user_id,
        MAX(created_at)::date AS last_order_date
    FROM
        {{ ref('int_orders') }}
    GROUP BY
        user_id
),
user_metrics AS(
    SELECT
        u.*,
        DATE '2015-03-19' - lo.last_order_date AS recency_days
    FROM
        dim_users AS u
    LEFT JOIN
        last_order AS lo
    ON u.user_id = lo.user_id
),
rfm_scores AS(
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days ASC) AS rfm_recency_score,
        NTILE(5) OVER (ORDER BY total_orders ASC) AS rfm_frequency_score,
        NTILE(5) OVER (ORDER BY total_revenue ASC) AS rfm_monetary_score
    FROM
        user_metrics
    WHERE is_buyer = 1
),
segments AS(
    SELECT
        *,
        CASE
            WHEN rfm_recency_score >= 4 AND rfm_frequency_score >= 4 THEN 'Champion'
            WHEN rfm_recency_score >= 3 AND rfm_frequency_score >= 3 THEN 'Loyal'
            WHEN rfm_recency_score >= 3 AND rfm_frequency_score < 3 THEN 'Potential'
            WHEN rfm_recency_score < 3 AND rfm_frequency_score >= 3 THEN 'At Risk'
            ELSE 'Lost'
        END AS customer_segment
    FROM
        rfm_scores
),
non_buyers AS(
    SELECT
        *,
        NULL::int AS recency_days,
        NULL::int AS rfm_recency_score,
        NULL::int AS rfm_frequency_score,
        NULL::int AS rfm_monetary_score,
        'Non Buyer' AS customer_segment
    FROM
        user_metrics
    WHERE is_buyer = 0
),
combined AS(
    SELECT
        user_id,
        first_session_date,
        acquisition_channel,
        acquisition_campaign,
        acquisition_device,
        first_order_date,
        is_buyer,
        is_repeat_buyer,
        total_orders,
        total_revenue,
        recency_days,
        rfm_recency_score,
        rfm_frequency_score,
        rfm_monetary_score,
        customer_segment
    FROM segments

    UNION ALL

    SELECT
        user_id,
        first_session_date,
        acquisition_channel,
        acquisition_campaign,
        acquisition_device,
        first_order_date,
        is_buyer,
        is_repeat_buyer,
        total_orders,
        total_revenue,
        NULL::int AS recency_days,
        NULL::int AS rfm_recency_score,
        NULL::int AS rfm_frequency_score,
        NULL::int AS rfm_monetary_score,
        'Non Buyer' AS customer_segment
    FROM user_metrics
    WHERE is_buyer = 0
),
final_df AS(
SELECT
    user_id,
    first_session_date,
    acquisition_channel,
    acquisition_campaign,
    acquisition_device,
    first_order_date,
    is_buyer,
    is_repeat_buyer,
    total_orders AS frequency,
    total_revenue AS monetary,
    recency_days,
    rfm_recency_score,
    rfm_frequency_score,
    rfm_monetary_score,
    customer_segment,
    DATE_TRUNC('month', first_order_date)::date AS cohort_month,
    total_revenue AS ltv
FROM
    combined
)
SELECT
    *
FROM
    final_df