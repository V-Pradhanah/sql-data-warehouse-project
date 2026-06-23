/*
The purpose of this script is to check the  quality of data 
in bronze layer tables  before loading data into silver layer
	These  queries can be used to validate data after inserting data into 
	the silver layer tables by switching the schema from bronze to silver
*/
--////////////////////////////////////////////////////////////////////////////////////////////
--bronze.crm_cust_info ...............to............................. silver.crm_cust_info

--Check for Nulls and Duplicates in Primary Key
-----Expectation: No Result

SELECT 
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

--Check for unwanted spaces in string values
SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

--Check the consistency of values in low cardinality columns
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

--//////////////////////////////////////////////////////////////////////////////////////////////////
--bronze.crm_prd_info ......................... to ..............................silver.crm_prd_info

--Checking for duplicates and nulls in primary key
SELECT 
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

--Checking for any blank spaces in string value
SELECT 
	prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

--Check for NULLS and Negative numbers in Cost column 
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;

--Getting distinct values in low cardinality columns in order to map them to expanded values rather than abbrevation
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

--Checking for records where end date occurs before start date (data quality issue)
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

--//////////////////////////////////////////////////////////////////////////////////////////////////
--bronze.crm_sales_details ...............to...................silver.crm_sales_details

--Checking for unwanted spaces in string value 
SELECT sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

--Checking if  customer id in sales details table is present in customer id in silver.crm_cust_info
SELECT *
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT DISTINCT cst_id FROM silver.crm_cust_info);

/*
  Checking if any order_dt,ship_dt, due_dt values are 
	lesser than or equal to 0 OR
	length of order_dt not equal to 8 OR
	if any outlier date is present
  before casting it as an date
*/
SELECT
	sls_due_dt,
	NULLIF(sls_due_dt,0)
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 OR LEN(sls_due_dt) != 8  OR sls_due_dt > 20250101 OR sls_due_dt < 19000101;


--Check if any order date is greater than shipdate or due date
SELECT 
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

/*
Checking for any negative values or zeroes in quantity,price and sales 
Also checking if all sales values follows business rule
		Business rule Sales = Quantity * Price
		Negatives, zeroes and NULLs are not allowed
*/
SELECT DISTINCT 
	sls_sales ,
	sls_price ,
	sls_quantity
FROM bronze.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity 
OR
sls_sales IS NULL OR sls_price IS NULL OR sls_quantity IS NULL 
OR
sls_sales <= 0  OR sls_price <= 0  OR sls_quantity <= 0 
ORDER BY sls_sales,sls_quantity,sls_price;

--//////////////////////////////////////////////////////////////////////////////////////////////////
--bronze.erp_cust_az12..............to.....................silver.erp_cust_az12

--checking for unwanted spaces in string value
SELECT cid FROM bronze.erp_cust_az12 WHERE TRIM(cid) != cid;

--checking if cid in bronze.erp_cust_az12 is present in cst_key of silver.crm_cust_info
SELECT *
FROM  bronze.erp_cust_az12 
WHERE cid NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info); --found extra characters 'NAS' in cid which prevents match between cid and csk_key of  silver.crm_cust_info

--checking for any outliers in bdate 
SELECT * FROM bronze.erp_cust_az12 WHERE bdate < '1926-01-01' OR bdate > GETDATE();

--Checking the consistency of data in low cardinality column gen(gender)
SELECT DISTINCT gen  FROM bronze.erp_cust_az12; --found NULL, Empty string, both abbrevated and expanded value which has to be standardised before loading data


--//////////////////////////////////////////////////////////////////////////////////////////////////
--bronze.erp_loc_a101...................to............................silver.erp_loc_a101

--Checking if cid in bronze.erp_loc_a101 matches cst_key in silver.crm_cust_info
SELECT * FROM bronze.erp_loc_a101 WHERE cid NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info); --found '-' between cid in bronze.erp_loc_a101 which is not present in silver.crm_cust_info

--Checking distinct values in low cardinality column cntry (country)
SELECT DISTINCT cntry FROM bronze.erp_loc_a101 ORDER BY cntry;


--//////////////////////////////////////////////////////////////////////////////////////////////////
--bronze.erp_px_cat_g1v2....................to.............................silver.erp_px_cat_g1v2

--Check for unwanted spaces in 	cat, subcat, maintenance
SELECT maintenance FROM bronze.erp_px_cat_g1v2 WHERE TRIM(maintenance) != maintenance;   -- no space found

--checking for consistencty in low cardinality columns
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;     --data is consistent , no missing values or NULL found
