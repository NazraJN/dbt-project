

with product_snapshot as (
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
       
        ModifiedDate
    from {{ ref("product_snapshot") }}
    where dbt_valid_to is null
),

-- Product model snapshot (only current valid records)
product_model_snapshot as (
    select
        ProductModelID,
       
       
        ModifiedDate as ModelModifiedDate
    from {{ ref("productmodel_snapshot") }}
    where dbt_valid_to is null
),

-- Join product + product model
transformed as (
    select
        row_number() over (order by p.ProductID) as Product_SK,  -- Surrogate Key
        p.ProductID,
        p.ProductName,
        p.ProductNumber,
        p.MakeFlag,
        p.FinishedGoodsFlag,
        p.Color,
        p.SafetyStockLevel,
        p.ReorderPoint,
        p.StandardCost,
        p.ListPrice,
        p.ProductSize,
        p.SizeUnitMeasureCode,
        p.WeightUnitMeasureCode,
        p.Weight,
        p.DaysToManufacture,
        p.ProductLine,
          ProductClass,
        ProductStyle,
        p.ProductSubcategoryID,
        p.ProductModelID,
      
        pm.ModelModifiedDate,
        p.SellStartDate,
        p.SellEndDate,
       
        p.ModifiedDate as ProductModifiedDate
    from product_snapshot p
    left join product_model_snapshot pm
        on p.ProductModelID = pm.ProductModelID
)

select *
from transformed