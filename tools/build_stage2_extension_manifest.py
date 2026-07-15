"""Build SHA-256 evidence inventory for the Stage-2 extension handoff."""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "outputs" / "paper-20260715-fgmee"


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main() -> None:
    explicit = [
        ROOT / "matlab" / "run_meet_static.m",
        ROOT / "matlab" / "run_isomorphic_solid_cfff.m",
        ROOT / "run_export_qian_inverse_layers.m",
        ROOT / "run_matlab_inverse_pyro_fix_verification.m",
        ROOT / "run_matlab_isomorphic_solid_validation.m",
        ROOT / "run_matlab_curvature_fg_full_mesh_validation.m",
        ROOT / "tools" / "comsol" / "RunIsomorphicSolidCfffValidation.java",
        ROOT / "tools" / "comsol" / "RunCurvedSolidCfffValidation.java",
        ROOT / "tools" / "comsol" / "RunInverseSensorCfffValidation.java",
        ROOT / "tools" / "generate_curvature_fg_cases.py",
        ROOT / "tools" / "generate_validation_mesh_cases.py",
        ROOT / "tools" / "analyze_isomorphic_solid_validation.py",
        ROOT / "tools" / "analyze_curvature_fg_full_validation.py",
        ROOT / "tools" / "analyze_curved_comsol_validation.py",
        ROOT / "tools" / "analyze_20x20_discrepancy_closure.py",
        ROOT / "tools" / "analyze_inverse_pyro_overcount.py",
        ROOT / "tools" / "plotting" / "plot_stage2_extension_figures.py",
        ROOT / "tools" / "validate_stage2_extension.py",
        ROOT / "tools" / "build_stage2_extension_manifest.py",
        BASE / "experiments" / "stage2_extension_reproduction_commands.md",
        BASE / "experiments" / "stage2_extension_validation_gate.json",
        BASE / "phase4_reporting" / "fgmee_latest_feasible_results_report_20260715_quality_check.md",
        BASE / "phase4_reporting" / "fgmee_latest_feasible_results_report_20260715_visual_qa.md",
        ROOT / "cases" / "curvature_fg" / "curvature_case_manifest.csv",
        BASE / "experiments" / "isomorphic_solid" / "matlab_isomorphic_solid_results.csv",
        BASE / "experiments" / "isomorphic_solid" / "matlab_isomorphic_solid_validation.log",
        BASE / "experiments" / "isomorphic_solid" / "matlab_toolbox_inventory.log",
        BASE / "experiments" / "isomorphic_solid" / "isomorphic_solid_cross_solver_comparison.csv",
        BASE / "experiments" / "discrepancy_20x20_root_cause_decomposition.csv",
        BASE / "experiments" / "discrepancy_20x20_closure.md",
        BASE / "experiments" / "deep_20x20_bias_diagnosis.md",
        BASE / "experiments" / "direct_comsol_mesh_validation.csv",
        BASE / "experiments" / "inverse_sensing" / "inverse_sensor_corrected_comparison.csv",
        BASE / "experiments" / "inverse_sensing" / "inverse_pyro_overcount_audit.csv",
        BASE / "experiments" / "inverse_sensing" / "inverse_sensor_deep_diagnosis.md",
        BASE / "experiments" / "inverse_sensing" / "qian_inverse_layer_means.csv",
        BASE / "experiments" / "inverse_sensing" / "matlab_inverse_pyro_fix_10x10.csv",
        BASE / "experiments" / "inverse_sensing" / "matlab_inverse_pyro_fix_10x10.log",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_10x10x1_smoke_layers.csv",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_10x10x1_smoke_summary.csv",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_10x10x1_smoke.log",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_10x10x1_smoke_Model.mph",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_15x15x5_layers.csv",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_15x15x5_summary.csv",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_15x15x5.log",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_15x15x5_Model.mph",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_20x20x5_layers.csv",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_20x20x5_summary.csv",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_20x20x5.log",
        BASE / "experiments" / "inverse_sensing" / "comsol_inverse_sensor_20x20x5_Model.mph",
        BASE / "experiments" / "comsol" / "comsol_direct_electro_300V_20x20x10_summary.csv",
        BASE / "experiments" / "comsol" / "comsol_direct_magnetic_200A_20x20x10_summary.csv",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_full_mesh_20_30_raw.csv",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_full_mesh_validation_resume.log",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_meshcheck_R0p4_raw.csv",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_meshcheck_R0p4_20_radiusfixed.csv",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_full_mesh_convergence.csv",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_final_30x30_results.csv",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_all_radius_interaction_30x30.csv",
        BASE / "experiments" / "curvature_fg" / "curvature_fg_report_macros.tex",
        BASE / "experiments" / "curvature_fg" / "curved_comsol_mesh_convergence.csv",
        BASE / "experiments" / "curvature_fg" / "curved_comsol_vs_matlab_model_form_comparison.csv",
        BASE / "phase4_reporting" / "fgmee_latest_feasible_results_report_20260715.tex",
        BASE / "phase4_reporting" / "fgmee_latest_feasible_results_report_20260715.pdf",
    ]
    globs = [
        BASE / "experiments" / "isomorphic_solid" / "comsol" / "comsol_isomorphic_*_summary.csv",
        BASE / "experiments" / "isomorphic_solid" / "comsol" / "comsol_isomorphic_*_Model.mph",
        BASE / "experiments" / "isomorphic_solid" / "comsol" / "comsol_isomorphic_*x.log",
        BASE / "experiments" / "curvature_fg" / "comsol" / "comsol_curved_U_R0p4_*_summary.csv",
        BASE / "experiments" / "curvature_fg" / "comsol" / "comsol_curved_U_R0p4_*_Model.mph",
        BASE / "experiments" / "curvature_fg" / "comsol" / "comsol_curved_U_R0p4_*.log",
        BASE / "experiments" / "curvature_fg" / "comsol" / "comsol_curved_U_R0p4_*_midarc.csv",
        BASE / "figures" / "Fig_0[3-5]_*.png",
        BASE / "figures" / "Fig_0[3-5]_*.pdf",
    ]
    paths = list(explicit)
    for pattern in globs:
        paths.extend(pattern.parent.glob(pattern.name))
    paths.extend((ROOT / "cases" / "curvature_fg").glob("*/*.txt"))
    paths.extend((ROOT / "cases" / "validation_mesh").glob("*"))
    paths = [
        path
        for path in paths
        if "smoke" not in path.name.lower() or "inverse_sensor" in path.name.lower()
    ]
    paths = sorted(set(path.resolve() for path in paths), key=lambda p: str(p).lower())

    rows: list[dict[str, object]] = []
    missing: list[str] = []
    for path in paths:
        if not path.is_file():
            missing.append(str(path))
            rows.append(
                {
                    "relative_path": str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path),
                    "size_bytes": "",
                    "sha256": "",
                    "status": "missing",
                }
            )
            continue
        rows.append(
            {
                "relative_path": str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path),
                "size_bytes": path.stat().st_size,
                "sha256": digest(path),
                "status": "verified",
            }
        )
    out = BASE / "experiments" / "stage2_extension_evidence_manifest.csv"
    with out.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    metadata = {
        "date": "2026-07-15",
        "matlab": "R2026a 26.1; base MATLAB and Simulink; PDE Toolbox absent",
        "comsol": "COMSOL Multiphysics 6.0.0.318 Java API/comsolbatch",
        "plotting_python": "Python 3.10.20; Matplotlib 3.10.9; pandas 2.3.3; NumPy 2.2.6",
        "latex_engine": "Tectonic 0.16.9",
        "matlab_solid": "H20 serendipity; 3x3x3 full integration",
        "comsol_solid": "quadratic serendipity solid",
        "manifest_entries": len(rows),
        "verified_entries": sum(row["status"] == "verified" for row in rows),
        "missing_entries": missing,
        "status": "pass" if not missing else "fail",
    }
    (BASE / "experiments" / "stage2_extension_reproducibility.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(metadata, ensure_ascii=False))
    if missing:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
