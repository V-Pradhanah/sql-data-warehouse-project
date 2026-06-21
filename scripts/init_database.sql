/*
========================================================
Create Database and Schemas
========================================================
Script Purpose:
	This script creates a database named  'DataWarehouse' after checking if it already exists
	Additionally, the script sets up three schemas within the database: 'bronze','silver', and 'gold'

WARNING:
	As this script will permanently delete all data in the database, ensure you have proper backups before runing this script.

*/


--Switching to system default database
USE master;
GO

--Checking if Database with the name 'DataWarehouse' already exists, 
--if  exists, drop and recreate DATABASE 'DataWarehouse'
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--Create the database 'DataWarehouse'
CREATE DATABASE DataWarehouse;
GO

--Switching to database 'DataWarehouse'
USE DataWarehouse;
GO

--Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
