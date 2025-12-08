{{ config(
    materialized='incremental',
    unique_key='social_id'
) }}

with base as (
    select *
    from {{ ref('dim_social_media') }}
),

enriched as (
    select
        social_id,
        event_ts,
        platform_normalized,
        content_clean,
        sentiment,

        -- simple numeric sentiment score
        case
            when sentiment = 'positive' then 1
            when sentiment = 'negative' then -1
            when sentiment = 'neutral' then 0
            else null
        end as sentiment_score
    from base
)

select * from enriched

{% if is_incremental() %}
where social_id not in (select social_id from {{ this }})
{% endif %}
