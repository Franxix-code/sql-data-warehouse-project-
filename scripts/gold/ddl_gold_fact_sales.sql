/*
    Script: ddl_gold_fact_sales.sql
    Purpose: Creates the gold.fact_sales view, at one row per sales order
             line item, joined to the surrogate keys of gold.dim_customers
             and gold.dim_products.

    How to run:
    1. Run ddl_gold_dim_customers.sql and ddl_gold_dim_products.sql first
       — this view joins to both of them by their surrogate keys, so
       they must exist before this script is run.
    2. Execute this script to create the view. Views read live from
       Silver/Gold, so no reload step is needed after this — querying
       the view always reflects the current underlying data.
*/

CREATE VIEW gold.fact_sales AS (
SELECT
	csd.sls_ord_nm AS order_number,
	gdp.product_key,
	gdc.customer_key,
	csd.sls_order_dt AS order_date,
	csd.sls_ship_dt AS ship_date,
	csd.sls_due_dt AS due_date,
	csd.sls_price AS price,
	csd.sls_quantity AS quantity,
	csd.sls_sales AS sales
FROM silver.crm_sales_details csd
LEFT JOIN gold.dim_customers gdc
ON csd.sls_cust_id = gdc.customer_id
LEFT JOIN gold.dim_products gdp
ON csd.sls_prd_key = gdp.product_number
);

-- Sanity check after creating the view (optional, not part of the DDL):
-- SELECT * FROM gold.fact_sales;
