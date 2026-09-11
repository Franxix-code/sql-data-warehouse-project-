/*
    Script: data_quality_checks.sql
    Purpose: Exploratory checks run against Bronze during Silver layer
             development, used to identify the specific data quality
             issues that load_silver.sql's transformation logic corrects
             (whitespace, inconsistent codes, duplicates, invalid dates,
             sales/price/quantity mismatches, etc).

    How to run:
    This is not meant to be executed top-to-bottom as a single script.
    Run individual SELECT statements as needed to inspect a specific
    table or issue — most are ad hoc checks, not a pipeline.
*/


-- ===================================================================
-- crm_cust_info
-- ===================================================================

-- Check for leading/trailing whitespace in first names
SELECT 
cst_firstname,
LEN(cst_firstname) as namelen,
LEN(TRIM(cst_firstname)),
LEN(cst_firstname) - LEN(TRIM(cst_firstname))
FROM bronze.crm_cust_info;

-- Check distinct values used for gender, to find codes to standardize
SELECT 
DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT * FROM silver.crm_cust_info;


-- ===================================================================
-- erp_loc_a101
-- ===================================================================

-- Check distinct country values and preview the standardization mapping
SELECT
cntry,
CASE
	WHEN cntry = 'DE' THEN 'Germany'
	WHEN cntry IN ('USA','US') THEN 'United States'
	WHEN cntry IS NULL OR cntry = '' THEN 'Unknown'
	ELSE cntry
END cntry1
FROM (
SELECT DISTINCT
cntry
FROM bronze.erp_loc_a101
) t;

SELECT * FROM silver.erp_loc_a101;


-- ===================================================================
-- erp_cust_az12
-- ===================================================================

-- Check customer ID prefix pattern and future-dated birthdates
SELECT 
CASE 
	WHEN cid LIKE 'N%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END cid,
CASE	
	WHEN bdate > GETDATE() THEN NULL
	ELSE bdate
END AS bdate
FROM (
SELECT *
FROM bronze.erp_cust_az12
) t;

-- Check distinct values used for gender, to find codes to standardize
SELECT
gen,
CASE	
	WHEN gen IN ('F','Female') THEN 'Female'
	WHEN gen IN ('M', 'Male') THEN 'Male'
	ELSE 'Unknown'
END AS gen1
FROM (
SELECT DISTINCT gen FROM bronze.erp_cust_az12) T;

SELECT * FROM silver.erp_cust_az12;


-- ===================================================================
-- crm_prd_info
-- ===================================================================

-- Check the category_id / product_key split from prd_key
SELECT
prd_key,
SUBSTRING(prd_key, 1, 5) AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key
FROM (
SELECT * FROM bronze.crm_prd_info) t;

-- Check for duplicate product IDs
SELECT prd_id, COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- Check for missing product names
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm IS NULL;

-- Check for missing product cost
SELECT prd_cost,
ISNULL(prd_cost, 0) prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL;

-- Check distinct product line codes, to find codes to standardize
SELECT DISTINCT
prd_line
FROM bronze.crm_prd_info;

-- Check the prd_end_dt derivation for one specific product
SELECT 
prd_key,
prd_start_dt,
DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) new_dt
FROM bronze.crm_prd_info
WHERE prd_key = 'AC-HE-HL-U509-R';


-- ===================================================================
-- erp_px_cat_g1v2
-- ===================================================================

-- Check the id format standardization (underscore to hyphen)
SELECT 
REPLACE(id, '_','-') AS id
FROM (
SELECT * FROM bronze.erp_px_cat_g1v2) T;

-- Check distinct maintenance values
SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;

SELECT * FROM silver.erp_px_cat_g1v2;


-- ===================================================================
-- crm_sales_details
-- ===================================================================

-- Check for duplicate order numbers
SELECT 
sls_ord_nm,
COUNT(*) 
FROM (
SELECT * FROM bronze.crm_sales_details) t
GROUP BY sls_ord_nm
HAVING COUNT(*) > 1;

-- Check for missing order/customer/product identifiers
SELECT
sls_ord_nm,
sls_prd_key,
sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_ord_nm IS NULL OR sls_cust_id IS NULL OR sls_prd_key IS NULL;

-- Check for invalid order dates (not stored as 8-digit YYYYMMDD)
SELECT
sls_order_dt
FROM bronze.crm_sales_details
WHERE LEN(sls_order_dt) != 8 OR sls_order_dt IS NULL;

SELECT
*
FROM bronze.crm_sales_details
WHERE LEN(sls_order_dt) != 8;

-- Check raw sales, quantity, price values
SELECT 
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details;

-- Check rows where sls_sales does not equal price * quantity, and
-- preview the correction logic used in load_silver.sql
SELECT 
sls_sales,
sls_quantity,
sls_price,
CASE
	WHEN sls_sales != sls_price * sls_quantity OR sls_sales IS NULL OR sls_sales <= 0 THEN ABS(sls_price) * sls_quantity
	ELSE sls_sales
END sales,
CASE
	WHEN sls_price IS NULL OR sls_price <= 0 THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
	ELSE sls_price
END price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity;

-- Check distinct quantity values
SELECT DISTINCT sls_quantity FROM bronze.crm_sales_details;

SELECT * FROM silver.crm_sales_details;
