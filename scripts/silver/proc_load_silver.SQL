/*
***********************************************************************
Stored Procedure: Load the Data to the Silver Layer in ETL Process
***********************************************************************
	This stored procedure loads data from the bronze layer (bronze schema) to the 
	tables created in silver schema in Database DataWarehouse
		It performs the following actions;
			1.Truncates the Target Table to avoid Duplicates.
			2.Transforms data (data cleansing and data transformation) before loading data.
			3.Calculates the load duration for each table and the whole batch.

--Parameters:
	None
	This script does not accept any arguments from the user and does not return any value.

--Usage Example:
	Ensure you are in the Right Database 'DataWarehouse'
		EXEC silver.load_silver;
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	BEGIN TRY 

	SET @batch_start_time  = GETDATE();
	PRINT '................................................................................';
	PRINT '.....................Loading Silver Layer.......................................';
	PRINT '................................................................................';

	PRINT '================================================================================';
	PRINT '                        Loading CRM Tables                                      ';
	PRINT '================================================================================';

	--silver_crm_cust_info	
	SET @start_time = GETDATE();
	PRINT '>>  Truncating table: silver.crm_cust_info <<';
	TRUNCATE TABLE silver.crm_cust_info;
	PRINT '>>  Inserting data into : silver.crm_cust_info <<';
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
		TRIM(cst_firstname) AS cst_firstname,  --Removing blank spaces in string values using TRIM function
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			 ELSE 'n/a'  --Mapping values of low cardinality columns to expanded values rather than abbrevated values
		END AS cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
			 WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			 ELSE 'n/a'
		END AS cst_gndr,
		cst_create_date
	FROM(
		SELECT *,
			ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS  flag_last --Selecting only rows where Primary Key is NOT NULL
																							   --and removing duplicate records by keeping only the most recent
																							   --entry per customer 
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL
	)t
	WHERE flag_last = 1 ;

	SET @end_time = GETDATE();

	PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time , @end_time) AS NVARCHAR) + ' seconds';
	
	--silver.crm_prd_info
	SET @start_time = GETDATE();

	PRINT '>>  Truncating table: silver.crm_prd_info <<';
	TRUNCATE TABLE silver.crm_prd_info;
	PRINT '>>  Inserting data into : silver.crm_prd_info <<';
	INSERT INTO silver.crm_prd_info(
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
		REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
		SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
		prd_nm,
		COALESCE(prd_cost,0) AS prd_cost,
		CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN  'Mountain'
			 WHEN UPPER(TRIM(prd_line)) = 'R' THEN  'Road'
			 WHEN UPPER(TRIM(prd_line)) = 'S' THEN	'Other Sales'
			 WHEN UPPER(TRIM(prd_line)) = 'T' THEN	'Touring'
			 ELSE 'n/a'
		END AS prd_line,
		CAST(prd_start_dt AS DATE) AS prd_start_dt,
		CAST((LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt ASC) - 1) AS DATE) AS prd_end_dt
	FROM bronze.crm_prd_info;

	SET @end_time = GETDATE();

	
	PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time , @end_time) AS NVARCHAR) + ' seconds';
	
	--silver.crm_sales_details
	SET @start_time = GETDATE();
	PRINT '>>  Truncating table: silver.crm_sales_details <<';
	TRUNCATE TABLE silver.crm_sales_details;
	PRINT '>>  Inserting data into : silver.crm_sales_details <<';
	INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt, --Handling invalid data - checking if any date column values like order_date, ship_date and due_date has invalid data
							 --and casting it to the correct datatype

		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,

		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,

		CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != ABS(sls_price) * sls_quantity
			THEN ABS(sls_price) * sls_quantity
			ELSE sls_sales
		END AS sls_sales,

		sls_quantity,

		CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / ABS(sls_quantity)
			 ELSE sls_price
		END AS sls_price  --Data enrichment - sls_sales - handling invalid and missing data by deriving information from existing columns.
	FROM bronze.crm_sales_details;

	SET @end_time = GETDATE();
	
	PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time , @end_time) AS NVARCHAR) + ' seconds';

	PRINT '================================================================================';
	PRINT '                        Loading ERP Tables                                      ';
	PRINT '================================================================================';

	--silver.erp_cust_az12
	SET @start_time = GETDATE();

	PRINT '>>  Truncating table: silver.erp_cust_az12 <<';
	TRUNCATE TABLE silver.erp_cust_az12;
	PRINT '>>  Inserting data into : silver.erp_cust_az12 <<';
	INSERT INTO silver.erp_cust_az12 (
		cid,			
		bdate,				
		gen				
	) 
	SELECT 
		CASE WHEN TRIM(cid) LIKE 'NAS%' THEN SUBSTRING(TRIM(cid),4,LEN(TRIM(cid))) ELSE TRIM(cid) END AS cid, --Remove 'NAS' prefix if present 
		CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate, --Set future brithdates to NULL 
		CASE WHEN UPPER(TRIM(gen)) IN  ('M','MALE')  THEN 'Male'
			 WHEN UPPER(TRIM(gen)) IN  ('F','FEMALE') THEN 'Female'
			 ELSE 'n/a'
		END AS gen	--normalise gender values and handle unknown cases 
	FROM bronze.erp_cust_az12;

	SET @end_time = GETDATE();

	PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time , @end_time) AS NVARCHAR) + ' seconds';


	--silver.erp_loc_a101
	SET @start_time = GETDATE();
	PRINT '>>  Truncating table: silver.erp_loc_a101 <<';
	TRUNCATE TABLE silver.erp_loc_a101;
	PRINT '>>  Inserting data into : silver.erp_loc_a101 <<';
	INSERT INTO silver.erp_loc_a101 (
		cid,
		cntry
	)
	SELECT 
		REPLACE(cid,'-','') AS cid,  --Handled invalid value '-' 
		CASE WHEN TRIM(cntry) in ('US','USA')THEN 'United States'
			 WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			 ELSE TRIM(cntry)
		END AS cntry -- Data Normalization and handled missing and blank country codes
	FROM bronze.erp_loc_a101;

	SET @end_time = GETDATE();

	PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time , @end_time) AS NVARCHAR) + ' seconds';

	-- silver.erp_px_cat_g1v2
	SET @start_time = GETDATE();
	PRINT '>>  Truncating table: silver.erp_px_cat_g1v2 <<';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	PRINT '>>  Inserting data into : silver.erp_px_cat_g1v2 <<';
	INSERT INTO silver.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
	)
	SELECT 
		id,
		cat,
		subcat,
		maintenance
	FROM bronze.erp_px_cat_g1v2;

	SET @end_time = GETDATE();

	PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time , @end_time) AS NVARCHAR) + ' seconds';

	SET @batch_end_time  = GETDATE();

	PRINT '*******************************************************************************************';
	PRINT 'Batch Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time , @batch_end_time) AS NVARCHAR) + ' seconds';
	PRINT '*******************************************************************************************';

	END TRY

	BEGIN CATCH 

	PRINT '====================================================================================';
	PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
	PRINT 'Error Message: ' + ERROR_MESSAGE();
	PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
	PRINT '====================================================================================';

	END CATCH
END
