{{ config(
    materialized='table'
) }}

with orders_base as (
    select
        OrderID as order_id,
        OrderDate as order_date,
        CustomerID as customer_id,
        ProductID as product_id,
        Quantity,
        TotalAmount,
        PaymentMethod
    from {{ ref('orders') }}
),

customers_snapshot as (
    select
        CustomerID,
        dbt_scd_id as customer_sk,
        CustomerName,
        Email,
        Location,
        SignupDate,
        dbt_valid_from,
        dbt_valid_to
    from {{ ref('customers_data_snapshot') }}
),

products_snapshot as (
    select
        ProductID,
        dbt_scd_id as product_sk,
        ProductName,
        UnitPrice,
        dbt_valid_from,
        dbt_valid_to
    from {{ ref('products_snapshot') }}
),

final as (
    select
        o.order_id,
        o.order_date,
        o.customer_id,
        c.customer_sk,
        c.CustomerName as customer_name,
        c.Email,
        c.Location,
        c.SignupDate,
        o.product_id,
        p.product_sk,
        p.ProductName as product_name,
        o.Quantity,
        o.TotalAmount,
        p.UnitPrice as product_price_at_order,
        o.PaymentMethod,
        year(o.order_date) as order_year,
        month(o.order_date) as order_month
    from orders_base o
    left join customers_snapshot c
        on o.customer_id = c.CustomerID
        and o.order_date >= c.dbt_valid_from
        and (c.dbt_valid_to is null or o.order_date < c.dbt_valid_to)
    left join products_snapshot p
        on o.product_id = p.ProductID
        and o.order_date >= p.dbt_valid_from
        and (p.dbt_valid_to is null or o.order_date < p.dbt_valid_to)
)

select * from final
