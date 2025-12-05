{% snapshot salesorderheader_snapshot %}

{{
    config(
        target_schema='DEV',
        unique_key='SalesOrderID',
        strategy='timestamp',
        updated_at='ModifiedDate'
    )
}}

select
    SalesOrderID,
    RevisionNumber,
    cast(OrderDate as date) as OrderDate,
    cast(DueDate as date) as DueDate,
    cast(ShipDate as date) as ShipDate,
    datediff(day, OrderDate, DueDate) as DaysToSaleDue,
    datediff(day, OrderDate, ShipDate) as DaysToSalesShip,
    Status,
    OnlineOrderFlag,
    SalesOrderNumber,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    SalesPersonID,
    TerritoryID,
    BillToAddressID,
    ShipToAddressID,
    ShipMethodID,
    CreditCardID,
    CreditCardApprovalCode,
    CurrencyRateID,
    SubTotal,
    TaxAmt,
    Freight,
    TotalDue,
  ModifiedDate
from {{ ref('salesorderheader') }}
where SalesOrderID is not null

{% endsnapshot %}