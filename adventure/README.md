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

---

## Architecture

### Dimensional Modeling (Star Schema)

The project follows **Kimball methodology** with facts and dimensions:

```
FACTS (Transactions/Events)        DIMENSIONS (Entities)
├── fact_orders                    ├── dim_customers_data (SCD2)
├── fact_reviews                   ├── dim_products (SCD2)
├── fact_social_media              └── dim_product_model (reference)
├── fact_web_logs
└── customer_orders (wide fact)

AGGREGATES & VIEWS
├── fact_web_sessions (sessionized)
├── agg_web_page_views (daily rollup)
└── agg_web_social_correlation (web + social joined)
```

### Data Flow

```
RAW SOURCES (Bronze)
  ↓
SNAPSHOTS (SCD2 tracking)
  ├── customers_data_snapshot
  ├── customers_snapshot
  ├── products_snapshot
  ├── product_snapshot
  ├── salesorderheader_snapshot
  └── salesorderdetail_snapshot
  ↓
GOLD LAYER (Facts & Dimensions)
  ├── dim_* (dimensions with surrogate keys)
  ├── fact_* (fact tables with temporal joins)
  ├── agg_* (aggregated views)
  └── customer_orders (wide denormalized fact)
```

---

## Snapshots

Snapshots capture **historical versions** of dimension tables using Type 2 SCD logic. Enables accurate historical joins.

### Active Snapshots

| Snapshot | Source | Strategy | Unique Key | Check Cols |
|----------|--------|----------|------------|-----------|
| `customers_data_snapshot` | `customers` | check | CustomerID | CustomerName, Email, Location |
| `customers_snapshot` | `customers` | check | CustomerID | CustomerName, Email, Location |
| `products_snapshot` | `products` | check | ProductID | ProductName, Category, UnitPrice |
| `product_snapshot` | `product` | timestamp | ProductID | ModifiedDate |
| `productmodel_snapshot` | `productmodel` | - | ProductModelID | - |
| `salesorderheader_snapshot` | `salesorderheader` | check | SalesOrderID | OrderDate, Status |
| `salesorderdetail_snapshot` | `salesorderdetail` | check | SalesOrderDetailID | OrderQuantity, UnitPrice |

Each snapshot produces 4 SCD Type 2 columns:
- `dbt_scd_id` — surrogate key for the dimensional row
- `dbt_valid_from` — row became valid
- `dbt_valid_to` — row became invalid (NULL = current)
- `dbt_updated_at` — timestamp of detection

**Usage in Facts**: Join facts to snapshots using temporal predicates:
```sql
LEFT JOIN dim_customers c
  ON fact.customer_id = c.CustomerID
  AND fact.order_date >= c.dbt_valid_from
  AND (c.dbt_valid_to IS NULL OR fact.order_date < c.dbt_valid_to)
```

---

## Data Layers

### Bronze Layer (`models/bronze/`)

Raw pass-through models from sources. Minimal transformation.

- `address.sql`, `customer.sql`, `customers.sql`, `orders.sql`
- `product.sql`, `productmodel.sql`, `products.sql`
- `reviews.sql`, `salesorderdetail.sql`, `salesorderheader.sql`
- `social_media.sql`, `weblogs.sql`

### Gold Layer (`models/gold/`)

Production-ready fact and dimension tables with business logic, tests, and documentation.

#### Dimensions

- **`dim_customers_data`** — Customer dimension with SCD2 history (from `customers_data_snapshot`). Includes surrogate key `customer_sk`.
- **`dim_products`** — Product dimension with price/category history (from `products_snapshot`). Includes `product_sk`.
- **`dim_product`** — Detailed product attributes (from `product_snapshot`). Includes `Product_SK`.

#### Facts

- **`fact_orders`** — Order-level fact. Grain: one row per order. Includes customer/product surrogate keys with temporal joins for historical accuracy.
- **`fact_reviews`** — Review events. Grain: one row per review. Attributes: rating, sentiment, product, customer.
- **`fact_social_media`** — Social media posts/engagements. Grain: one row per post. Attributes: timestamp, platform, content, sentiment (standardized).
- **`fact_social_media_enriched`** — Enriched social media with product detection, sentiment score, URL flags, word count.
- **`fact_web_logs`** — Web page events (click stream). Grain: one row per page view. Includes customer surrogate key and URL detection flag.
- **`customer_orders`** — Wide denormalized fact combining order + customer + product attributes. Used for reporting/exports.

#### Aggregates & Views

- **`fact_web_sessions`** — Sessionized web events (30-min inactivity threshold). Grain: one row per session. Includes session duration, page view count.
- **`agg_web_page_views`** — Daily page-view rollup. Grain: event_date + page. Metrics: page_views, unique_users, url_count.
- **`agg_web_social_correlation`** — Joins web page views with social product mentions. Detects same-day / prior-day / next-day temporal proximity for correlation analysis.

---

## Key Models

### `dim_customers_data` (Dimension with SCD2)

```sql
SELECT
  customer_sk         -- surrogate key
  CustomerID          -- natural key
  CustomerName, Email, Location, SignupDate
  dbt_valid_from, dbt_valid_to   -- SCD Type 2 columns
  is_current          -- boolean flag
FROM customers_data_snapshot
```

