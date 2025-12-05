With raw_products as (
    select
        *
    from {{ source('adv','products_data') }}
)
select
   *

from raw_products