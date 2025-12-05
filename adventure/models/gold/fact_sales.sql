{{
    config(
        materialized='table'
    )
}}

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

reviews_base as (
    select
        product_id,
        customer_id,
        rating,
        review_text,
        timestamp as review_timestamp,
        row_number() over (
            order by timestamp, customer_id, product_id
        ) as review_id
    from {{ ref('reviews') }}
),

-- Generate date dimension on the fly
date_spine as (
    select
        OrderDate,
        row_number() over (order by OrderDate) as date_id,
        extract(YEAR from OrderDate) as order_year,
        quarter(OrderDate) as Quarter,
        month(OrderDate) as Order_month,
        day(OrderDate) as Order_day,
        to_char(OrderDate, 'Dy') as Day_abbr,
        dayofyear(OrderDate) as Day_of_the_year,
        weekofyear(OrderDate) as Week
    from orders_base
    group by OrderDate
),

customers_snapshot as (
    select
        CustomerID,
        dbt_scd_id as customer_sk,
        CustomerName,
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
        row_number() over (order by o.OrderID, o.ProductID) as sales_id,
        o.OrderID as Order_id,
        o.CustomerID as Customer_id,
        coalesce(d.date_id, 0) as Date_id,
        o.ProductID as Product_id,
        coalesce(r.review_id, 0) as Review_id,
        0 as Activity_id,  -- Placeholder for web activity linkage
        o.Quantity,
        o.TotalAmount as Total_amount,
        p.UnitPrice as Product_price,
        coalesce(avg(r.rating), 0) as Avg_product_rating,
        coalesce(avg(c_cust.rating), 0) as Avg_customer_rating,
        count(distinct o.OrderID) over (partition by o.CustomerID) as Customer_order_count,
        o.PaymentMethod,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from orders_base o
    left join date_spine d on o.OrderDate = d.OrderDate
    left join products_snapshot p on o.ProductID = p.ProductID
        and o.OrderDate >= p.dbt_valid_from
        and (p.dbt_valid_to is null or o.OrderDate < p.dbt_valid_to)
    left join customers_snapshot c on o.CustomerID = c.CustomerID
        and o.OrderDate >= c.dbt_valid_from
        and (c.dbt_valid_to is null or o.OrderDate < c.dbt_valid_to)
    left join reviews_base r on o.ProductID = r.product_id
        and o.CustomerID = r.customer_id
    left join reviews_base c_cust on o.CustomerID = c_cust.customer_id
    group by
        o.OrderID, o.ProductID, o.CustomerID, d.date_id, o.Quantity,
        o.TotalAmount, p.UnitPrice, r.review_id, c.customer_sk,
        o.PaymentMethod, p.ProductName, p.Category
)

select * from final
