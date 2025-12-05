with salesorderdetail_snapshot as (
    select
        SalesOrderID,
        SalesOrderDetailID,
        ProductID, 
        CarrierTrackingNumber,
        OrderQuantity,
        SpecialOfferID,
        UnitPrice,
        UnitPriceDiscount,
        TotalPrice
    from {{ ref("salesorderdetail_snapshot") }}
    where dbt_valid_to is null
),

product_snapshot as (
    select
        ProductID,
        ProductName,
        ProductNumber,
        MakeFlag,
        FinishedGoodsFlag,
        Color,
        SafetyStockLevel,
        ReorderPoint,
        StandardCost,
        ListPrice,
        ProductSize,
        SizeUnitMeasureCode,
        WeightUnitMeasureCode,
        Weight,
        DaysToManufacture,
        ProductLine,
        ProductClass,
        ProductStyle,
        ProductSubcategoryID,
        ProductModelID,
        SellStartDate,
        SellEndDate,
        ModifiedDate as ProductModifiedDate
    from {{ ref('product_snapshot') }}  
    where dbt_valid_to is null
),

salesorderheader_snapshot as (
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
),

transformed as (
    select
        -- Sales Order Detail fields
        sod.SalesOrderID,
        sod.SalesOrderDetailID,
        
        sod.OrderQuantity,
        sod.SpecialOfferID,
        sod.UnitPrice,
        sod.UnitPriceDiscount,
        sod.TotalPrice,

        -- Product fields
        p.ProductID,
       
        p.StandardCost,
        p.ListPrice,

        -- Sales Order Header fields
        
        
        soh.CustomerID,
        soh.SalesPersonID,
        soh.TerritoryID,
        soh.BillToAddressID,
        soh.ShipToAddressID,
        soh.ShipMethodID,
        soh.CreditCardID,
        
        soh.CurrencyRateID,
        soh.SubTotal,
        soh.TaxAmt,
        soh.Freight,
        soh.TotalDue
       
    from salesorderdetail_snapshot sod
    left join product_snapshot p 
        on sod.ProductID = p.ProductID
    left join salesorderheader_snapshot soh 
        on sod.SalesOrderID = soh.SalesOrderID
    where soh.row_num = 1
)

select * from transformed