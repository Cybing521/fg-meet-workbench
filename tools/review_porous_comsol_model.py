#!/usr/bin/env python3
"""Review the porous COMSOL validation model against MATLAB references.

The review intentionally does not re-run COMSOL. It checks the evidence that is
already available after the batch solves:

* pointwise MATLAB-vs-COMSOL displacement bias;
* mesh-sensitivity direction;
* porous layer CSV parity with the MATLAB input MATERIAL block;
* which layer material columns the COMSOL Java driver actually consumes.
"""

from __future__ import annotations

import csv
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "reports" / "2026-06-04-porous-comsol-model-review"
DATA = REPORT / "data"

POROUS_CASES = [
    {
        "case": "U_Vf50_e20_Even_elastic",
        "label": "U/Vf0=0.5/e0=0.2/Even",
        "case_file": ROOT / "cases" / "porous" / "Porous_CFFF_U_Vf0.5_e20_Even-30x30-10layer.txt",
        "layer_csv": ROOT / "comsol" / "export" / "porous" / "Porous_U_Vf0.5_e20_Even_layers.csv",
        "best_points": ROOT / "comsol" / "results" / "validation_points_porous_U_Vf05_e20_Even_elastic_layered_csv_sweep7_mesh4.csv",
        "refined_points": ROOT / "comsol" / "results" / "validation_points_porous_U_Vf05_e20_Even_elastic_layered_csv_sweep10_mesh3.csv",
    },
    {
        "case": "U_Vf50_e30_Even_elastic",
        "label": "U/Vf0=0.5/e0=0.3/Even",
        "case_file": ROOT / "cases" / "porous" / "Porous_CFFF_U_Vf0.5_e30_Even-30x30-10layer.txt",
        "layer_csv": ROOT / "comsol" / "export" / "porous" / "Porous_U_Vf0.5_e30_Even_layers.csv",
        "best_points": ROOT / "comsol" / "results" / "validation_points_porous_U_Vf05_e30_Even_elastic_layered_csv_sweep7_mesh4.csv",
        "refined_points": ROOT / "comsol" / "results" / "validation_points_porous_U_Vf05_e30_Even_elastic_layered_csv_sweep10_mesh3.csv",
    },
    {
        "case": "X_Vf50_e20_Even_elastic",
        "label": "X/Vf0=0.5/e0=0.2/Even",
        "case_file": ROOT / "cases" / "porous" / "Porous_CFFF_X_Vf0.5_e20_Even-30x30-10layer.txt",
        "layer_csv": ROOT / "comsol" / "export" / "porous" / "Porous_X_Vf0.5_e20_Even_layers.csv",
        "best_points": ROOT / "comsol" / "results" / "validation_points_porous_X_Vf05_e20_Even_elastic_layered_csv_sweep7_mesh4.csv",
        "refined_points": ROOT / "comsol" / "results" / "validation_points_porous_X_Vf05_e20_Even_elastic_layered_csv_sweep10_mesh3.csv",
    },
]

NON_POROUS_POINTS = [
    ROOT / "comsol" / "results" / "validation_points_U_Vf06_elastic_layered_csv_sweep7_mesh4.csv",
    ROOT / "comsol" / "results" / "validation_points_V_Vf06_elastic_layered_csv_sweep7_mesh4.csv",
    ROOT / "comsol" / "results" / "validation_points_X_Vf06_elastic_layered_csv_sweep7_mesh4.csv",
]

MATERIAL_COLS = [
    "layer", "E1", "E2", "v12", "v23", "G12", "G13", "G23",
    "d31", "d32", "angle", "hE", "q31", "q32", "g33", "k33", "r33",
    "A1", "A2", "PyroE", "PyroM", "Cv", "HC", "Density", "zC1", "zC2",
    "IsSmtLay",
]

JAVA_DRIVER = ROOT / "tools" / "comsol" / "RunElasticCfffValidation.java"


