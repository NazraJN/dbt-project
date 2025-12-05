{{
    config(
        materialized='table'
    )
}}

select
    platform_normalized as Platform,
    sentiment as Sentiment,
    count(*) as Sentiment_count
from {{ ref('fact_social_media_enriched') }}
group by platform_normalized, sentiment
