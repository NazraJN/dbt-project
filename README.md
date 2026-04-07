# Phoenix Adventure Data Warehouse (dbt)

A modern analytics warehouse built using dbt, Snowflake, and dimensional modeling (star schema).  
The project includes SCD2 historical dimensions, fact tables, and temporal logic that enables accurate point-in-time reporting and advanced customer/product behavior analytics.

---

## Key features
- SCD2 modeling for customers and products
- Star schema design with well-structured fact and dimension tables
- Order, review, social media & clickstream facts
- Temporal joins for accurate point-in-time analysis
- Automated testing, documentation, and lineage tracking using dbt

---

## Tech Stack
- dbt for transformation, documentation, testing, and orchestration
- Snowflake as the cloud data warehouse
- SQL for data modeling and transformations

---

## Run the project
- Build models - dbt run

- Execute snapshots - dbt snapshot

- Run tests - dbt test

- Generate and view documentation - dbt docs generate && dbt docs serve
