with products_snapshot as (
    select
        dbt_scd_id as product_sk,
        ProductID,
        ProductName,
        Category,
        Stock,
        UnitPrice,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then true else false end as is_current
    from {{ ref('products_snapshot') }}
    where dbt_valid_to is null 
),

final as (
    select
        product_sk,
        ProductID,
        ProductName,
        Category,
        Stock,
        UnitPrice,
        dbt_valid_from,
        dbt_valid_to,
        is_current
    from products_snapshot
)

select * from final
