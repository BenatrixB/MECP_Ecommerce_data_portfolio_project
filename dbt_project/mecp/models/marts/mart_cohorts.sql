/*
EXPECTED SCHEMA
mart_cohorts — viena eilutė per cohort mėnesį per subsequent mėnesį

Stulpelis              | Šaltinis              | Aprašymas
-----------------------|-----------------------|---------------------------
cohort_month           | mart_users            | Pirmojo pirkimo mėnuo (PK kartu su subsequent_month)
subsequent_month       | calculated            | Kiekvienas mėnuo po cohort_month
months_since_first     | calculated            | 0, 1, 2, 3... (cohort_month = 0)
cohort_size            | calculated            | Vartotojų skaičius šiame cohort'e
active_users           | calculated            | Kiek pirkė šiame subsequent_month
retention_rate_pct     | calculated            | active_users / cohort_size * 100
monthly_revenue        | int_orders            | SUM(price_usd) šiame cohort+mėnesyje
avg_revenue_per_user   | calculated            | monthly_revenue / active_users
*/

WITH cohort_users AS(
    SELECT
        user_id,
        cohort_month
    FROM
        {{ ref('mart_users') }}
    WHERE is_buyer = 1
),
orders AS(
    SELECT
        user_id,
        created_at,
        price_usd
    FROM
        {{ ref('int_orders') }}
),
user_orders AS(
    SELECT
        cu.user_id,
        cu.cohort_month,
        DATE_TRUNC('month', o.created_at)::date AS order_month,
        o.price_usd
    FROM
        cohort_users AS cu
    LEFT JOIN
        orders AS o
    ON cu.user_id = o.user_id
),
months_diff AS(
    SELECT
        *,
        EXTRACT(year FROM AGE(order_month, cohort_month)) * 12 +
        EXTRACT(month FROM AGE(order_month, cohort_month)) AS months_since_first
    FROM
        user_orders
),
cohort_sizes AS(
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM
        cohort_users
    GROUP BY
        cohort_month
),
cohort_activity AS(
    SELECT
        cohort_month,
        order_month AS subsequent_month,
        months_since_first,
        COUNT(DISTINCT user_id) AS active_users,
        SUM(price_usd) AS monthly_revenue
    FROM
        months_diff
    WHERE order_month IS NOT NULL
    GROUP BY
        cohort_month,
        order_month,
        months_since_first
)
SELECT
    ca.cohort_month,
    ca.subsequent_month,
    ca.months_since_first::int,
    cs.cohort_size,
    ca.active_users,
    ROUND(ca.active_users::numeric / cs.cohort_size * 100, 2) AS retention_rate_pct,
    ca.monthly_revenue,
    ROUND(ca.monthly_revenue / ca.active_users, 2) AS avg_revenue_per_user
FROM
    cohort_activity AS ca
LEFT JOIN
    cohort_sizes AS cs
ON ca.cohort_month = cs.cohort_month
ORDER BY
    ca.cohort_month,
    ca.months_since_first