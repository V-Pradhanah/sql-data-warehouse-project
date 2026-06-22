/*
***********************************************************************
Stored Procedure: Load the Data to the Bronze Layer in ETL Process
***********************************************************************
	This stored procedure loads data from the source system files (csv format) to the 
	tables created in bronze schema in Database DataWarehouse
		It performs the following actions;
			1.Truncates the Target Table to avoid Duplicates.
			2.Uses the 'BULK INSERT' command to fully load the data from csv files.
			3.Calculates the load duration for each table and the whole batch.

--Parameters:
	None
	This script does not accept any arguments from the user and does not return any value.

--Usage Example:
	Ensure you are in the Right Database 'DataWarehouse'
		EXEC bronze.load_bronze;
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=====================================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '=====================================================================';

		PRINT '---------------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------------------------------------';
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.crm_cust_info <<';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data into: bronze.crm_cust_info <<';
		BULK INSERT [bronze].[crm_cust_info] 
		FROM 'D:\SQL Projects with Baraa\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>  Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time)  AS NVARCHAR) + ' seconds  <<';
		PRINT '.......................................................';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info <<';
		TRUNCATE TABLE [bronze].[crm_prd_info];

		PRINT '>> Inserting Data into: bronze.crm_prd_info  <<';
		BULK INSERT [bronze].[crm_prd_info] 
		FROM 'D:\SQL Projects with Baraa\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>  Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) AS NVARCHAR) + ' seconds  <<';
		PRINT '...............................................';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details <<';
		TRUNCATE TABLE [bronze].[crm_sales_details];

		PRINT '>> Inserting Data into: bronze.crm_sales_details <<';
		BULK INSERT [bronze].[crm_sales_details] 
		FROM 'D:\SQL Projects with Baraa\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>  Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) AS NVARCHAR) + ' seconds  <<';
		PRINT '...............................................';

		PRINT('---------------------------------------------------------------------');
		PRINT('Loading ERP Tables');
		PRINT('---------------------------------------------------------------------');

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12 <<';
		TRUNCATE TABLE [bronze].[erp_cust_az12];

		PRINT '>> Inserting Data into: bronze.erp_cust_az12 <<';
		BULK INSERT [bronze].[erp_cust_az12]
		FROM 'D:\SQL Projects with Baraa\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>  Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) AS NVARCHAR) + ' seconds  <<';
		PRINT '...............................................';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101 <<';
		TRUNCATE TABLE [bronze].[erp_loc_a101];

		PRINT '>> Inserting Data into: bronze.erp_loc_a101 <<';
		BULK INSERT [bronze].[erp_loc_a101]
		FROM 'D:\SQL Projects with Baraa\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>  Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) AS NVARCHAR) + ' seconds  <<';
		PRINT '...............................................';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2 <<';
		TRUNCATE TABLE [bronze].[erp_px_cat_g1v2];

		PRINT '>> Inserting Data into: bronze.erp_px_cat_g1v2 <<';
		BULK INSERT [bronze].[erp_px_cat_g1v2]
		FROM 'D:\SQL Projects with Baraa\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>>  Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) AS NVARCHAR) + ' seconds  <<';
		PRINT '...............................................';

		SET @batch_end_time = GETDATE();
		PRINT '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^';
		PRINT 'Loading Bronze layer is Completed'
		PRINT '.... Batch Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds .....';
		PRINT '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^';

	END TRY

	BEGIN CATCH
	PRINT '==============================================================';
	PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
	PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
	PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
	PRINT '==============================================================';
	END CATCH
END


