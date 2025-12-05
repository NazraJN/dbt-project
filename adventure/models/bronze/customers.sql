With raw_customers as (
    select
        *
    from {{ source('adv','customers') }}
)
select
   *

from raw_customers