{% snapshot products_snapshot %}

{{
    config(
        target_schema='DEV',
        unique_key='ProductID',
        strategy='check',
        check_cols=['ProductName', 'Category', 'UnitPrice']
    )
}}

select
    ProductID,
    ProductName,
    Category,
    Stock,
    UnitPrice
from {{ ref('products') }}

{% endsnapshot %}
