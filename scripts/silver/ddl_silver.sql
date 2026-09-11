/*
    Script: ddl_silver.sql
    Purpose: Defines (drops and recreates) all six Silver layer tables.
             Silver holds cleaned, standardized data transformed from
             Bronze, with a dwh_create_date column added to each table
             for load auditing.

    How to run:
    1. Run init_database.sql and ddl_bronze.sql first.
    2. Execute this entire script. Each table is dropped and recreated if
       it already exists, so it is safe to re-run.
    3. After this, run load_silver.sql to populate the tables.
*/

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
	cst_id int,
	cst_key nvarchar(50),
	cst_firstname nvarchar(50),
	cst_lastname nvarchar(50),
	cst_marital_status nvarchar(50),
	cst_gndr nvarchar(50),
	cst_create_date date,
	dwh_create_date DATETIME DEFAULT GETDATE()
);

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
	prd_id int,
	cat_id nvarchar(50),
	prd_key nvarchar(50),
	prd_nm nvarchar(50),
	prd_cost int,
	prd_line nvarchar(50),
	prd_start_dt date,
	prd_end_dt date,
	dwh_create_date DATETIME DEFAULT GETDATE()
);

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
	sls_ord_nm nvarchar(50),
	sls_prd_key nvarchar(50),
	sls_cust_id nvarchar(50),
	sls_order_dt date,
	sls_ship_dt date,
	sls_due_dt date,
	sls_price int,
	sls_quantity int,
	sls_sales int,
	dwh_create_date DATETIME DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
	cid nvarchar(50),
	bdate date,
	gen nvarchar(50),
	dwh_create_date DATETIME DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
	cid nvarchar(50),
	cntry nvarchar(50),
	dwh_create_date DATETIME DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
	id nvarchar(50),
	cat nvarchar(50),
	subcat nvarchar(50),
	maintenance nvarchar(50),
	dwh_create_date DATETIME DEFAULT GETDATE()
);
