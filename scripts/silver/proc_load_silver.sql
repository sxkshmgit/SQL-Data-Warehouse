/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================

Script Purpose:

    This stored procedure performs the ETL (Extract, Transform, Load) process
    to populate the 'silver' schema tables from the 'bronze' schema.

Actions Performed:

    - Extracts raw data from Bronze tables.
    - Cleans and transforms source data.
    - Standardizes formats and resolves data quality issues.
    - Loads transformed data into Silver tables.
    - Tracks load duration for each transformation process.
    - Handles errors using TRY...CATCH blocks.

Parameters:

    None.

    This stored procedure does not accept parameters or return values.

Usage Example:

    EXEC silver.load_silver;

===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver as 
begin
DECLARE @START_TIME  DATETIME, @END_TIME DATETIME;
BEGIN TRY



PRINT '============LOADING silver.crm_cst_info============'


PRINT '>> truncating table ' ;
TRUNCATE TABLE  silver.crm_cst_info;
PRINT '>> inserting data in table ' ;
SET @START_TIME = GETDATE();


insert into silver.crm_cst_info 
( cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gender,
cst_create_date

)


select  
cst_id,
cst_key,
trim (cst_firstname) as cst_firstname,
trim (cst_lastname) as cst_lastname,

case when UPPER (trim (cst_marital_status) )= 'S' then 'Single'
when upper(trim	 (cst_marital_status)) = 'M' then 'Married'
end cst_marital_status,


case when UPPER (trim (cst_gender) )= 'F' then 'Female'
when upper(trim	 (cst_gender)) = 'M' then 'Male'
end cst_gender,

cst_create_date
from (
select *,
ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last

from bronze.crm_cst_info
) 
   t where flag_last = 1 
SET @END_TIME = GETDATE();

 PRINT '>> LOAD DURATION: ' + CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS'
PRINT'-----------------------------------------------------'

PRINT '============LOADING silver.crm_prd_info ============'


  PRINT '>> truncating table ' ;
TRUNCATE TABLE silver.crm_prd_info;
PRINT '>> inserting data in table ' ;

SET @START_TIME = GETDATE();
INSERT INTO silver.crm_prd_info (
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
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    
    CASE
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountains'
        ELSE 'unknown'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) - 1 AS DATE
    ) AS prd_end_dt

FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY
                   prd_id,
                   prd_key,
                   prd_nm,
                   prd_cost,
                   prd_line,
                   prd_start_dt,
                   prd_end_dt
               ORDER BY prd_id
           ) AS rn
    FROM bronze.crm_prd_info
) t

WHERE rn = 1
  AND SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN (
      SELECT sls_prd_key
      FROM bronze.crm_sales_details
  );


  select * from bronze.crm_sales_details
  WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info) 

  SET @END_TIME = GETDATE();

   PRINT '>> LOAD DURATION: ' + CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS'
PRINT'-----------------------------------------------------'



  PRINT '============LOADING silver.crm_sales_details  ============'



    PRINT '>> truncating table ' ;
TRUNCATE TABLE silver.crm_sales_details ;
PRINT '>> inserting data in table ' ;
SET @START_TIME = GETDATE();

INSERT INTO silver.crm_sales_details
(
    sls_ord_nmb,
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
    sls_ord_nmb,
    sls_prd_key,
    sls_cust_id,

    CASE
        WHEN sls_order_dt = 0
             OR LEN(sls_order_dt) != 8
        THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,

    CASE
        WHEN sls_ship_dt = 0
             OR LEN(sls_ship_dt) != 8
        THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,

    CASE
        WHEN sls_due_dt = 0
             OR LEN(sls_due_dt) != 8
        THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,

    CASE
        WHEN sls_sales IS NULL
             OR sls_sales <= 0
             OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    CASE
        WHEN sls_price IS NULL
             OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY
                   sls_ord_nmb,
                   sls_prd_key,
                   sls_cust_id,
                   sls_order_dt,
                   sls_ship_dt,
                   sls_due_dt,
                   sls_sales,
                   sls_quantity,
                   sls_price
               ORDER BY sls_ord_nmb
           ) AS rn
    FROM bronze.crm_sales_details
) duplicates

WHERE rn = 1;
 SET @END_TIME = GETDATE();
 PRINT '>> LOAD DURATION: ' + CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS'
PRINT'-----------------------------------------------------'


 PRINT '============LOADING silver.erp_cust_az12 ============'


PRINT '>> truncating table ' ;
TRUNCATE TABLE  silver.erp_cust_az12;
PRINT '>> inserting data in table ' ;

SET @START_TIME = GETDATE();

INSERT INTO silver.erp_cust_az12
(
cid,
bdate,
gen

)
SELECT 

CASE WHEN cid  like 'nas%'then SUBSTRING (cid,4 , len(cid))
else cid
end as cid ,

CASE WHEN bdate > GETDATE () then null 
else bdate
END AS bdate,


CASE WHEN (TRIM (gen)) IN ('f' , 'Female') THEN 'Female'
WHEN (TRIM (gen)) IN ('m' , 'Male') THEN 'Male'
else 'n/a'
END AS gen 

FROM bronze.erp_cust_az12

 SET @END_TIME = GETDATE();
 PRINT '>> LOAD DURATION: ' + CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS'
PRINT'-----------------------------------------------------'

PRINT '============LOADING silver.erp_loc_a101 ============'

PRINT '>> truncating table ' ;
TRUNCATE TABLE silver.erp_loc_a101 ;
PRINT '>> inserting data in table ' ;
SET @START_TIME = GETDATE();

;WITH cleaned AS (
    SELECT 
        REPLACE(cid, '-', '') AS cid,

        CASE 
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'

            WHEN TRIM(cntry) IN ('US', 'USA') 
                THEN 'United States'

            WHEN TRIM(cntry) = '' OR cntry IS NULL  
                THEN 'n/a'

            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101
),

cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY cid, cntry
               ORDER BY cid
           ) AS rn
    FROM cleaned
)

INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)

SELECT 
    cid,
    cntry
FROM cte
WHERE rn = 1;

 SET @END_TIME = GETDATE();
 PRINT '>> LOAD DURATION: ' + CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS'
PRINT'-----------------------------------------------------'

PRINT '============LOADING silver.erp_px_cat_g1v2 ============'



PRINT '>> truncating table ' ;
TRUNCATE TABLE silver.erp_px_cat_g1v2;
PRINT '>> inserting data in table ' ;

SET @START_TIME = GETDATE();

;WITH cleaned AS (

    SELECT 
        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat_g1v2
),

cte AS (

    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   id,
                   cat,
                   subcat,
                   maintenance
               ORDER BY id
           ) AS rn
    FROM cleaned
)

INSERT INTO silver.erp_px_cat_g1v2 (
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
FROM cte
WHERE rn = 1;

 SET @END_TIME = GETDATE();
 PRINT '>> LOAD DURATION: ' + CAST ( DATEDIFF(SECOND , @START_TIME , @END_TIME) AS NVARCHAR ) + 'SECONDS'
PRINT'-----------------------------------------------------'

 END TRY
      BEGIN CATCH

      PRINT '===================================================';
      PRINT'ERROR OCCURED IN ETL';
      PRINT'ERROR MESSAGE: '+ ERROR_MESSAGE();
      PRINT 'ERROR MESSAGE: '+ CAST (ERROR_NUMBER()AS NVARCHAR );
      PRINT 'ERROR MESSAGE: '+ CAST (ERROR_STATE()AS NVARCHAR );
      PRINT '====================================================';
      END CATCH
      END
--took me 3 days to do this im dedd ---






