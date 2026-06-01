WITH source AS(
    SELECT
        *
    FROM
        {{ref('stg_website_sessions')}}
)
SELECT
    *
FROM
    source