/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================

This script creates views for the Gold Layer in the Data Warehouse.
The Gold layer represents the final dimension and fact tables (Star Schema)

Each View performs data transformations and combines tables from the silver layer to 
to create business ready dataset  optimized for analytics and reporting

Usage: 
	-These views can be queried directly for analytics and reporting
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers','V') IS NOT NULL
	DROP gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
SELECT 
	ROW_NUMBER() OVER(ORDER BY ci.cst_id ASC)               AS customer_key,
	ci.cst_id												AS customer_id,
	ci.cst_key												AS customer_number,
	ci.cst_firstname										AS first_name,
	ci.cst_lastname											AS last_name,
	cl.cntry												AS country,
	ci.cst_marital_status									AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr  --CRM is the primary source for gender  --Data Integration
		 ELSE COALESCE(ca.gen,'n/a')                 --fallback to ERP when gender not available in CRM
	END														AS gender,
	ca.bdate												AS birthdate,
	ci.cst_create_date										AS create_date
	
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS cl
ON ci.cst_key = cl.cid;

GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products','V') IS NOT NULL
	DROP gold.dim_products;
GO


CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY pc.prd_start_dt,pc.prd_key) AS product_key,
	pc.prd_id            AS product_id,
	pc.prd_key           AS product_number,
	pc.prd_nm            AS product_name,
	pc.cat_id			 AS category_id,
	pe.cat				 AS category,
	pe.subcat			 AS subcategory,
	pe.maintenance ,
	pc.prd_cost			 AS cost,
	pc.prd_line			 AS product_line,
	pc.prd_start_dt		 AS start_date  --Sorting the prd_start_date for each prd_key to get only the recent record
FROM silver.crm_prd_info AS pc
LEFT JOIN silver.erp_px_cat_g1v2 AS pe
ON pc.cat_id = pe.id
WHERE pc.prd_end_dt IS  NULL;   --filter out all historical data --excluding prd_end_dt as it is always NULL

GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID(' gold.fact_sales','V') IS NOT NULL
	DROP  gold.fact_sales;
GO


--Building Fact
----Use the dimension's surrogate key instead of IDs to easily connect facts with dimensions

CREATE VIEW gold.fact_sales AS
SELECT
	csa.sls_ord_num AS order_number,
	dp.product_key,
	dc.customer_key,
	csa.sls_order_dt AS order_date,
	csa.sls_ship_dt  AS shipping_date,
	csa.sls_due_dt AS due_date,
	csa.sls_sales AS sales_amount,
	csa.sls_quantity AS quantity,
	csa.sls_price AS price
FROM silver.crm_sales_details AS csa
LEFT JOIN gold.dim_products AS dp
ON csa.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers AS dc
ON csa.sls_cust_id = dc.customer_id;

GO
