/*
    Script: init_database.sql
    Purpose: Creates the DWH database and the three Medallion architecture
             schemas (bronze, silver, gold) used throughout this project.

    How to run:
    1. Open this script in SQL Server Management Studio (SSMS), connected
       to your target SQL Server instance.
    2. Execute the entire script (F5). It must run first, before any
       Bronze/Silver/Gold table or procedure scripts.
    3. WARNING: If a database named DWH already exists on your instance,
       this script does not drop or check for it, and CREATE DATABASE will
       fail. Rename the database in this script, or drop the existing DWH
       database first, before running.
*/

USE MASTER;

CREATE DATABASE DWH;
GO

USE DWH;

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
