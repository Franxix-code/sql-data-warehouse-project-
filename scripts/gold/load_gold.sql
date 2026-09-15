/*
    Script: load_gold.sql
    Purpose: Creates (or replaces) the gold.load_gold stored procedure,
             which truncates and reloads all three Gold tables from
             Silver, generating surrogate keys and merging CRM/ERP data
             into the star schema.

    How to run:
    1. Run silver.load_silver at least once first, so Silver has data.
    2. Run ddl_gold.sql to create the Gold tables.
    3. Execute this script once to create the procedure.
    4. Re-run with: EXEC gold.load_gold;
       Truncate-and-reload makes this safe to re-run any number of times
       without producing duplicate rows.

    Note: unlike a view, this table-based Gold layer does not update
    automatically when Silver changes. Re-run EXEC gold.load_gold after
    any Silver reload to keep Gold in sync:
        EXEC bronze.load_bronze;
        EXEC silver.load_silver;
        EXEC gold.load_gold;
*/

CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
DECLARE @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '===================================================';
		PRINT 'LOADING GOLD LAYER';
		PRINT '===================================================';


		PRINT '---------------------------------------------------';
		PRINT 'Loading dim_customers Table';
		PRINT '---------------------------------------------------';
		-- Loading gold.dim_customers
		SET @start_time = GETDATE();
		PRINT 'Truncating table gold.dim_customers';
		TRUNCATE TABLE gold.dim_customers;
		PRINT 'Inserting data into gold.dim_customers table';
		INSERT INTO gold.dim_customers (
			customer_key,
			customer_id,
			customer_number,
			first_name,
			last_name,
			marital_status,
			gender,
			birthdate,
			country,
			create_date
		)
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
			eca.bdate AS birthdate,
			ela.cntry AS country,
			cci.cst_create_date AS create_date
		FROM silver.crm_cust_info cci
		LEFT JOIN silver.erp_cust_az12 eca
		ON cci.cst_key = eca.cid
		LEFT JOIN silver.erp_loc_a101 ela
		ON cci.cst_key = ela.cid;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		-- Loading gold.dim_products
		SET @start_time = GETDATE();
		PRINT 'Truncating table gold.dim_products';
		TRUNCATE TABLE gold.dim_products;
		PRINT 'Inserting data into gold.dim_products table';
		INSERT INTO gold.dim_products (
			product_key,
			product_id,
			category_id,
			product_number,
			category,
			subcategory,
			product_name,
			product_line,
			cost,
			maintenance,
			product_start_date
		)
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
		WHERE cpi.prd_end_dt IS NULL; -- filter out historical data
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		-- Loading gold.fact_sales
		SET @start_time = GETDATE();
		PRINT 'Truncating table gold.fact_sales';
		TRUNCATE TABLE gold.fact_sales;
		PRINT 'Inserting data into gold.fact_sales table';
		INSERT INTO gold.fact_sales (
			order_number,
			product_key,
			customer_key,
			orderdate,
			shipdate,
			duedate,
			price,
			quantity,
			sales
		)
		SELECT
			csd.sls_ord_nm AS order_number,
			gdp.product_key,
			gdc.customer_key,
			csd.sls_order_dt AS orderdate,
			csd.sls_ship_dt AS shipdate,
			csd.sls_due_dt AS duedate,
			csd.sls_price AS price,
			csd.sls_quantity AS quantity,
			csd.sls_sales AS sales
		FROM silver.crm_sales_details csd
		LEFT JOIN gold.dim_customers gdc
		ON csd.sls_cust_id = gdc.customer_id
		LEFT JOIN gold.dim_products gdp
		ON csd.sls_prd_key = gdp.product_number;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		SET @batch_end_time = GETDATE();
		PRINT '===================================================';
		PRINT 'Gold Layer Load Completed.';
		PRINT '	Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '===================================================';
	END TRY
	BEGIN CATCH
		PRINT '===================================================';
		PRINT 'ERROR OCCURRED DURING LOADING GOLD LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT '===================================================';
	END CATCH
END
