/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================

Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV
    files. It performs the following actions:

    - Loads CRM source files into bronze CRM tables.
    - Loads ERP source files into bronze ERP tables.
    - Uses the BULK INSERT command to import data from CSV files.
    - Captures and displays load duration for each table.
    - Implements TRY...CATCH error handling for ETL monitoring.

Parameters:
    None.

    This stored procedure does not accept any parameters or return any values.

                                   Usage Example:
   ============================ EXEC bronze.load_bronze;=============================

===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze as 
begin
DECLARE @START_TIME  DATETIME, @END_TIME DATETIME;
BEGIN TRY
print '=============================';
print 'loading the bronze layer';
print '=============================';
print '-------------------------';
print 'loading crm tables';
print '-------------------------';

SET @START_TIME = GETDATE();
print '>> inserting data into bronze.crm';

BULK INSERT bronze.crm_cst_info
FROM 'C:\Users\saksh\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK 
      );
 SET @END_TIME = GETDATE();
 PRINT '>> LOAD DURATION: ' + CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS'
PRINT'-----------------------------------------------------'


SET @START_TIME = GETDATE();
print '>> inserting data into bronze.crm_prd_info';
BULK INSERT bronze.crm_prd_info
FROM 'C:\Users\saksh\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK 
      );
     SET @END_TIME = GETDATE();  
     PRINT '>> LOAD DURATION: ' + CAST( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS';
PRINT'-----------------------------------------------------';


     SET @START_TIME = GETDATE();
     print '>> inserting data into bronze.crm_sales_details'; 
     BULK INSERT bronze.crm_sales_details
FROM 'C:\Users\saksh\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK 
      );
      SET @END_TIME = GETDATE();
       PRINT '>> LOAD DURATION: ' +CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS';
PRINT'-----------------------------------------------------';



  
print '-------------------------';
print 'loading erp tables';
print '-------------------------';


SET @START_TIME = GETDATE();

print '>> inserting data into bronze.erp_cust_az12';

    BULK INSERT bronze.erp_cust_az12
FROM 'C:\Users\saksh\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK 
      );
     SET @END_TIME = GETDATE();
     PRINT '>> LOAD DURATION: ' +CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS';
PRINT'-----------------------------------------------------';


 SET @START_TIME = GETDATE();

      print '>> inserting data into bronze.erp_loc_a101';


          BULK INSERT bronze.erp_loc_a101
FROM 'C:\Users\saksh\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK 
      );
       SET @END_TIME = GETDATE();
     PRINT '>> LOAD DURATION: ' +CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS';
PRINT'-----------------------------------------------------';


SET @START_TIME = GETDATE();


print '>> inserting data into bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
FROM 'C:\Users\saksh\OneDrive\Desktop\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK 
      );
       SET @END_TIME = GETDATE();
     PRINT '>> LOAD DURATION: ' +CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS';
PRINT'-----------------------------------------------------';

      END TRY
      BEGIN CATCH

      PRINT '===================================================';
      PRINT'ERROR OCCURED IN ETL';
      PRINT'ERROR MESSAGE'+ ERROR_MESSAGE();
      PRINT 'ERROR MESSAGE'+ CAST (ERROR_NUMBER()AS NVARCHAR );
      PRINT 'ERROR MESSAGE'+ CAST (ERROR_STATE()AS NVARCHAR );
      PRINT '====================================================';
      END CATCH
      end
