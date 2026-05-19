-- Data cleaning in SQL Server
--
-- Each row is a defective part logged on the production line.
-- I keep the raw import untouched and do the cleaning in a staging table.

SELECT *
FROM dbo.defects;


-- Create the staging table.
DROP TABLE IF EXISTS dbo.defects_staging;

SELECT *
INTO dbo.defects_staging
FROM dbo.defects
WHERE 1 = 0;

INSERT INTO dbo.defects_staging
SELECT * FROM dbo.defects;


-- 1. Check and remove duplicates

SELECT *
FROM dbo.defects_staging;

-- First check a small key: serial number, code, and date.
SELECT PART_SERIAL_NUMBER, CODE, DATE_CREATED,
       ROW_NUMBER() OVER (
           PARTITION BY PART_SERIAL_NUMBER, CODE, DATE_CREATED
           ORDER BY (SELECT NULL)
       ) AS row_num
FROM dbo.defects_staging;

SELECT *
FROM (
    SELECT PART_SERIAL_NUMBER, CODE, DATE_CREATED,
           ROW_NUMBER() OVER (
               PARTITION BY PART_SERIAL_NUMBER, CODE, DATE_CREATED
               ORDER BY (SELECT NULL)
           ) AS row_num
    FROM dbo.defects_staging
) duplicates
WHERE row_num > 1;

-- Same serial numbers can appear at different stations, so the final duplicate
-- check uses all value columns.
SELECT *
FROM dbo.defects_staging
WHERE PART_SERIAL_NUMBER = '740568040100193272';

SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY DATE_CREATED, SHIFT_NAME, PART_SERIAL_NUMBER, MATERIAL_R3,
                            MACHINE_ID, PRODUCTION_ORDER_ID, SEQUENCE,
                            DESCRIPTION, CODE, MATERIAL_COST
               ORDER BY (SELECT NULL)
           ) AS row_num
    FROM dbo.defects_staging
) duplicates
WHERE row_num > 1;

WITH DELETE_CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY DATE_CREATED, SHIFT_NAME, PART_SERIAL_NUMBER, MATERIAL_R3,
                            MACHINE_ID, PRODUCTION_ORDER_ID, SEQUENCE,
                            DESCRIPTION, CODE, MATERIAL_COST
               ORDER BY (SELECT NULL)
           ) AS row_num
    FROM dbo.defects_staging
)
DELETE FROM DELETE_CTE
WHERE row_num > 1;

SELECT COUNT(*) AS remaining_rows
FROM dbo.defects_staging;


-- 2. Standardize text fields

SELECT *
FROM dbo.defects_staging;

SELECT DISTINCT SHIFT_NAME, COUNT(*) AS n
FROM dbo.defects_staging
GROUP BY SHIFT_NAME
ORDER BY SHIFT_NAME;

UPDATE dbo.defects_staging
SET SHIFT_NAME = LOWER(LTRIM(RTRIM(SHIFT_NAME)));

SELECT DISTINCT SHIFT_NAME
FROM dbo.defects_staging
ORDER BY SHIFT_NAME;

-- Convert blank cells to NULL before filling values or changing data types.
UPDATE dbo.defects_staging
SET DESCRIPTION = NULL
WHERE LTRIM(RTRIM(DESCRIPTION)) = '';

UPDATE dbo.defects_staging
SET CODE = NULL
WHERE LTRIM(RTRIM(CAST(CODE AS VARCHAR(50)))) = '';

UPDATE dbo.defects_staging
SET MATERIAL_COST = NULL
WHERE LTRIM(RTRIM(CAST(MATERIAL_COST AS VARCHAR(50)))) = '';

-- Review defect codes and descriptions before fixing blanks.
SELECT CODE, DESCRIPTION, COUNT(*) AS n
FROM dbo.defects_staging
WHERE CODE IS NOT NULL AND DESCRIPTION IS NOT NULL
GROUP BY CODE, DESCRIPTION
ORDER BY CODE, n DESC;

-- Normalize the AOI description.
SELECT DESCRIPTION, COUNT(*) AS n
FROM dbo.defects_staging
WHERE CODE = '275'
GROUP BY DESCRIPTION;

UPDATE dbo.defects_staging
SET DESCRIPTION = 'Automatical optical check NOK'
WHERE CODE = '275'
  AND DESCRIPTION IS NOT NULL;

-- Fill missing descriptions from rows with the same defect code.
WITH code_lookup AS (
    SELECT CODE, MAX(DESCRIPTION) AS DESCRIPTION
    FROM dbo.defects_staging
    WHERE CODE IS NOT NULL
      AND DESCRIPTION IS NOT NULL
    GROUP BY CODE
)
UPDATE t
SET t.DESCRIPTION = l.DESCRIPTION
FROM dbo.defects_staging t
JOIN code_lookup l
    ON t.CODE = l.CODE
WHERE t.DESCRIPTION IS NULL;


-- 3. Convert imported text fields

SELECT TOP 10 DATE_CREATED
FROM dbo.defects_staging;

UPDATE dbo.defects_staging
SET DATE_CREATED = CONVERT(VARCHAR(10), CONVERT(DATE, DATE_CREATED, 101), 23);

ALTER TABLE dbo.defects_staging
ALTER COLUMN DATE_CREATED DATE NULL;

SELECT *
FROM dbo.defects_staging;

ALTER TABLE dbo.defects_staging
ALTER COLUMN MACHINE_ID INT NULL;

ALTER TABLE dbo.defects_staging
ALTER COLUMN PRODUCTION_ORDER_ID INT NULL;

ALTER TABLE dbo.defects_staging
ALTER COLUMN SEQUENCE INT NULL;

ALTER TABLE dbo.defects_staging
ALTER COLUMN MATERIAL_COST DECIMAL(10,3) NULL;

ALTER TABLE dbo.defects_staging
ALTER COLUMN CODE INT NULL;


-- 4. Remove records without defect information

SELECT *
FROM dbo.defects_staging
WHERE CODE IS NULL
  AND DESCRIPTION IS NULL;

DELETE FROM dbo.defects_staging
WHERE CODE IS NULL
  AND DESCRIPTION IS NULL;

SELECT *
FROM dbo.defects_staging;

SELECT COUNT(*) AS final_clean_rows
FROM dbo.defects_staging;
