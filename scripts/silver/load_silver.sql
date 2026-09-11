/*
    Script: load_silver.sql
    Purpose: Creates (or replaces) the silver.load_silver stored procedure,
             which truncates and reloads all six Silver tables from Bronze,
             applying data cleaning, standardization, deduplication, and
             validation logic along the way.

    How to run:
    1. Run bronze.load_bronze at least once first, so Bronze has data.
    2. Run ddl_silver.sql to create the Silver tables.
    3. Execute this script once to create the procedure.
    4. Re-run with: EXEC silver.load_silver;
       Truncate-and-reload makes this safe to re-run any number of times
       without producing duplicate rows.
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '===================================================';
		PRINT 'LOADING SILVER LAYER';
		PRINT '===================================================';


		PRINT '---------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------------------';

		-- Loading silver.crm_cust_info
		SET @start_time = GETDATE();
		PRINT 'Truncating table silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE 
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			ELSE 'Unknown'
		END AS cst_marital_status,
		CASE 
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			ELSE 'Unknown'
		END AS cst_gndr,
		cst_create_date
		FROM (
		SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL
		) t
		WHERE flag_last = 1;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';


		-- Loading silver.crm_prd_info
		SET @start_time = GETDATE();
		PRINT 'Truncating table silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
		prd_id,
		SUBSTRING(prd_key, 1, 5) AS cat_id,
		SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
		prd_nm,
		ISNULL(prd_cost, 0) AS prd_cost,
		CASE
			WHEN prd_line = 'R' THEN 'Road'
			WHEN prd_line = 'T' THEN 'Tourist'
			WHEN prd_line = 'M' THEN 'Mountain'
			WHEN prd_line = 'S' THEN 'Other Sales'
			ELSE 'Unknown'
		END AS prd_line,
		prd_start_dt,
		DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
		FROM bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';


		-- Loading silver.crm_sales_details
		SET @start_time = GETDATE();
		PRINT 'Truncating table silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		INSERT INTO silver.crm_sales_details (
			sls_ord_nm,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_price,
			sls_quantity,
			sls_sales
		)
		SELECT 
		sls_ord_nm,
		sls_prd_key,
		sls_cust_id,
		CASE
			WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE)
		END AS  sls_order_dt,
		CASE
			WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE)
		END AS  sls_ship_dt,
		CASE
			WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE)
		END AS  sls_due_dt,
		CASE
			WHEN sls_price IS NULL OR sls_price <= 0 THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
			ELSE sls_price
		END AS sls_price,
		sls_quantity,
		CASE
			WHEN sls_sales != sls_price * sls_quantity OR sls_sales IS NULL OR sls_sales <= 0 THEN ABS(sls_price) * sls_quantity
			ELSE sls_sales
		END AS sls_sales
		FROM bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';


		PRINT '---------------------------------------------------';
		PRINT 'CRM Tables Load Completed';
		PRINT '---------------------------------------------------';


		PRINT '---------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------------------------';

		-- Loading silver.erp_cust_az12
		SET @start_time = GETDATE();
		PRINT 'Truncating table silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)
		SELECT
		CASE 
			WHEN cid LIKE 'N%' THEN SUBSTRING(cid, 4, LEN(cid))
			ELSE cid
		END cid,
		CASE	
			WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END AS bdate,
		CASE	
			WHEN gen IN ('F','Female') THEN 'Female'
			WHEN gen IN ('M', 'Male') THEN 'Male'
			ELSE 'Unknown'
		END AS gen
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';


		-- Loading silver.erp_loc_a101
		SET @start_time = GETDATE();
		PRINT 'Truncating table silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
		)
		SELECT 
		REPLACE(cid, '-', '') AS cid,
		CASE
			WHEN cntry = 'DE' THEN 'Germany'
			WHEN cntry IN ('USA','US') THEN 'United States'
			WHEN cntry IS NULL OR cntry = '' THEN 'Unknown'
			ELSE cntry
		END cntry
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';


		-- Loading silver.erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT 'Truncating table silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
		REPLACE(id, '_','-') AS id,
		cat,
		subcat,
		maintenance
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';


		PRINT '---------------------------------------------------';
		PRINT 'ERP Tables Load Completed';
		PRINT '---------------------------------------------------';


		SET @batch_end_time = GETDATE();
		PRINT '===================================================';
		PRINT 'Silver Layer Load Completed.';
		PRINT '	Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '===================================================';
	END TRY
	BEGIN CATCH
			PRINT '===================================================';
			PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
			PRINT 'Error Message: ' + ERROR_MESSAGE();
			PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
			PRINT '===================================================';
	END CATCH
END
