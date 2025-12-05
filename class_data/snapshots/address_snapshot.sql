{% snapshot address_snapshot %}

{{
    config(
        target_schema='DEV',
        unique_key='AddressID',
        strategy='timestamp',
        updated_at='ModifiedDate'
    )
}}

select
    AddressID,
    AddressLine1 as AddressLine,
    City,
    StateProvinceID,
    PostalCode,
    modifieddate
from {{ ref('address') }}
--where AddressID is not null

{% endsnapshot %}
