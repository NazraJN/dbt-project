{{
    config(
        materialized='table'
    )
}}

select
    product_id as Product_id,
    round(avg(rating), 2) as avg_rating,
    count(*) as Total_reviews,
    listagg(distinct review_text, ' | ') within group (order by review_text) as Review_text
from {{ ref('reviews') }}
group by product_id
