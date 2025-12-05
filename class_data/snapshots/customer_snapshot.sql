{% snapshot customers_snapshot %}

{{
    config(
        target_schema='DEV',
       
        unique_key='CustomerID',
        strategy='timestamp',
        updated_at='ModifiedDate'
    )
}}

select
    CustomerID,
    AddressID,
    StoreID,
    TerritoryID,
    AccountNumber,
   modifieddate
from {{ ref('customer') }}

{% endsnapshot %}
