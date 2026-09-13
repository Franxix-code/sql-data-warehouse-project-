SQL Data Warehouse Project

📌 Overview

This project demonstrates the design and implementation of an end-to-end SQL Server data warehouse using the Medallion Architecture (Bronze, Silver, and Gold layers).

The warehouse integrates data from CRM and ERP source systems, applies data cleansing and transformation processes, and produces a structured analytical layer using a star schema.

I built this project independently as part of my data engineering learning journey, following concepts demonstrated in Baraa’s SQL Data Warehouse tutorials. While the tutorials provided guidance on the concepts and overall approach, I implemented the project myself and worked through the SQL, transformations, data-quality issues, and debugging involved in building the warehouse.

The main goal of this project was to gain practical experience with SQL Server, ETL, data modelling, data quality, and data warehouse architecture.

---

🎯 Project Objectives

- Build an end-to-end data warehouse using SQL Server
- Integrate data from multiple CRM and ERP source systems
- Implement a Bronze, Silver, and Gold data architecture
- Clean and standardize raw source data
- Handle duplicates, NULL values, invalid dates, and inconsistent records
- Apply business rules during transformation
- Build a dimensional model using fact and dimension tables
- Implement data-quality checks
- Develop reusable ETL stored procedures
- Practice SQL Server error handling and ETL monitoring
- Create an analytical layer suitable for reporting and analysis

---

🏗️ Architecture

The project follows the Medallion Architecture:

                 ┌───────────────────┐
                 │   CRM / ERP Data  │
                 │      (CSV)        │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │   BRONZE LAYER    │
                 │   Raw Data        │
                 │   Source-Aligned  │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │   SILVER LAYER    │
                 │ Cleaned &         │
                 │ Standardized Data│
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │     GOLD LAYER    │
                 │ Dimensional Model │
                 │ Fact + Dimensions │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │ Analytics /       │
                 │ Reporting         │
                 └───────────────────┘

The project also includes architecture and star-schema diagrams in the "docs/" directory.

---

🥉 Bronze Layer

The Bronze layer stores data as close as possible to its original source format.

Responsibilities

- Load raw CRM and ERP CSV files
- Preserve source-level information
- Perform minimal transformation
- Provide a reliable staging area for downstream processing

Sources

The project contains data from two source systems:

CRM

- Customer information
- Product information
- Sales transactions

ERP

- Customer demographic information
- Customer location information
- Product category information

Data is loaded into the Bronze layer using SQL Server "BULK INSERT".

---

🥈 Silver Layer

The Silver layer contains cleaned, standardized, and transformed data.

Data transformations include

- Removing duplicate records
- Handling NULL values
- Standardizing categorical values
- Trimming unnecessary whitespace
- Validating and converting dates
- Handling invalid or inconsistent values
- Correcting inconsistent sales calculations
- Generating derived date ranges
- Applying business rules
- Standardizing customer and product information

Window functions such as "ROW_NUMBER()" and "LEAD()" were used during the transformation process.

---

🥇 Gold Layer

The Gold layer provides the analytical model used for reporting and analysis.

The warehouse follows a star-schema design consisting of:

Dimension Views

- "gold.dim_customers"
- "gold.dim_products"

Fact View

- "gold.fact_sales"

The sales fact is designed at the following grain:

«One record per product sold within a sales order.»

The fact layer contains measures and foreign keys that allow sales performance to be analyzed by customers, products, and dates.

---

⭐ Star Schema

The resulting model follows a star-schema structure:

                    ┌─────────────────┐
                    │  dim_customers  │
                    └────────┬────────┘
                             │
                             │
                             ▼
                    ┌─────────────────┐
                    │   fact_sales    │
                    └────────┬────────┘
                             │
                             │
                             ▼
                    ┌─────────────────┐
                    │  dim_products   │
                    └─────────────────┘

A detailed star-schema diagram is available in:

docs/star_schema.png

---

🔄 ETL Process

The ETL workflow follows these major stages:

Source CSV Files
       │
       ▼
Load Bronze
       │
       ▼
