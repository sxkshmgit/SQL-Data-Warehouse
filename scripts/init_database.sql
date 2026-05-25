/*
===============================================================================
Create Database and Schemas
===============================================================================

Script Purpose:

    This script creates a new database named 'DataWarehouse' and sets up
    the foundational schemas required for the data warehouse architecture.

    The following schemas are created:
    - bronze : Stores raw data ingested from source systems.
    - silver : Stores cleansed and transformed data.
    - gold   : Stores business-ready data optimized for analytics and reporting.

WARNING:

    Running this script will create the 'DataWarehouse' database.
    Ensure you have the necessary permissions before execution.

===============================================================================
*/

-- Switch to the system database
use master;

-- Create the DataWarehouse database
create DATABASE Datawarehouse;

-- Switch to the newly created database
use Datawarehouse;

-- Create Bronze schemas 
create schema bronze;
GO

create schema silver;
GO

create schema gold;
GO
