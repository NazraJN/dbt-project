with salesorderdetail_snapshot as (
    select
        SalesOrderID,
        SalesOrderDetailID,
        CarrierTrackingNumber,
        OrderQuantity,
        ProductID,
        SpecialOfferID,
        UnitPrice,
        UnitPriceDiscount,
        TotalPrice
    from {{ ref("salesorderdetail_snapshot") }}
    where dbt_valid_to is null
),
lsalesorderheader_snapshot as (
    select
        SalesOrderID,
        RevisionNumber,
        OrderDate,
        DueDate,
        ShipDate,
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
        ModifiedDate as HeaderModifiedDate,
        row_number() over (partition by SalesOrderID order by SalesOrderID) as row_num
    from {{ ref('salesorderheader_snapshot') }}
    where dbt_valid_to is null
)
select
    h.SalesOrderID,
    h.OrderDate,
    h.DueDate,
    h.ShipDate,
    h.Freight,
    h.Status,
    h.CustomerID,
    h.SalesPersonID,
    h.TerritoryID,
    h.TotalDue,
    d.TotalPrice,
    d.SalesOrderDetailID,
    d.ProductID,
    d.OrderQuantity,
    h.TaxAmt,
    d.UnitPriceDiscount,
    d.UnitPrice
from salesorderdetail_snapshot d
join lsalesorderheader_snapshot h
    on d.SalesOrderID = h.SalesOrderID
where h.row_num = 1