Transform & Clean
       │
       ▼
Load Silver
       │
       ▼
Create Gold Model
       │
       ▼
Data Quality Checks
       │
       ▼
Analytics

The ETL processes are implemented using T-SQL stored procedures.

Error handling using "TRY...CATCH" is also implemented to identify and report failures during loading.

---

🧪 Data Quality

Data-quality checks were developed to identify common problems in the source data.

Checks include:

- Duplicate records
- Missing identifiers
- NULL values
- Invalid dates
- Invalid or inconsistent categorical values
- Missing product information
- Invalid product costs
- Invalid quantities
- Sales calculation inconsistencies

The data-quality scripts can be found in:

scripts/test/data_quality_checks.sql

---

🛠️ Technologies Used

- Microsoft SQL Server
- T-SQL
- SQL Server Management Studio (SSMS)
- Git
- GitHub

SQL concepts applied

- DDL and DML
- Joins
- CTEs
- Subqueries
- CASE expressions
- Window functions
- Stored procedures
- Temporary tables
- Error handling
- Data cleaning
- Data transformation
- Dimensional modelling
- Star schema
- Data-quality validation

---

📁 Repository Structure

sql-data-warehouse-project/
│
├── datasets/
│   ├── source_crm/
│   └── source_erp/
│
├── docs/
│   ├── data_flow.png
│   ├── high_level_architecture.png
│   └── star_schema.png
│
├── scripts/
│   ├── bronze/
│   │   ├── ddl_bronze.sql
│   │   └── load_bronze.sql
│   │
│   ├── silver/
│   │   ├── ddl_silver.sql
│   │   └── load_silver.sql
│   │
│   ├── gold/
│   │   ├── ddl_gold_dim_customers.sql
│   │   ├── ddl_gold_dim_products.sql
│   │   └── ddl_gold_fact_sales.sql
│   │
│   ├── test/
│   │   └── data_quality_checks.sql
│   │
│   └── init_database.sql
│
└── README.md

---

🚀 How to Run the Project

1. Clone the repository

git clone https://github.com/Franxix-code/sql-data-warehouse-project-.git

2. Open SQL Server Management Studio

Connect to your SQL Server instance.

3. Initialize the database

Run:

scripts/init_database.sql

4. Create the Bronze layer

Run:

scripts/bronze/ddl_bronze.sql

Update the CSV file paths in the Bronze loading script to match your local environment.

Then execute:

scripts/bronze/load_bronze.sql

5. Create and load the Silver layer

Run:

scripts/silver/ddl_silver.sql
scripts/silver/load_silver.sql

6. Create the Gold layer

Run the Gold scripts:

scripts/gold/

7. Run data-quality checks

Execute:

scripts/test/data_quality_checks.sql

---

📊 Project Outcomes

Through this project, I gained practical experience in:

- Designing a multi-layer data warehouse
- Building ETL processes using SQL Server
- Working with raw source data
- Cleaning and transforming real-world datasets
- Implementing data-quality checks
- Writing reusable stored procedures
- Handling ETL errors
- Designing dimensional models
- Building fact and dimension structures
- Applying SQL window functions to transformation problems
- Organizing a data-engineering project for version control

---

📚 Learning Reference

This project was developed independently while learning from Baraa's SQL Data Warehouse tutorials.

The tutorials were used as a learning reference for concepts such as:

- Data warehouse architecture
- Medallion architecture
- ETL design
- Data transformation
- Dimensional modelling
- Star-schema design

The implementation, debugging, data-quality investigation, and project organization were carried out as part of my own learning and practice.

---

👨‍💻 Author

Francis Oluwadamilola Ayodele

Aspiring Data Engineer

GitHub: "Franxix-code"

---

⭐ Future Improvements

Planned improvements include:

- Automating data-quality validation
- Improving ETL configuration and portability
- Adding more robust surrogate-key management
- Implementing additional performance optimization
- Adding indexing strategies for analytical workloads
- Adding automated pipeline orchestration
- Connecting the warehouse to a BI/reporting tool
- Exploring cloud-based data-engineering technologies
