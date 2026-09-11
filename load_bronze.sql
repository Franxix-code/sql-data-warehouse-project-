/*
    Script: load_bronze.sql
    Purpose: Creates (or replaces) the bronze.load_bronze stored procedure,
             which truncates and reloads all six Bronze tables from their
             source CSV files, with per-table timing and error handling.

    How to run:
    1. Run init_database.sql and ddl_bronze.sql first.
    2. Update the six file paths below (FROM '...') to match where you
       cloned this repo's /datasets folder on your own machine. As
       written, the paths are local to the original author's machine and
       will fail on any other system.
    3. Execute this script once to create the procedure.
    4. Re-run with: EXEC bronze.load_bronze;
       Truncate-and-reload makes this safe to re-run any number of times
       without producing duplicate rows.
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
DECLARE @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '===================================================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '===================================================';


		PRINT '---------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------------------';
		-- Loading bronze.crm_cust_info
		SET @start_time = GETDATE();
		PRINT 'Truncating table bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT 'Inserting data into bronze.crm_cust_info table';
		BULK INSERT bronze.crm_cust_info 
		FROM 'C:\Users\hp\Desktop\Data Warehouse Project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		-- Loading bronze.crm_prd_info
		SET @start_time = GETDATE();
		PRINT 'Truncating table bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT 'Inserting data into bronze.crm_prd_info table';
		BULK INSERT bronze.crm_prd_info 
		FROM 'C:\Users\hp\Desktop\Data Warehouse Project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		-- Loading bronze.crm_sales_details
		SET @start_time = GETDATE();
		PRINT 'Truncating table bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT 'Inserting data into bronze.crm_sales_details table';
		BULK INSERT bronze.crm_sales_details 
		FROM 'C:\Users\hp\Desktop\Data Warehouse Project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		PRINT '---------------------------------------------------';
		PRINT 'CRM Tables Load Completed';
		PRINT '---------------------------------------------------';

		PRINT '---------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------------------------';

		-- Loading bronze.erp_cust_az12
		SET @start_time = GETDATE();
		PRINT 'Truncating table bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT 'Inserting data into bronze.erp_cust_az12 table';
		BULK INSERT bronze.erp_cust_az12 
		FROM 'C:\Users\hp\Desktop\Data Warehouse Project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		-- Loading bronze.erp_loc_a101
		SET @start_time = GETDATE();
		PRINT 'Truncating table bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT 'Inserting data into bronze.erp_loc_a101 table';
		BULK INSERT bronze.erp_loc_a101 
		FROM 'C:\Users\hp\Desktop\Data Warehouse Project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		-- Loading bronze.erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT 'Truncating table bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT 'Inserting data into bronze.erp_px_cat_g1v2 table';
		BULK INSERT bronze.erp_px_cat_g1v2 
		FROM 'C:\Users\hp\Desktop\Data Warehouse Project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>> Load Duration : ' + CAST((DATEDIFF(SECOND, @start_time, @end_time)) AS NVARCHAR) + ' seconds';
		PRINT '------------------';

		PRINT '---------------------------------------------------';
		PRINT 'ERP Tables Load Completed';
		PRINT '---------------------------------------------------';

		SET @batch_end_time = GETDATE();
		PRINT '===================================================';
		PRINT 'Bronze Layer Load Completed.';
		PRINT '	Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '===================================================';
	END TRY
	BEGIN CATCH
		PRINT '===================================================';
		PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT '===================================================';
	END CATCH
END
