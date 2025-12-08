{{ config(
    materialized='table'
) }}

with raw as (
    select
        timestamp,
        platform,
        content,
        sentiment
    from {{ ref('social_media') }}
),

cleaned as (
    select
        --md5(concat(cast(timestamp as varchar), '||', lower(trim(platform)), '||', content)) as social_id,
        cast(timestamp as timestamp_ntz) as event_ts,
        lower(trim(platform)) as platform_normalized,
        trim(content) as content_clean,
        lower(trim(sentiment)) as sentiment_raw
    from raw
),

standardized as (
    select
        social_id,
        event_ts,
        platform_normalized,
        content_clean,
        case
            when sentiment_raw in ('positive','pos','+','1') then 'positive'
            when sentiment_raw in ('negative','neg','-','-1') then 'negative'
            when sentiment_raw in ('neutral','neu','0') then 'neutral'
            else null
        end as sentiment
    from cleaned
)

select * from standardized
