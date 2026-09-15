/*
    Script: ddl_gold.sql
    Purpose: Defines (drops and recreates) the three Gold layer tables:
             dim_customers, dim_products, and fact_sales. Gold holds the
             star schema used for reporting and analytics.

             Gold is implemented as physical tables rather than views.
             Views were tried first, but joining dim_customers/dim_products
             to fact_sales on their ROW_NUMBER()-computed surrogate keys
             caused SQL Server to fall back to a runaway nested-loop join
             (no index possible on a computed, non-materialized column).
             Physical tables with PRIMARY KEY constraints on the surrogate
             keys let SQL Server use proper indexed joins instead.

    How to run:
    1. Run init_database.sql, ddl_bronze.sql, and ddl_silver.sql first.
    2. Execute this entire script. Each table is dropped and recreated if
       it already exists, so it is safe to re-run.
    3. After this, run load_gold.sql to populate the tables.
*/

IF OBJECT_ID('gold.dim_customers','U') IS NOT NULL
	DROP TABLE gold.dim_customers;
CREATE TABLE gold.dim_customers (
	customer_key INT PRIMARY KEY,
	customer_id INT,
	customer_number NVARCHAR(50),
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	marital_status NVARCHAR(50),
	gender NVARCHAR(50),
	birthdate DATE,
	country NVARCHAR(50),
	create_date DATE
);

IF OBJECT_ID('gold.dim_products','U') IS NOT NULL
	DROP TABLE gold.dim_products;
CREATE TABLE gold.dim_products (
	product_key INT PRIMARY KEY,
	product_id INT,
	category_id NVARCHAR(50),
	product_number NVARCHAR(50),
	category NVARCHAR(50),
	subcategory NVARCHAR(50),
	product_name NVARCHAR(50),
	product_line NVARCHAR(50),
	cost INT,
	maintenance NVARCHAR(50),
	product_start_date DATE
);

IF OBJECT_ID('gold.fact_sales','U') IS NOT NULL
	DROP TABLE gold.fact_sales;
CREATE TABLE gold.fact_sales (
	order_number NVARCHAR(50),
	product_key INT,
	customer_key INT,
	orderdate DATE,
	shipdate DATE,
	duedate DATE,
	price INT,
	quantity INT,
	sales INT
);
