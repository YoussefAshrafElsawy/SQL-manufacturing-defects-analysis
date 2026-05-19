-- Query I use to export the cleaned CSV from dbo.defects_staging.
-- Then run this query, right-click the results grid, and choose Save Results As...

SELECT
    DATE_CREATED,
    SHIFT_NAME,
    PART_SERIAL_NUMBER,
    MATERIAL_R3,
    MACHINE_ID,
    PRODUCTION_ORDER_ID,
    SEQUENCE,
    DESCRIPTION,
    CODE,
    COALESCE(CAST(MATERIAL_COST AS VARCHAR(20)), 'NULL') AS MATERIAL_COST
FROM dbo.defects_staging
ORDER BY
    DATE_CREATED,
    SHIFT_NAME,
    PART_SERIAL_NUMBER,
    MATERIAL_R3,
    MACHINE_ID,
    PRODUCTION_ORDER_ID,
    SEQUENCE,
    DESCRIPTION,
    CODE,
    MATERIAL_COST;
