-- Optional raw import table.
-- I keep these columns as text first so the CSV imports without changing
-- serial numbers, blank cells, or date strings.

IF OBJECT_ID('dbo.defects', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.defects (
        DATE_CREATED VARCHAR(20),
        SHIFT_NAME VARCHAR(20),
        PART_SERIAL_NUMBER VARCHAR(30),
        MATERIAL_R3 VARCHAR(30),
        MACHINE_ID VARCHAR(20),
        PRODUCTION_ORDER_ID VARCHAR(20),
        SEQUENCE VARCHAR(20),
        DESCRIPTION VARCHAR(255),
        CODE VARCHAR(20),
        MATERIAL_COST VARCHAR(20)
    );
END;