**Use for**: Customer attribute lookups, customer cohort analysis, churn tracking.

---

### `fact_orders` (Fact with Temporal Joins)

```sql
SELECT
  OrderID
  OrderDate
  CustomerID
  customer_sk         -- join key to dim_customers_data
  ProductID
  product_sk          -- join key to dim_products
  Quantity, TotalAmount
  customer_name, email  -- denormalized from snapshot
  product_name, product_price_at_order
FROM orders
LEFT JOIN customers_data_snapshot c
  ON orders.customer_id = c.CustomerID
  AND orders.order_date >= c.dbt_valid_from
  AND (c.dbt_valid_to IS NULL OR orders.order_date < c.dbt_valid_to)
LEFT JOIN products_snapshot p
  ON orders.product_id = p.ProductID
  AND orders.order_date >= p.dbt_valid_from
  AND (p.dbt_valid_to IS NULL OR orders.order_date < p.dbt_valid_to)
```

**Grain**: One row per order.  
**Use for**: Revenue analysis, customer LTV, product revenue, cohort-based metrics.

---

### `fact_web_logs` (Event Fact with Temporal Joins)

```sql
SELECT
  log_id                    -- deterministic hash-based surrogate key
  event_ts
  customer_id, customer_sk  -- link to customer dimension
  page, action              -- normalized event data
  has_url                   -- boolean feature
FROM weblogs
LEFT JOIN customers_data_snapshot
  ON weblogs.customer_id = customers_data_snapshot.CustomerID
  AND weblogs.event_ts >= dbt_valid_from
  AND (dbt_valid_to IS NULL OR event_ts < dbt_valid_to)
```

**Grain**: One row per web event/click.  
**Use for**: User funnel analysis, page engagement, event sequence modeling.

---

### `fact_web_sessions` (Aggregated Sessions)

```sql
SELECT
  session_id          -- deterministic hash
  customer_id, customer_sk
  session_start, session_end
  session_duration_seconds
  page_views          -- count of events in session
FROM fact_web_logs
WHERE is_new_session = 1 (30-minute inactivity threshold)
```

**Grain**: One row per user session.  
**Use for**: Session funnel, session duration trends, session-level conversions.

---

### `agg_web_social_correlation` (Multi-Source Join View)

```sql
SELECT
  pv.event_date, pv.page, pv.page_views, pv.unique_users
  sm.detected_product, sm.sentiment, sm.mention_count
  sm.positive_mentions, sm.negative_mentions, sm.avg_sentiment_score
  temporal_proximity  -- 'same_day', 'prior_day', 'next_day', null
FROM agg_web_page_views pv
LEFT JOIN social_mentions sm
  ON page LIKE detected_product
  AND (mention_date, page) temporal proximity
```

**Use for**: Correlation between social sentiment/mentions and web page activity. Identify which products/pages benefit from social buzz.

---

## Running the Project

### Prerequisites

1. **dbt Installation**:
   ```powershell
   pip install dbt-snowflake>=1.7.0
   ```

2. **Python (Optional ML Enrichment)**:
   ```powershell
   pip install -r requirements.txt
   ```

3. **Snowflake Connection**: Configure `~/.dbt/profiles.yml` with your Snowflake credentials.

### Common Commands

**Parse the project** (validate YAML, models, tests):
```powershell
dbt parse
```

**Run all models** (execute transformations):
```powershell
dbt run
```

**Run specific model(s)**:
```powershell
dbt run --models fact_orders dim_customers_data
```

**Run models by tag**:
```powershell
dbt run --models tag:fact
```

**Execute snapshots** (capture current state of dimension tables):
```powershell
dbt snapshot
```

**Run tests** (data quality validation):
```powershell
dbt test
```

**Run tests for specific model**:
```powershell
dbt test --models fact_orders
```

**Generate and serve documentation**:
```powershell
dbt docs generate
dbt docs serve
```

**Full refresh** (rebuild incremental models from scratch):
```powershell
dbt run --full-refresh
```

---

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

## Troubleshooting

### Parse Errors in `schema.yml`

Check YAML indentation (2 spaces). Common issue: test arguments nested incorrectly.

```yaml
# ❌ Wrong (dbt0102 deprecation)
- name: StoreID
  tests:
    - dbt_expectations.expect_column_values_to_be_in_set:
        value_set: [1, 2, 3]

# ✅ Correct
- name: StoreID
  tests:
    - dbt_expectations.expect_column_values_to_be_in_set:
        arguments:
          value_set: [1, 2, 3]
```

### Snapshot Issues

Ensure snapshot source tables have no duplicates on `unique_key`:
```powershell
dbt snapshot
dbt test --models customers_data_snapshot
```

### Slow Queries on Facts

Facts are large; add indexes or clustering on frequent join keys:
```sql
ALTER TABLE fact_web_logs CLUSTER BY (customer_id, event_ts);
```

---

## Contact & Support

For questions on:
- **dbt & data modeling**: See [dbt docs](https://docs.getdbt.com/)
- **Snapshots & SCD**: See [dbt snapshots](https://docs.getdbt.com/docs/build/snapshots)
- **Project specifics**: Review `models/schema.yml` and `dbt_project.yml`

---

**Last Updated**: December 5, 2025  
**dbt Version**: 1.11.0-b4  
**Adapter**: Snowflake 1.10.2
