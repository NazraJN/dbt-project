with reviews_base as (
    select
        *,
        row_number() over (
            order by timestamp, customer_id, product_id
        ) as review_id
    from {{ ref('reviews') }}
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
        dbt_valid_from,
        dbt_valid_to
    from {{ ref('products_snapshot') }}
),

final as (
    select
        r.review_id,
        r.timestamp,
        r.customer_id,
        c.customer_sk,
        c.CustomerName,
        r.product_id,
        p.product_sk,
        p.ProductName,
        r.rating,
        r.review_text
    from reviews_base r
    left join customers_snapshot c 
        on r.customer_id = c.CustomerID
        and r.timestamp >= c.dbt_valid_from
        and (c.dbt_valid_to is null or r.timestamp < c.dbt_valid_to)
    left join products_snapshot p 
        on r.product_id = p.ProductID
        and r.timestamp >= p.dbt_valid_from
        and (p.dbt_valid_to is null or r.timestamp < p.dbt_valid_to)
)

select * from final
