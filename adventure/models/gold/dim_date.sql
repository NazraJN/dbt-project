{{
    config(
        materialized='table'
    )
}}

with orders_base as (
    select distinct OrderDate
    from {{ ref('orders') }}
)

select
    row_number() over (order by OrderDate) as date_id,
    OrderDate as Order_date,
    extract(YEAR from OrderDate) as order_year,
    quarter(OrderDate) as Quarter,
    month(OrderDate) as Order_month,
    day(OrderDate) as Order_day,
    to_char(OrderDate, 'Dy') as Day_abbr,
    dayofyear(OrderDate) as Day_of_the_year,
    weekofyear(OrderDate) as Week
from orders_base
order by OrderDate
