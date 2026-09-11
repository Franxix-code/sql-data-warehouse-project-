/*
    Script: ddl_gold_dim_products.sql
    Purpose: Creates the gold.dim_products view. Merges cleaned CRM
             product data with ERP category/subcategory data, generates
             a surrogate key (product_key), and keeps only the current
             version of each product (prd_end_dt IS NULL).

    How to run:
    1. Run silver.load_silver at least once first, so Silver has data.
    2. Execute this script to create the view. Views read live from
       Silver, so no reload step is needed after this — querying the
       view always reflects the current Silver data.
*/

CREATE VIEW gold.dim_products AS (
SELECT
	ROW_NUMBER() OVER (ORDER BY cpi.prd_start_dt, cpi.prd_id) AS product_key, 
	cpi.prd_id AS product_id,
	cpi.cat_id AS category_id,
	cpi.prd_key AS product_number,
	epcg.cat AS category,
	epcg.subcat AS subcategory,
	cpi.prd_nm AS product_name,
	cpi.prd_line AS product_line,
	cpi.prd_cost AS cost,
	epcg.maintenance AS maintenance,
	cpi.prd_start_dt AS product_start_date
	FROM silver.crm_prd_info cpi
LEFT JOIN silver.erp_px_cat_g1v2 epcg
ON cpi.cat_id = epcg.id
WHERE cpi.prd_end_dt IS NULL -- filter out historical data
);

-- Sanity check after creating the view (optional, not part of the DDL):
-- SELECT * FROM gold.dim_products;
