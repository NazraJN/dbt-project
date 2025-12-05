with orders_base as (
    select
        OrderID,
        OrderDate,
        CustomerID,
        ProductID,
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
        dbt_valid_from,
        dbt_valid_to
    from {{ ref('customers_data_snapshot') }}
),

products_snapshot as (
    select
        ProductID,
        dbt_scd_id as product_sk,
        ProductName,
        Category,
        UnitPrice,
        dbt_valid_from,
        dbt_valid_to
    from {{ ref('products_snapshot') }}
),

final as (
    select
        o.OrderID,
        o.OrderDate,
        o.CustomerID,
        c.customer_sk,
        c.CustomerName,
        o.ProductID,
        p.product_sk,
        p.ProductName,
        p.Category,
        o.Quantity,
        o.TotalAmount,
        p.UnitPrice as product_price_at_order,
        o.PaymentMethod,
        c.dbt_valid_from as customer_valid_from,
        c.dbt_valid_to as customer_valid_to,
        p.dbt_valid_from as product_valid_from,
        p.dbt_valid_to as product_valid_to
    from orders_base o
    left join customers_snapshot c 
        on o.CustomerID = c.CustomerID
    left join products_snapshot p 
        on o.ProductID = p.ProductID
)

select * from final
