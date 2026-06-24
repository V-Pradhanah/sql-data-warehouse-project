/*
QUALITY CHECKS

Script Purpose:
	This script performs quality checks to validate the accuracy and consistency 
	of the Gold Layer.
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================
-- Check for Uniqueness of Customer Key in gold.dim_customers
-- Expectation: No results 
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- ====================================================================
-- Checking 'gold.dim_products'
-- ====================================================================
-- Check for Uniqueness of Product Key in gold.dim_products
-- Expectation: No results 
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- ====================================================================
-- Checking 'gold.fact_sales'
-- ====================================================================
--Fact Check
----Check if all dimension tables can successfully join with the fact table after integration
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_products dp
ON f.product_key = dp.product_key
LEFT JOIN gold.dim_customers dc
ON f.customer_key = dc.customer_key
WHERE dp.product_key IS NULL OR dc.customer_key IS NULL;
