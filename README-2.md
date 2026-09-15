# SQL Data Warehouse Project

An end-to-end data warehouse built in SQL Server, using the **Medallion
architecture** (Bronze → Silver → Gold) to move raw CRM and ERP data
through cleaning and standardization into a business-ready star schema
for analytics and reporting.

## Architecture

![High Level Architecture](docs/high_level_architecture.png)

Raw CSV files from two source systems (CRM and ERP) are loaded into SQL
Server and processed through three layers:

- **Bronze** — raw data loaded as-is from the source CSVs, no
  transformation. Tables are refreshed via truncate-and-insert.
- **Silver** — cleaned and standardized data: whitespace trimmed,
  inconsistent codes mapped to readable values (e.g. gender, marital
  status, country), duplicates removed, and invalid values corrected
  (dates, prices, sales amounts).
- **Gold** — business-ready data modeled as a star schema, materialized
  as physical tables (loaded via `gold.load_gold`) for querying by BI
  tools, ad-hoc SQL, or downstream analytics.

  Gold was originally implemented as views, matching the common
  pattern for this architecture. Testing business-question queries
  against it surfaced a performance issue: joining `dim_customers`
  and `fact_sales` on their `ROW_NUMBER()`-computed surrogate keys
  caused SQL Server to fall back to a nested-loop join with an
  estimated row count in the billions, since a computed, non-stored
  column can't be indexed. Converting Gold to physical tables with
  `PRIMARY KEY` constraints on the surrogate keys resolved this — the
  same query dropped from over a minute to near-instant. The
  trade-off is that Gold no longer updates automatically when Silver
  changes; `gold.load_gold` must be re-run after `silver.load_silver`
  to keep it in sync.

## Data Flow

![Data Flow](docs/data_flow.png)

Each of the six source tables (three from CRM, three from ERP) flows
independently through Bronze and Silver, and converges into the Gold
layer's three objects: `dim_customers`, `dim_products`, and
`fact_sales`.

## Data Model (Star Schema)

![Sales Data Mart Star Schema](docs/star_schema.png)

`gold.fact_sales` sits at the center, at a grain of one row per sales
order line item, and joins to two dimensions via surrogate keys:

- **gold.dim_customers** — merged from CRM customer info and ERP
  birthdate/gender/location data
- **gold.dim_products** — merged from CRM product info and ERP
  category/subcategory data

## Repository Structure

```
sql-data-warehouse-project/
├── README.md
├── LICENSE
├── datasets/
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   └── source_erp/
│       ├── CUST_AZ12.csv
│       ├── LOC_A101.csv
│       └── PX_CAT_G1V2.csv
├── scripts/
│   ├── init_database.sql
│   ├── bronze/
│   │   ├── ddl_bronze.sql
│   │   └── load_bronze.sql
│   ├── silver/
│   │   ├── ddl_silver.sql
│   │   └── load_silver.sql
│   └── gold/
│       ├── ddl_gold.sql
│       └── load_gold.sql
├── tests/
│   └── data_quality_checks.sql
└── docs/
    ├── high_level_architecture.png
    ├── data_flow.png
    └── star_schema.png
```

## How to Run

Run the scripts in this order:

1. **`scripts/init_database.sql`** — creates the `DWH` database and the
   `bronze`, `silver`, and `gold` schemas.
2. **`scripts/bronze/ddl_bronze.sql`** — creates the six Bronze tables.
3. **`scripts/bronze/load_bronze.sql`** — creates the
   `bronze.load_bronze` stored procedure. Update the six file paths
   inside it to point at your local copy of `datasets/`, then run:
   ```sql
   EXEC bronze.load_bronze;
   ```
4. **`scripts/silver/ddl_silver.sql`** — creates the six Silver tables.
5. **`scripts/silver/load_silver.sql`** — creates the
   `silver.load_silver` stored procedure, then run:
   ```sql
   EXEC silver.load_silver;
   ```
6. **`scripts/gold/ddl_gold.sql`** — creates the three Gold tables.
7. **`scripts/gold/load_gold.sql`** — creates the `gold.load_gold`
   stored procedure, then run:
   ```sql
   EXEC gold.load_gold;
   ```

All three stored procedures use truncate-and-reload, so they can be
safely re-run at any time without producing duplicate rows. To fully
refresh the warehouse after a source data change, run all three in
order:
```sql
EXEC bronze.load_bronze;
EXEC silver.load_silver;
EXEC gold.load_gold;
```

## Data Quality Checks

`tests/data_quality_checks.sql` contains the exploratory checks used to
identify the data quality issues that the Silver layer transformation
logic corrects — inconsistent codes, duplicate records, invalid dates,
and mismatched sales/price/quantity values.

## Tech Stack

- SQL Server / T-SQL
- SQL Server Management Studio (SSMS)

## Credits

This project's dataset and overall Medallion architecture pattern are
based on the [SQL Data Warehouse
Project](https://github.com/DataWithBaraa/sql-data-warehouse-project)
by [Data With Baraa](https://www.youtube.com/@DataWithBaraa), used
under the MIT License with attribution. All SQL scripts and diagrams
in this repository are my own independent work.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE)
for details.
