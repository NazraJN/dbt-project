With raw_productmodel as (
    select
        *
    from {{ source('adv','productmodel') }}
)
select
   *
from raw_productmodel