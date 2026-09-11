/*
    Script: ddl_gold_dim_customers.sql
    Purpose: Creates the gold.dim_customers view. Merges cleaned CRM
             customer data with ERP birthdate/gender and country data,
             and generates a surrogate key (customer_key).

    How to run:
    1. Run silver.load_silver at least once first, so Silver has data.
    2. Execute this script to create the view. Views read live from
       Silver, so no reload step is needed after this — querying the
       view always reflects the current Silver data.
*/

CREATE VIEW gold.dim_customers AS (
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	cci.cst_id AS customer_id,
	cci.cst_key AS customer_number,
	cci.cst_firstname AS first_name,
	cci.cst_lastname AS last_name,
	cci.cst_marital_status AS marital_status,
	CASE
		WHEN cci.cst_gndr != 'Unknown' THEN cci.cst_gndr -- cci is the master table
		ELSE COALESCE(eca.gen, 'Unknown')
	END AS gender,
	eca.bdate AS birth_date,
	ela.cntry AS country,
	cci.cst_create_date AS create_date
FROM silver.crm_cust_info cci
LEFT JOIN silver.erp_cust_az12 eca
ON cci.cst_key = eca.cid
LEFT JOIN silver.erp_loc_a101 ela
ON cci.cst_key = ela.cid
);

-- Sanity check after creating the view (optional, not part of the DDL):
-- SELECT * FROM gold.dim_customers;
