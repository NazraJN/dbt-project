With raw_salesorderheader as (
    select
        *
    from {{ source('adv','salesorderheader') }}
)
select
   *

from raw_salesorderheader