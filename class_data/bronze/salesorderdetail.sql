With raw_salesorderdetail as (
    select
        *
    from {{ source('adv','salesorderdetail') }}
)
select
   *

from raw_salesorderdetail