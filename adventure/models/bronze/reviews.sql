With raw_reviews as (
    select
        *
    from {{ source('adv','reviews') }}
)
select
   *

from raw_reviews