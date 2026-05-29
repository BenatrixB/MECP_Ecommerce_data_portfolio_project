-- stg_website_pageviews page views fact view connected to sessions
WITH source AS(
    SELECT
        *
    FROM
        {{source('raw', 'website_pageviews')}}
),
stg_website_pageviews_df AS(
    SELECT
        website_pageview_id, -- PK
        created_at:: timestamp AS created_at,
        website_session_id, -- FK
        pageview_url
    FROM
        source
)
SELECT
    *
FROM
    stg_website_pageviews_df