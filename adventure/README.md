# dbt Project: Phoenix Adventure Data Warehouse

A modern dbt data warehouse project modeling e-commerce transactions, customer behavior, and digital engagement using dimensional modeling (star schema) with Type 2 Slowly Changing Dimensions (SCD2).

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Snapshots](#snapshots)
4. [Data Layers](#data-layers)
5. [Key Models](#key-models)
6. [Running the Project](#running-the-project)
7. [Testing & Validation](#testing--validation)
8. [File Structure](#file-structure)
9. [Future Enhancements](#future-enhancements)

---

## Project Overview

**Purpose**: Transform raw e-commerce, customer, and web activity data into a queryable analytical schema.

**Technology Stack**:
- **dbt** (1.11.0+) - Data transformation
- **Snowflake** - Data warehouse (Snowpark-compatible)
- **Python** (optional ML enrichment) - sentence-transformers, transformers
- **Snapshots**: Type 2 SCD for customer, product, and order tracking

**Key Use Cases**:
- Customer lifetime value (LTV) analysis
- Cohort analysis with historical customer attributes
- Product performance trending (price history)
- Web engagement and sessionization
- Social media sentiment correlation with web activity
- Review sentiment and product ratings

### Data Flow

```
RAW SOURCES (Bronze)
  ↓
SNAPSHOTS (SCD2 tracking)
  ├── customers_data_snapshot
  └── products_snapshot
  ↓
GOLD LAYER (Facts & Dimensions)
  ├── dim_* (dimensions with surrogate keys)
  ├── fact_* (fact tables with temporal joins)
  └── customer_orders (wide denormalized fact)
```

### Active Snapshots

| Snapshot | Source | Strategy | Unique Key | Check Cols |
|----------|--------|----------|------------|-----------|
| `customers_data_snapshot` | `customers` | check | CustomerID | CustomerName, Email, Location |
| `products_snapshot` | `products` | check | ProductID | ProductName, Category, UnitPrice |


Each snapshot produces 4 SCD Type 2 columns:
- `dbt_scd_id` — surrogate key for the dimensional row
- `dbt_valid_from` — row became valid
- `dbt_valid_to` — row became invalid (NULL = current)
- `dbt_updated_at` — timestamp of detection

## Data Layers

### Bronze Layer (`models/bronze/`)

Raw pass-through models from sources. Minimal transformation.

- `customers.sql`, `orders.sql`
-  `products.sql`
- `reviews.sql`
- `social_media.sql`, `weblogs.sql`

### Gold Layer (`models/gold/`)

Production-ready fact and dimension tables with business logic, tests, and documentation.

#### Dimensions

- **`dim_customers_data`** — Customer dimension with SCD2 history (from `customers_data_snapshot`). Includes surrogate key `customer_sk`.
- **`dim_products`** — Product dimension with price/category history (from `products_snapshot`). Includes `product_sk`.

#### Facts

- **`fact_orders`** — Order-level fact. Grain: one row per order. Includes customer/product surrogate keys with temporal joins for historical accuracy.
- **`fact_reviews`** — Review events. Grain: one row per review. Attributes: rating, sentiment, product, customer.
- **`fact_social_media`** — Social media posts/engagements. Grain: one row per post. Attributes: timestamp, platform, content, sentiment (standardized).
- **`fact_social_media_enriched`** — Enriched social media with product detection, sentiment score, URL flags, word count.
- **`fact_web_logs`** — Web page events (click stream). Grain: one row per page view. Includes customer surrogate key and URL detection flag.
- **`customer_orders`** — Wide denormalized fact combining order + customer + product attributes. Used for reporting/exports.


## Testing & Validation

### Test Types

1. **Built-in Tests** (in `schema.yml`):
   - `unique` — column values are distinct
   - `not_null` — column has no nulls
   - `accepted_values` / `in_set` — column values in allowed set
   - `relationships` — foreign key to another table

2. **dbt_expectations Tests** (from dbt-expectations package):
   - `expect_column_values_to_be_of_type` — type validation
   - `expect_column_values_to_be_between` — range validation
   - `expect_column_values_to_be_in_set` — enum validation

### Example Test Coverage

**Dimensions**:
- Surrogate key (`customer_sk`, `product_sk`) is `unique` and `not_null`
- Natural key (`CustomerID`, `ProductID`) is `unique` and `not_null`

**Facts**:
- Primary key (e.g., `OrderID`) is `unique` and `not_null`
- Foreign keys (e.g., `customer_sk`) have `relationships` to dimension tables
- Date columns are `not_null` and correct type

**Aggregates**:
- Dimension key combinations are `unique`
- Metric columns are `not_null` and non-negative

### Run Tests

```powershell
dbt test
dbt test --models fact_orders
dbt test --models tag:critical
```

---

## File Structure

```
adventure/
├── README.md                           # This file
├── dbt_project.yml                     # dbt configuration
├── packages.yml                        # dbt package dependencies
├── requirements.txt                    # Python dependencies (ML enrichment)
├── models/
│   ├── schema.yml                      # Data dictionary & tests
│   ├── sources.yml                     # Source definitions
│   ├── bronze/                         # Raw pass-through models
│   │   ├── address.sql, customers.sql, orders.sql, ...
│   │   └── weblogs.sql, social_media.sql, ...
│   ├── gold/                           # Production-ready fact & dimensions
│   │   ├── dim_customers_data.sql
│   │   ├── dim_products.sql
│   │   ├── fact_orders.sql
│   │   ├── fact_reviews.sql
│   │   ├── fact_social_media.sql
│   │   ├── fact_social_media_enriched.sql
│   │   ├── fact_web_logs.sql
│   │   ├── fact_web_sessions.sql
│   │   ├── agg_web_page_views.sql
│   │   ├── agg_web_social_correlation.sql
│   │   └── customer_orders.sql
│   └── python/                         # Python models (optional ML)
│       └── enrich_social_media.py      # Sentence embeddings + HF sentiment
├── snapshots/                          # Type 2 SCD snapshots
│   ├── customers_data_snapshot.sql
│   ├── products_snapshot.sql
│   ├── salesorderheader_snapshot.sql
│   └── ...
├── tests/                              # Custom tests (if any)
├── macros/                             # Custom macros (if any)
├── seeds/                              # Static data files (if any)
├── target/                             # dbt artifacts (generated)
└── logs/                               # dbt logs (generated)
```

---

## Key Design Decisions

### 1. **Type 2 SCD for Dimensions**

**Why?** Enables historical accuracy in fact queries. Orders joined to customer snapshot at order time get correct customer attributes as they were then, not current values.

**Cost**: Extra storage for dimension history; slightly complex joins.

**Benefit**: Accurate cohort analysis, price history tracking, customer attribute trends.

---

### 2. **Temporal Joins in Fact Models**

**Why?** Facts inherit historical context from dimensions without storing redundant snapshot versions of facts.

**Example**:
```sql
fact_orders JOIN customers_snapshot
  ON order_date >= valid_from AND (valid_to IS NULL OR order_date < valid_to)
```

Ensures each order uses customer attributes from the snapshot row valid on `order_date`.

---

### 3. **Incremental Materialization for Event Tables**

Facts like `fact_web_logs` and `fact_web_sessions` use `incremental` mode with `unique_key` for performance:
- First run: builds the table.
- Subsequent runs: appends new rows, skips existing rows.

---

### 4. **Aggregates as Views or Tables**

- **Views** (`agg_web_social_correlation`) — lightweight, low latency joins on underlying facts.
- **Tables** (`agg_web_page_views`) — pre-computed rollups for dashboard performance.

Choose based on:
- **View**: Real-time accuracy, small result sets.
- **Table**: High query volume, complex aggregations, dashboard refresh schedules.

---

## Future Enhancements

1. **ML Enrichment**: Activate Python model `enrich_social_media.py` for embeddings and sentiment when Python runtime dependencies are installed.

2. **More Aggregates**:
   - Monthly revenue by product/category
   - Customer LTV (lifetime value) summary table
   - Cohort retention matrix
   - Product performance scorecard

3. **Intermediate Staging Layer**: Add `models/staging/` for complex transformations before gold.

4. **Data Quality Macros**: Implement automated data quality checks (e.g., row count comparisons, freshness validation).

5. **Incremental Strategies**: Migrate more fact tables to `incremental` mode with clustering for large-scale data.

---
