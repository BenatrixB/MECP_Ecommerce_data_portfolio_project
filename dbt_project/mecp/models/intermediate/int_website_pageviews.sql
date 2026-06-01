WITH source AS(
    SELECT
        *
    FROM
        {{ref('stg_website_pageviews')}}
)
SELECT
    *
FROM
    source