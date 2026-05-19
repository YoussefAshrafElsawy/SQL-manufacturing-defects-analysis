# Production Defects: SQL Data Cleaning & Exploratory data analysis

This is a self-contained SQL and Python portfolio project I completed to
demonstrate how I clean messy manufacturing data, explore business drivers,
visualize results, and translate query outputs into practical manufacturing
recommendations.

The project works with a production defect log provided as a CSV file.
Each row represents a defective part flagged during assembly or final testing.
the current workflow is: data cleaning in T-SQL, exploratory analysis,
chart generation in Python, and interpretation of the results.

## Project Highlights

- Cleaned a raw defect table by removing true duplicates,
  standardizing categorical values, converting imported text fields to proper
  SQL types, and handling missing defect information.
- Used SQL Server / T-SQL features including CTEs, window functions,
  `ROW_NUMBER()`, `DENSE_RANK()`, grouped aggregations, joins, and date
  conversion.
- Analyzed scrap by defect type, shift, machine, station, material, production
  order, and month.
- Rebuilt summary charts from the cleaned CSV with Python, pandas, and
  matplotlib.

## Repository Structure

```
sql-data-cleaning-eda-portfolio/
├── README.md
├── requirements.txt
├── data/
│   ├── radar_production_defects.csv
│   └── radar_production_defects_CLEAN.csv
├── scripts/
│   └── generate_charts.py
├── sql/
│   ├── 00_create_table.sql
│   ├── 01_data_cleaning.sql
│   ├── 02_eda.sql
│   └── 03_export_clean_csv.sql
└── charts/
    ├── chart_1_defects_by_shift.png
    ├── chart_2_top_defects.png
    ├── chart_3_top_machines.png
    ├── chart_4_monthly_trend.png
    └── chart_5_top_stations.png
```

## Dataset Columns

| Column | Description |
|---|---|
| `DATE_CREATED` | Date when the defect was logged |
| `SHIFT_NAME` | Production shift: early, late, or night |
| `PART_SERIAL_NUMBER` | Part serial number |
| `MATERIAL_R3` | material number |
| `MACHINE_ID` | Machine that detected or logged the defect |
| `PRODUCTION_ORDER_ID` | Production order / batch identifier |
| `SEQUENCE` | Station number on the line |
| `DESCRIPTION` | Defect description |
| `CODE` | Numeric defect code |
| `MATERIAL_COST` | Recorded material cost in EUR |


## Data Quality Issues Handled

The raw CSV includes the kinds of issues that often appear in manufacturing
exports:

| Issue | Cleaning approach |
|---|---|
| Exact duplicate rows | Removed with `ROW_NUMBER()` over all value columns |
| Shift names with inconsistent casing or whitespace | Trimmed and converted to lowercase |
| Blank descriptions where a valid code exists | Backfilled by joining on defect code |
| Rows with no code and no description | Deleted as unusable records |
| Multiple labels for the same defect | Standardized to one canonical description |
| Dates imported as text | Converted to SQL `DATE` |
| Empty cost fields | Preserved as `NULL` for analysis |


## Analysis Summary

The cleaned table covers **2,350 defect records** from November 2025 through
April 2026, with **€34,076.37** in recorded material cost.

- `Final Test Radar NOK` is the largest defect category: 870 records, 37.0% of
  all defects, and 36.2% of total recorded cost.
- The top three defect categories account for about 61% of total recorded cost.
- Night shift has about 9% more defects than early shift.
- Monthly scrap cost stays relatively flat across the analyzed period.
- Defect counts are spread fairly evenly across the top machines, so the best
  improvement target is defect type rather than one individual machine.

## Charts

The chart images below are based on the cleaned CSV. They can be recreated with
[`scripts/generate_charts.py`](scripts/generate_charts.py).

![Defects by shift](charts/chart_1_defects_by_shift.png)

![Top defect types](charts/chart_2_top_defects.png)

![Top machines](charts/chart_3_top_machines.png)

![Monthly trend](charts/chart_4_monthly_trend.png)

![Top stations](charts/chart_5_top_stations.png)

