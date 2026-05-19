"""Build the chart PNGs from the cleaned CSV."""

from pathlib import Path

import matplotlib
import pandas as pd

matplotlib.use("Agg")
import matplotlib.pyplot as plt


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_FILE = PROJECT_ROOT / "data" / "radar_production_defects_CLEAN.csv"
CHARTS_DIR = PROJECT_ROOT / "charts"


def add_bar_labels(values, offset):
    for i, value in enumerate(values):
        plt.text(i, value + offset, str(int(value)), ha="center", fontsize=10)


def main():
    CHARTS_DIR.mkdir(exist_ok=True)

    if not INPUT_FILE.exists():
        raise FileNotFoundError(f"Cleaned CSV not found: {INPUT_FILE}")

    print("Loading cleaned CSV...")
    df = pd.read_csv(INPUT_FILE, parse_dates=["DATE_CREATED"], na_values=["NULL"])
    df["MATERIAL_COST"] = pd.to_numeric(df["MATERIAL_COST"], errors="coerce")
    print("Rows loaded:", len(df))

    print("Making chart 1: defects by shift")
    shift_data = df.groupby("SHIFT_NAME").size().reindex(["early", "late", "night"])
    shift_names = list(shift_data.index)
    shift_counts = list(shift_data.values)

    plt.figure(figsize=(8, 5))
    plt.bar(shift_names, shift_counts, color=["#5B9BD5", "#ED7D31", "#70AD47"])
    plt.xlabel("Shift")
    plt.ylabel("Number of defects")
    plt.title("Defects per Shift")
    add_bar_labels(shift_counts, 15)
    plt.tight_layout()
    plt.savefig(CHARTS_DIR / "chart_1_defects_by_shift.png", dpi=120)
    plt.close()

    print("Making chart 2: top defect types")
    defect_counts = df.groupby("DESCRIPTION").size().sort_values(ascending=False).head(8)
    defect_names = [name[:35] + "..." if len(name) > 35 else name for name in defect_counts.index]
    defect_values = list(defect_counts.values)
    defect_names.reverse()
    defect_values.reverse()

    plt.figure(figsize=(10, 5))
    plt.barh(defect_names, defect_values, color="#4472C4")
    plt.xlabel("Number of defects")
    plt.title("Top Defect Types by Volume")
    for i, value in enumerate(defect_values):
        plt.text(value + 8, i, str(int(value)), va="center", fontsize=9)
    plt.tight_layout()
    plt.savefig(CHARTS_DIR / "chart_2_top_defects.png", dpi=120)
    plt.close()

    print("Making chart 3: top machines")
    machine_counts = df.groupby("MACHINE_ID").size().sort_values(ascending=False).head(5)
    machine_labels = [str(int(machine)) for machine in machine_counts.index]
    machine_values = list(machine_counts.values)

    plt.figure(figsize=(8, 5))
    plt.bar(machine_labels, machine_values, color="#C00000")
    plt.xlabel("Machine ID")
    plt.ylabel("Number of defects")
    plt.title("Top 5 Machines by Defect Count")
    add_bar_labels(machine_values, 2)
    plt.tight_layout()
    plt.savefig(CHARTS_DIR / "chart_3_top_machines.png", dpi=120)
    plt.close()

    print("Making chart 4: monthly trend")
    df["month"] = df["DATE_CREATED"].dt.to_period("M").astype(str)
    monthly_count = df.groupby("month").size()
    monthly_cost = df.groupby("month")["MATERIAL_COST"].sum()

    month_labels = list(monthly_count.index)
    count_values = list(monthly_count.values)
    cost_values = list(monthly_cost.values)

    fig, left_axis = plt.subplots(figsize=(10, 5))
    left_axis.plot(month_labels, cost_values, marker="o", linewidth=2, color="#C00000")
    left_axis.set_xlabel("Month")
    left_axis.set_ylabel("Scrap cost (EUR)", color="#C00000")
    left_axis.tick_params(axis="y", labelcolor="#C00000")
    left_axis.set_title("Monthly Scrap Cost & Volume Trend")

    right_axis = left_axis.twinx()
    right_axis.bar(month_labels, count_values, alpha=0.25, color="#4472C4")
    right_axis.set_ylabel("Defect count", color="#4472C4")
    right_axis.tick_params(axis="y", labelcolor="#4472C4")

    plt.tight_layout()
    plt.savefig(CHARTS_DIR / "chart_4_monthly_trend.png", dpi=120)
    plt.close()

    print("Making chart 5: top stations")
    station_counts = df.groupby("SEQUENCE").size().sort_values(ascending=False).head(5)
    station_labels = ["Seq " + str(int(station)) for station in station_counts.index]
    station_values = list(station_counts.values)

    plt.figure(figsize=(8, 5))
    plt.bar(station_labels, station_values, color="#7030A0")
    plt.xlabel("Station (process sequence)")
    plt.ylabel("Number of defects")
    plt.title("Top 5 Stations by Defect Count")
    add_bar_labels(station_values, 1)
    plt.tight_layout()
    plt.savefig(CHARTS_DIR / "chart_5_top_stations.png", dpi=120)
    plt.close()

    print("All charts saved to:", CHARTS_DIR)


if __name__ == "__main__":
    main()
