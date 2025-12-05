{% snapshot salesorderdetail_snapshot %}

{{
    config(
        target_schema='DEV',
       
        unique_key='SalesOrderDetailID',
         strategy='timestamp',
        updated_at='ModifiedDate'
    )
}}

select
    SalesOrderID,
    SalesOrderDetailID,
    CarrierTrackingNumber,
    OrderQty as OrderQuantity,
    ProductID,
    SpecialOfferID,
    UnitPrice,
    UnitPriceDiscount,
    round(LineTotal, 0) as TotalPrice,
    ModifiedDate
from {{ ref('salesorderdetail') }}
WHERE SalesOrderID is not null

{% endsnapshot %}
