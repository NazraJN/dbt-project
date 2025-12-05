With raw_web_logs as (
    select
        *
    from {{ source('adv','weblogs') }}
)
select
   *

from raw_web_logs