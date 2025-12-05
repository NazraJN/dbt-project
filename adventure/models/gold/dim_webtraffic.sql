{{
    config(
        materialized='table'
    )
}}

select
    user_id as Customer_id,
    page as Page,
    action as Action_taken,
    count(*) as Action_count
from {{ ref('weblogs') }}
group by user_id, page, action
