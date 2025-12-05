With raw_product as (
    select
        *
    from {{ source('adv','product') }}
)
select
   *

from raw_product
