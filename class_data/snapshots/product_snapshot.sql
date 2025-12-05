{% snapshot product_snapshot %}

{{
    config(
        target_schema='DEV',
        unique_key='ProductID',
        strategy='timestamp',
        updated_at='ModifiedDate'
    )
}}

with base as (
    select
        ProductID,
        Name as ProductName,
        ProductNumber,
        MakeFlag,
        FinishedGoodsFlag,
        Color,
        SafetyStockLevel,
        ReorderPoint,
        StandardCost,
        ListPrice,
        Size as ProductSize,
        SizeUnitMeasureCode,
        WeightUnitMeasureCode,
        Weight,
        DaysToManufacture,
        ProductLine,
        Class as ProductClass,
        Style as ProductStyle,
        ProductSubcategoryID,
        ProductModelID,
        SellStartDate,
        SellEndDate,
        ModifiedDate
    from {{ ref('product') }}
    where ProductModelID is not null
),

-- Calculate mode for size unit
size_mode as (
    select SizeUnitMeasureCode
    from base
    where SizeUnitMeasureCode is not null
    group by SizeUnitMeasureCode
    order by count(*) desc
    limit 1
),

-- Calculate mode for weight unit
weight_mode as (
    select WeightUnitMeasureCode
    from base
    where WeightUnitMeasureCode is not null
    group by WeightUnitMeasureCode
    order by count(*) desc
    limit 1
),

weight_avg as (
    select avg(Weight) as avg_weight
    from base
    where Weight is not null
),

aggregates as (
    select
        (select SizeUnitMeasureCode from size_mode) as mode_sizeunit,
        (select WeightUnitMeasureCode from weight_mode) as mode_weightunit,
        (select avg_weight from weight_avg) as avg_weight
),

cleaned as (
    select
        b.ProductID,
        b.ProductName,
        b.ProductNumber,
        b.MakeFlag,
        b.FinishedGoodsFlag,
        b.Color,
        b.SafetyStockLevel,
        b.ReorderPoint,
        b.StandardCost,
        b.ListPrice,
        b.ProductSize,
        coalesce(b.SizeUnitMeasureCode, a.mode_sizeunit) as SizeUnitMeasureCode,
        coalesce(b.WeightUnitMeasureCode, a.mode_weightunit) as WeightUnitMeasureCode,
        coalesce(b.Weight, a.avg_weight) as Weight,
        case when b.DaysToManufacture = 0 then 1 else b.DaysToManufacture end as DaysToManufacture,
        b.ProductLine,
        b.ProductClass,
        b.ProductStyle,
        b.ProductSubcategoryID,
        b.ProductModelID,
        b.SellStartDate,
        b.SellEndDate,
        b.ModifiedDate
    from base b
    cross join aggregates a
)

select * from cleaned

{% endsnapshot %}