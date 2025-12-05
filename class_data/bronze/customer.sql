With raw_customers as (
    select
        *
    from {{ source('adv','customer') }}
)
select
   *

from raw_customers