# Phoenix Adventure Data Warehouse (dbt)

A modern analytics warehouse built using dbt, Snowflake, and dimensional modeling (star schema).  
Includes SCD2 snapshots, temporal joins and  fact/dimension modeling.

## Features
- SCD2 historical dimensions (customers, products)
- Order, review, social media & clickstream facts
- Temporal joins for accurate point-in-time analysis

## Tech Stack
- dbt
- Snowflake

## Run the project
dbt run

dbt snapshot

dbt test

dbt docs generate && dbt docs serve
