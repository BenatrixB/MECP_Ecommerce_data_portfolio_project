-- stg_website_sessions fact view connected to page views
WITH source AS(
    SELECT
        *
    FROM
        {{source('raw', 'website_sessions')}}
),
stg_website_sessions_df AS (
    SELECT
        website_session_id, -- PK
        created_at:: timestamp AS created_at,
        user_id, -- FK
        is_repeat_session,
        utm_source, 
        utm_campaign, -- campaing info
        utm_content,
        device_type, -- what kind of device used
        http_referer
    FROM
        source
)
SELECT
    *
FROM
    stg_website_sessions_df