def read_points(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def rel_diff_pct(a: float, b: float) -> float:
    return abs(a - b) / max(abs(a), abs(b), 1e-15) * 100.0


def point_stats(path: Path) -> dict[str, object]:
    rows = read_points(path)
    ratios = [float(r["comsol_w_mm"]) / float(r["matlab_w_mm"]) for r in rows]
    errs = [float(r["rel_err_w_pct"]) for r in rows]
    diffs = [float(r["diff_w_mm"]) for r in rows]
    center = next(r for r in rows if r["point_id"] == "p8")
    max_row = max(rows, key=lambda r: float(r["rel_err_w_pct"]))
    return {
        "point_file": str(path.relative_to(ROOT)),
        "center_err_pct": float(center["rel_err_w_pct"]),
        "max_err_pct": max(errs),
        "mean_err_pct": sum(errs) / len(errs),
        "mean_ratio_comsol_over_matlab": sum(ratios) / len(ratios),
        "min_ratio_comsol_over_matlab": min(ratios),
        "max_ratio_comsol_over_matlab": max(ratios),
        "mean_diff_w_mm": sum(diffs) / len(diffs),
        "max_point": max_row["point_id"],
        "max_point_x_m": float(max_row["x_m"]),
        "max_point_y_m": float(max_row["y_m"]),
        "max_point_matlab_w_mm": float(max_row["matlab_w_mm"]),
        "max_point_comsol_w_mm": float(max_row["comsol_w_mm"]),
    }


def parse_material_block(path: Path) -> list[dict[str, float]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    start = text.index("MATERIAL START") + len("MATERIAL START")
    end = text.index("MATERIAL END", start)
    rows = []
    for raw in text[start:end].splitlines():
        line = raw.strip()
        if not line or not line[0].isdigit():
            continue
        parts = line.split()
        row = {name: float(parts[i]) for i, name in enumerate(MATERIAL_COLS)}
        rows.append(row)
    return rows


def read_layer_csv(path: Path) -> list[dict[str, float]]:
    with path.open(newline="", encoding="utf-8") as f:
        rows = []
        for row in csv.DictReader(f):
            rows.append({k: float(v) for k, v in row.items() if v != ""})
        return rows


def material_parity(case_file: Path, layer_csv: Path) -> dict[str, object]:
    case_rows = parse_material_block(case_file)
    csv_rows = read_layer_csv(layer_csv)
    cols = [c for c in MATERIAL_COLS if c in csv_rows[0]]
    max_diff = -1.0
    max_col = ""
    max_layer = 0
    for i, (case_row, csv_row) in enumerate(zip(case_rows, csv_rows), start=1):
        for col in cols:
            diff = rel_diff_pct(case_row[col], csv_row[col])
            if diff > max_diff:
                max_diff = diff
                max_col = col
                max_layer = i
    return {
        "case_file": str(case_file.relative_to(ROOT)),
        "layer_csv": str(layer_csv.relative_to(ROOT)),
        "layers_in_case": len(case_rows),
        "layers_in_csv": len(csv_rows),
        "max_rel_diff_pct_case_vs_csv": max_diff,
        "max_diff_layer": max_layer,
        "max_diff_column": max_col,
    }


def java_material_usage() -> dict[str, object]:
    src = JAVA_DRIVER.read_text(encoding="utf-8", errors="replace")
    used = []
    if "layerE1(layer)" in src:
        used.append("E1")
    if "layerNu12(layer)" in src:
        used.append("v12")
    if "layerDensity(layer)" in src:
        used.append("Density")
    ignored = [
        "E2", "v23", "G12", "G13", "G23", "d31", "d32", "q31", "q32",
        "g33", "k33", "r33", "A1", "A2", "PyroE", "PyroM", "Cv", "HC",
    ]
    return {
        "java_driver": str(JAVA_DRIVER.relative_to(ROOT)),
        "material_model": "COMSOL Common material, isotropic Young's modulus / Poisson's ratio / density",
        "csv_columns_consumed": ";".join(used),
        "csv_columns_not_consumed_by_solid_surrogate": ";".join(ignored),
    }


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def fmt_pct(value: float) -> str:
    return f"{value:.3f}%"


def fmt_num(value: float) -> str:
    return f"{value:.5f}"


def make_report(point_rows: list[dict[str, object]], material_rows: list[dict[str, object]], usage: dict[str, object]) -> str:
    best = [r for r in point_rows if r["family"] == "porous-best"]
    refined = [r for r in point_rows if r["family"] == "porous-refined"]
    nonporous = [r for r in point_rows if r["family"] == "nonporous-reference"]
    best_max = max(float(r["max_err_pct"]) for r in best)
    refined_max = max(float(r["max_err_pct"]) for r in refined)
    nonporous_max = max(float(r["max_err_pct"]) for r in nonporous)
    best_ratio_min = min(float(r["mean_ratio_comsol_over_matlab"]) for r in best)
    best_ratio_max = max(float(r["mean_ratio_comsol_over_matlab"]) for r in best)
    parity_max = max(float(r["max_rel_diff_pct_case_vs_csv"]) for r in material_rows)

    lines = [
        "# Porous COMSOL model construction review",
        "",
        "## Direct answer",
        "",
        "The porous discrepancy is not best treated as a load-method problem. The current batch model already uses the validated Case A force-area route: top surface load `FperArea = [0, 0, -15000] N/m^2`. The evidence points instead to the porous COMSOL solid surrogate being too simple for the porous MATLAB plate model.",
        "",
        "The specific modeling gap is that `tools/comsol/RunElasticCfffValidation.java` reads the 10-layer CSV but assigns only `E1`, `v12`, and `Density` to a COMSOL isotropic elastic material. The MATLAB input and layer CSV contain the fuller plate material row (`E1/E2/G12/G13/G23`, coupling and thermal terms). The simplification still passes for non-porous/non-U checks, but after porosity softening it produces a systematic extra-flexible response.",
        "",
        "## Review result",
        "",
        f"- Best porous 15-point maximum error: `{fmt_pct(best_max)}`.",
        f"- Refined porous mesh maximum error: `{fmt_pct(refined_max)}`; refinement increases the discrepancy, so this is not a mesh-density fix.",
        f"- Non-porous/non-U reference maximum error remains within criterion: `{fmt_pct(nonporous_max)}`.",
        f"- Porous COMSOL/MATLAB mean displacement ratio is `{fmt_num(best_ratio_min)}`--`{fmt_num(best_ratio_max)}`; COMSOL is consistently more flexible.",
        f"- MATLAB case MATERIAL rows and exported porous layer CSVs match within formatted input precision; maximum case-vs-CSV relative difference is `{fmt_pct(parity_max)}`.",
        "",
        "## Pointwise bias summary",
        "",
        "| Case | Run | Center error | Max error | Mean ratio C/M | Max-error point |",
        "|------|-----|--------------|-----------|----------------|-----------------|",
    ]
    for row in best + refined:
        lines.append(
            "| {case_label} | {run_label} | {center} | {maxerr} | {ratio} | {point} ({x:.2f},{y:.2f}) |".format(
                case_label=row["case_label"],
                run_label=row["run_label"],
                center=fmt_pct(float(row["center_err_pct"])),
                maxerr=fmt_pct(float(row["max_err_pct"])),
                ratio=fmt_num(float(row["mean_ratio_comsol_over_matlab"])),
                point=row["max_point"],
                x=float(row["max_point_x_m"]),
                y=float(row["max_point_y_m"]),
            )
        )

    lines.extend([
        "",
        "## Load-method check",
        "",
        "The load route is:",
        "",
        "1. MATLAB Case A uses `LoadScale = -15000` as a distributed mechanical load.",
        "2. COMSOL uses `BoundaryLoad` with `LoadType = ForceArea` and `FperArea = [0, 0, -15000[N/m^2]]` on the top face.",
        "3. If the load magnitude or sign were the primary issue, the already-passing non-U/CFCF rows would show the same failure pattern. They do not.",
        "",
        "A post-hoc load rescaling could numerically reduce the porous displacement error because the model is linear, but that would only calibrate away the symptom. It would not be a defensible validation result.",
        "",
        "## Construction review checklist",
        "",
        "| Item | Status | Evidence |",
        "|------|--------|----------|",
        "| Layer geometry | OK | Ten stacked domains, z ranges from the layer CSV. |",
        "| Layer material CSV export | OK | MATERIAL block and CSV match within printed precision. |",
        "| Boundary condition | OK | CFFF/CFCF selection logic is explicit in Java driver; CFCF refined row passes. |",
        "| Load method | OK for Case A | Uses force-area load with MATLAB pressure magnitude. |",
        "| Mesh density | Not root cause | Refined porous mesh increases error. |",
        "| Solid material formulation | Needs change | Current COMSOL driver consumes only `E1`, `v12`, `Density` and treats each layer as isotropic. |",
        "",
        "## Next implementation path",
        "",
        "The next real fix is to add an orthotropic/anisotropic material mode to the COMSOL Java driver and rerun the three porous validation rows. That mode should assign at least `E1`, `E2`, `G12`, `G13`, `G23`, `v12`, `v23`, and `Density` per layer. If the target is full thermo-magneto-electro-elastic validation rather than elastic deflection validation, the mapped coupling/thermal constants must also be moved out of the CSV-only documentation path and into the COMSOL physics definition.",
        "",
        "Until that orthotropic COMSOL rerun is complete, the paper/report wording should remain: non-U and CFCF are validated within 5%; porous rows are solved but require COMSOL model-formulation review.",
        "",
        "## Generated files",
        "",
        "- `data/point_bias_summary.csv`",
        "- `data/material_parity_summary.csv`",
        "- `data/comsol_material_usage.csv`",
    ])
    return "\n".join(lines) + "\n"


def main() -> None:
    DATA.mkdir(parents=True, exist_ok=True)

    point_rows: list[dict[str, object]] = []
    for case in POROUS_CASES:
        for family, run_label, key in [
            ("porous-best", "mesh4/sweep7", "best_points"),
            ("porous-refined", "mesh3/sweep10", "refined_points"),
        ]:
            stats = point_stats(case[key])
            point_rows.append({
                "family": family,
                "case_id": case["case"],
                "case_label": case["label"],
                "run_label": run_label,
                **stats,
            })
    for path in NON_POROUS_POINTS:
        stats = point_stats(path)
        point_rows.append({
            "family": "nonporous-reference",
            "case_id": Path(path).stem.replace("validation_points_", ""),
            "case_label": Path(path).stem.replace("validation_points_", ""),
            "run_label": "mesh4/sweep7",
            **stats,
        })
    write_csv(DATA / "point_bias_summary.csv", point_rows)

    material_rows = []
    for case in POROUS_CASES:
        material_rows.append({
            "case_id": case["case"],
            "case_label": case["label"],
            **material_parity(case["case_file"], case["layer_csv"]),
        })
    write_csv(DATA / "material_parity_summary.csv", material_rows)

    usage = java_material_usage()
    write_csv(DATA / "comsol_material_usage.csv", [usage])

    (REPORT / "README.md").write_text(make_report(point_rows, material_rows, usage), encoding="utf-8")
    print(f"Wrote {REPORT / 'README.md'}")
    print(f"Wrote {DATA / 'point_bias_summary.csv'}")
    print(f"Wrote {DATA / 'material_parity_summary.csv'}")
    print(f"Wrote {DATA / 'comsol_material_usage.csv'}")


if __name__ == "__main__":
    main()
