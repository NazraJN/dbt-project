With raw_orders as (
    select
        *
    from {{ source('adv','orders') }}
)
select * from raw_orders