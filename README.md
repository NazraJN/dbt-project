# Phoenix Adventure Data Warehouse (dbt)

A modern analytics warehouse built using dbt, Snowflake, and dimensional modeling (star schema).  
Includes SCD2 snapshots, temporal joins, fact/dimension modeling, and optional ML enrichment.

## Features
- SCD2 historical dimensions (customers, products)
- Order, review, social media & clickstream facts
- Temporal joins for accurate point-in-time analysis
- Incremental processing for large event datasets

## Tech Stack
- dbt
- Snowflake

## Run the project
dbt snapshot

dbt run

dbt test

dbt docs generate && dbt docs serve
