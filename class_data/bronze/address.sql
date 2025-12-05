With raw_address as (
    select
        *
    from {{ source('adv','address') }}
)
select * from raw_address
