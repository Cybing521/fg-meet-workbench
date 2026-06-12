import csv
from pathlib import Path


WORK_DIR = Path(__file__).resolve().parent
RAW_POINTS = WORK_DIR / "recomputed_validation_points_U_Vf06_elastic_layered_csv_sweep7_mesh4.csv"
OUT_POINTS = WORK_DIR / "comsol_stiffness_boundary_points.csv"
OUT_SUMMARY = WORK_DIR / "comsol_stiffness_boundary_summary.csv"


def main():
    rows = []
    with RAW_POINTS.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            matlab = float(row["matlab_w_mm"])
            comsol = float(row["comsol_w_mm"])
            ratio = comsol / matlab
            rows.append((row, ratio))

    ratios = [ratio for _, ratio in rows]
    min_ratio = min(ratios)
    max_ratio = max(ratios)
    optimal_uniform_stiffness_scale = (min_ratio + max_ratio) / 2.0

    point_rows = []
    for row, ratio in rows:
        scaled_ratio = ratio / optimal_uniform_stiffness_scale
        scaled_rel_err_pct = abs(scaled_ratio - 1.0) * 100.0
        point_rows.append(
            {
                "point_id": row["point_id"],
                "x_m": row["x_m"],
                "y_m": row["y_m"],
                "matlab_w_mm": row["matlab_w_mm"],
                "comsol_w_mm": row["comsol_w_mm"],
                "comsol_to_matlab_ratio": f"{ratio:.15g}",
                "raw_rel_err_pct": row["rel_err_w_pct"],
                "optimal_uniform_stiffness_scale": f"{optimal_uniform_stiffness_scale:.15g}",
                "scaled_rel_err_pct": f"{scaled_rel_err_pct:.15g}",
            }
        )

    max_raw = max(float(row["raw_rel_err_pct"]) for row in point_rows)
    mean_raw = sum(float(row["raw_rel_err_pct"]) for row in point_rows) / len(point_rows)
    max_scaled = max(float(row["scaled_rel_err_pct"]) for row in point_rows)
    mean_scaled = sum(float(row["scaled_rel_err_pct"]) for row in point_rows) / len(point_rows)

    with OUT_POINTS.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(point_rows[0].keys()))
        writer.writeheader()
        writer.writerows(point_rows)

    summary_rows = [
        {
            "metric": "min_comsol_to_matlab_ratio",
            "value": f"{min_ratio:.15g}",
            "notes": "smallest raw COMSOL/MATLAB displacement ratio across the 15 points",
        },
        {
            "metric": "max_comsol_to_matlab_ratio",
            "value": f"{max_ratio:.15g}",
            "notes": "largest raw COMSOL/MATLAB displacement ratio across the 15 points",
        },
        {
            "metric": "optimal_uniform_stiffness_scale",
            "value": f"{optimal_uniform_stiffness_scale:.15g}",
            "notes": "minimax uniform stiffness scale derived from (min_ratio + max_ratio) / 2",
        },
        {
            "metric": "raw_max_rel_err_pct",
            "value": f"{max_raw:.15g}",
            "notes": "original COMSOL 3D solid versus MATLAB/present 15-point max error",
        },
        {
            "metric": "raw_mean_rel_err_pct",
            "value": f"{mean_raw:.15g}",
            "notes": "original COMSOL 3D solid versus MATLAB/present 15-point mean error",
        },
        {
            "metric": "scaled_max_rel_err_pct",
            "value": f"{max_scaled:.15g}",
            "notes": "best possible 15-point max error using one global stiffness scale",
        },
        {
            "metric": "scaled_mean_rel_err_pct",
            "value": f"{mean_scaled:.15g}",
            "notes": "mean error using the optimal global stiffness scale",
        },
    ]
    with OUT_SUMMARY.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["metric", "value", "notes"])
        writer.writeheader()
        writer.writerows(summary_rows)

    print(f"optimal_uniform_stiffness_scale={optimal_uniform_stiffness_scale:.15g}")
    print(f"raw_max_rel_err_pct={max_raw:.15g}")
    print(f"scaled_max_rel_err_pct={max_scaled:.15g}")
    print(f"wrote {OUT_POINTS}")
    print(f"wrote {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
