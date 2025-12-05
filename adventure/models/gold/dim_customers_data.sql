with customers_snapshot as (
    select
        dbt_scd_id as customer_sk,
        CustomerID,
        CustomerName,
        Email,
        Location,
        SignupDate,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then true else false end as is_current
    from {{ ref('customers_data_snapshot') }}
    where dbt_valid_to is null  
),

final as (
    select
        customer_sk,
        CustomerID,
        CustomerName,
        Email,
        Location,
        SignupDate,
        dbt_valid_from,
        dbt_valid_to,
        is_current
    from customers_snapshot
)

select * from final