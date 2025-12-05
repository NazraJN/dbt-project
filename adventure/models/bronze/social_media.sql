With raw_social_media as (
    select
        *
    from {{ source('adv','social_media') }}
)
select
   *

from raw_social_media