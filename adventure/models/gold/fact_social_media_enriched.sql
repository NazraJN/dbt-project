{{ config(
    materialized='incremental',
    unique_key='social_id'
) }}

with base as (
    select *
    from {{ ref('fact_social_media') }}
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
        end as sentiment_score,

        -- simple product-pattern detection 
        regexp_substr(content_clean, '([A-Z0-9]{2,}-[A-Z0-9]{2,})', 1, 1, 'i') as detected_product,

        -- boolean flag for urls
        case when lower(content_clean) like '%http%' or lower(content_clean) like '%www.%' then true else false end as has_url,

        -- approximate word count
        case
            when trim(content_clean) = '' then 0
            else length(trim(content_clean)) - length(replace(trim(content_clean), ' ', '')) + 1
        end as word_count
    from base
)

select * from enriched

{% if is_incremental() %}
where social_id not in (select social_id from {{ this }})
{% endif %}
