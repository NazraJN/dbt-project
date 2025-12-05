-- Get current valid customers frmo  the already created silver layer data 
with customers as (
    select
        CustomerID,
        AddressID,
        StoreID,
        TerritoryID,
        AccountNumber,
        ModifiedDate
    from {{ ref('customers_snapshot') }}
    where AddressID is not null
),

-- Get current valid addresses from the already crerated  adress tabel in the silver layer
addresses as (
    select
        AddressID,
        AddressLine,
        City,
        StateProvinceID,
        PostalCode,
         ModifiedDate
    from {{ ref('address_snapshot') }}
    where AddressID is not null
),

-- Join customers with addresses and create sort of primary key
dim_customers as (
    select
    row_number() over (order by c.CustomerID) as customer_sk,
        c.CustomerID,
        c.AddressID,
        c.StoreID,
        c.TerritoryID,
        c.AccountNumber,
        c.ModifiedDate as CustomerModifiedDate,
        a.AddressLine,
        a.City,
        a.StateProvinceID,
        a.PostalCode,
        a.ModifiedDate as AddressModifiedDate
    from customers c
    left join addresses a
        on c.AddressID = a.AddressID
)


select *
from dim_customers
