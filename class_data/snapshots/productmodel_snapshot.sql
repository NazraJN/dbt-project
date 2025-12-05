{% snapshot productmodel_snapshot %}

{{
    config(
        target_schema='DEV',
    
        unique_key='ProductModelID',
        strategy='timestamp',
        updated_at='ModifiedDate'
    )
}}

select
    ProductModelID,
    Name as ModelName,
modifieddate
from {{ ref('productmodel') }}
where ProductModelID is not null

{% endsnapshot %}