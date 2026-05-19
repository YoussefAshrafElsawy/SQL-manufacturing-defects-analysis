-- Exploratory analysis in SQL Server
--
-- Main questions:
--   Which defect types cost the most?
--   Which shifts, machines, and stations have the most defects?
--   Which materials and orders create the most scrap cost?
--   How does scrap change month by month?

SELECT *
FROM dbo.defects_staging;


-- Cost range
SELECT MAX(MATERIAL_COST) AS most_expensive_scrap
FROM dbo.defects_staging;

SELECT MAX(MATERIAL_COST) AS max_cost,
       MIN(MATERIAL_COST) AS min_cost
FROM dbo.defects_staging
WHERE MATERIAL_COST IS NOT NULL;

SELECT TOP 10 PART_SERIAL_NUMBER, MATERIAL_R3, DESCRIPTION, MATERIAL_COST
FROM dbo.defects_staging
WHERE MATERIAL_COST IS NOT NULL
ORDER BY MATERIAL_COST DESC;


-- Defect volume and cost
SELECT DESCRIPTION, COUNT(*) AS defect_count
FROM dbo.defects_staging
GROUP BY DESCRIPTION
ORDER BY defect_count DESC;

SELECT DESCRIPTION,
       COUNT(*) AS defect_count,
       SUM(MATERIAL_COST) AS total_scrap_cost,
       AVG(MATERIAL_COST) AS avg_cost_per_defect
FROM dbo.defects_staging
WHERE MATERIAL_COST IS NOT NULL
GROUP BY DESCRIPTION
ORDER BY total_scrap_cost DESC;


-- Machines, stations, shifts, materials, and orders
SELECT TOP 10 MACHINE_ID,
       COUNT(*) AS defect_count,
       SUM(MATERIAL_COST) AS total_scrap_cost
FROM dbo.defects_staging
GROUP BY MACHINE_ID
ORDER BY defect_count DESC;

SELECT SEQUENCE,
       COUNT(*) AS defect_count,
       SUM(MATERIAL_COST) AS total_scrap_cost
FROM dbo.defects_staging
GROUP BY SEQUENCE
ORDER BY defect_count DESC;

SELECT SHIFT_NAME,
       COUNT(*) AS defect_count,
       SUM(MATERIAL_COST) AS total_scrap_cost,
       AVG(MATERIAL_COST) AS avg_cost
FROM dbo.defects_staging
GROUP BY SHIFT_NAME
ORDER BY defect_count DESC;

SELECT MATERIAL_R3,
       COUNT(*) AS defect_count,
       SUM(MATERIAL_COST) AS total_scrap_cost
FROM dbo.defects_staging
GROUP BY MATERIAL_R3
ORDER BY total_scrap_cost DESC;

SELECT TOP 15 PRODUCTION_ORDER_ID,
       COUNT(*) AS defect_count,
       SUM(MATERIAL_COST) AS total_scrap_cost
FROM dbo.defects_staging
GROUP BY PRODUCTION_ORDER_ID
ORDER BY defect_count DESC;


-- Monthly trend
SELECT YEAR(DATE_CREATED) AS yr,
       MONTH(DATE_CREATED) AS mo,
       COUNT(*) AS defect_count,
       SUM(MATERIAL_COST) AS total_scrap_cost
FROM dbo.defects_staging
GROUP BY YEAR(DATE_CREATED), MONTH(DATE_CREATED)
ORDER BY yr, mo;


-- Top 3 machines by month
WITH Machine_Month AS (
    SELECT MACHINE_ID,
           CONVERT(CHAR(7), DATE_CREATED, 120) AS yr_month,
           COUNT(*) AS defect_count
    FROM dbo.defects_staging
    GROUP BY MACHINE_ID, CONVERT(CHAR(7), DATE_CREATED, 120)
),
Machine_Month_Rank AS (
    SELECT MACHINE_ID,
           yr_month,
           defect_count,
           DENSE_RANK() OVER (
               PARTITION BY yr_month
               ORDER BY defect_count DESC
           ) AS ranking
    FROM Machine_Month
)
SELECT MACHINE_ID, yr_month, defect_count, ranking
FROM Machine_Month_Rank
WHERE ranking <= 3
ORDER BY yr_month ASC, defect_count DESC;


-- Running scrap cost
SELECT CONVERT(CHAR(7), DATE_CREATED, 120) AS yr_month,
       SUM(MATERIAL_COST) AS monthly_scrap_cost
FROM dbo.defects_staging
GROUP BY CONVERT(CHAR(7), DATE_CREATED, 120)
ORDER BY yr_month ASC;

WITH MONTH_CTE AS (
    SELECT CONVERT(CHAR(7), DATE_CREATED, 120) AS yr_month,
           SUM(MATERIAL_COST) AS monthly_scrap_cost
    FROM dbo.defects_staging
    GROUP BY CONVERT(CHAR(7), DATE_CREATED, 120)
)
SELECT yr_month,
       monthly_scrap_cost,
       SUM(monthly_scrap_cost) OVER (ORDER BY yr_month ASC) AS rolling_total_scrap_cost
FROM MONTH_CTE
ORDER BY yr_month ASC;


-- Top defect types in each shift
WITH Shift_Defect_Count AS (
    SELECT SHIFT_NAME,
           DESCRIPTION,
           COUNT(*) AS defect_count
    FROM dbo.defects_staging
    GROUP BY SHIFT_NAME, DESCRIPTION
),
Shift_Defect_Rank AS (
    SELECT SHIFT_NAME,
           DESCRIPTION,
           defect_count,
           DENSE_RANK() OVER (
               PARTITION BY SHIFT_NAME
               ORDER BY defect_count DESC
           ) AS rk
    FROM Shift_Defect_Count
)
SELECT SHIFT_NAME, DESCRIPTION, defect_count, rk
FROM Shift_Defect_Rank
WHERE rk <= 3
ORDER BY SHIFT_NAME, rk;


-- Defect mix inside each station
SELECT SEQUENCE,
       DESCRIPTION,
       COUNT(*) AS defect_count,
       CAST(100.0 * COUNT(*)
            / SUM(COUNT(*)) OVER (PARTITION BY SEQUENCE)
            AS DECIMAL(5,2)) AS pct_of_station
FROM dbo.defects_staging
GROUP BY SEQUENCE, DESCRIPTION
ORDER BY SEQUENCE, defect_count DESC;
