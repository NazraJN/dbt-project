{% snapshot customers_data_snapshot %}

{{
    config(
        target_schema='DEV',
        unique_key='CustomerID',
        strategy='check',
        check_cols=['CustomerName', 'Email', 'Location']
    )
}}

select
    CustomerID,
    CustomerName,
    Email,
    Location,
    SignupDate
from {{ ref('customers') }}

{% endsnapshot %}
