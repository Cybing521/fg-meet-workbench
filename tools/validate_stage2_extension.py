"""Fail-closed validation gate for the Stage-2 extension artifacts."""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "outputs" / "paper-20260715-fgmee"


def read(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def clean_completed_log(path: Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="replace")
    return (
        "100 % - 完成" in text
        and "错误" not in text
        and "exception" not in text.lower()
        and "error" not in text.lower()
    )


def main() -> None:
    checks: list[dict[str, object]] = []

    def check(name: str, passed: bool, evidence: object) -> None:
        checks.append({"check": name, "status": "pass" if passed else "fail", "evidence": evidence})

    iso = read(BASE / "experiments" / "isomorphic_solid" / "isomorphic_solid_cross_solver_comparison.csv")
    iso_max = max(float(row["center_relative_error_pct"]) for row in iso)
    iso_free_max = max(float(row["free_mid_relative_error_pct"]) for row in iso)
    check("isomorphic_six_rows", len(iso) == 6, len(iso))
    check("isomorphic_center_error_le_0p1pct", iso_max <= 0.1, iso_max)
    check("isomorphic_free_mid_error_le_0p1pct", iso_free_max <= 0.1, iso_free_max)
    check("isomorphic_all_acceptance_gates", all(row["acceptance_gate"] == "pass" for row in iso), [row["acceptance_gate"] for row in iso])
    iso_dir = BASE / "experiments" / "isomorphic_solid" / "comsol"
    iso_logs = sorted(path for path in iso_dir.glob("comsol_isomorphic_*x.log") if "smoke" not in path.name)
    iso_models = sorted(path for path in iso_dir.glob("comsol_isomorphic_*x_Model.mph") if "smoke" not in path.name)
    check("isomorphic_comsol_six_clean_logs", len(iso_logs) == 6 and all(clean_completed_log(path) for path in iso_logs), [path.name for path in iso_logs])
    check("isomorphic_comsol_six_models", len(iso_models) == 6 and all(path.stat().st_size > 100_000 for path in iso_models), [(path.name, path.stat().st_size) for path in iso_models])
    matlab_iso = read(BASE / "experiments" / "isomorphic_solid" / "matlab_isomorphic_solid_results.csv")
    max_residual = max(float(row["relative_equilibrium_residual"]) for row in matlab_iso)
    check("matlab_h20_equilibrium_residual_le_1e_6", max_residual <= 1e-6, max_residual)

    diagnosis = read(BASE / "experiments" / "discrepancy_20x20_root_cause_decomposition.csv")
    old_curve_gap = max(float(row["apparent_gap_wrong_radius_pct"]) for row in diagnosis)
    corrected_curve_gap = max(float(row["gap_after_material_canonicalization_pct"]) for row in diagnosis)
    check("discrepancy_decomposition_six_rows", len(diagnosis) == 6, len(diagnosis))
    check(
        "wrong_radius_anomaly_closed_by_audited_inputs",
        old_curve_gap > 1.0 and corrected_curve_gap <= 0.1 and iso_max <= 0.1,
        {"old_curve_gap_pct": old_curve_gap, "corrected_curve_gap_pct": corrected_curve_gap, "isomorphic_cross_solver_max_pct": iso_max},
    )

    raw = read(BASE / "experiments" / "curvature_fg" / "curvature_fg_full_mesh_20_30_raw.csv")
    raw_keys = {
        (int(float(row["mesh"])), row["mode"], float(row["radius_m"]), row["load_case"])
        for row in raw
    }
    check("curvature_raw_48_rows", len(raw) == 48, len(raw))
    check("curvature_raw_48_unique_keys", len(raw_keys) == 48, len(raw_keys))
    check("curvature_raw_completed", all(row["status"].startswith("completed") for row in raw), sorted({row["status"] for row in raw}))

    final = read(BASE / "experiments" / "curvature_fg" / "curvature_fg_final_30x30_results.csv")
    interactions = read(BASE / "experiments" / "curvature_fg" / "curvature_fg_all_radius_interaction_30x30.csv")
    radius_summary = read(BASE / "experiments" / "curvature_fg" / "curvature_fg_all_radius_mesh_summary.csv")
    max_change = max(float(row["w_change_20_to_30_pct"]) for row in final)
    check("curvature_final_24_rows", len(final) == 24, len(final))
    check("curvature_interaction_12_rows", len(interactions) == 12, len(interactions))
    check("curvature_radius_summary_4_rows", len(radius_summary) == 4, len(radius_summary))
    check("curvature_all_1pct_mesh_gate", max_change <= 1.0, max_change)
    passport = read(BASE / "experiments" / "curvature_fg" / "curvature_fg_case_passport_audit.csv")[0]
    check(
        "curvature_material_and_radius_passport",
        passport["audit_status"] == "pass"
        and int(float(passport["U_unique_material_numeric_hashes"])) == 1
        and int(float(passport["X_unique_material_numeric_hashes"])) == 1
        and int(float(passport["radius_mismatch_count"])) == 0,
        passport,
    )

    curved = read(BASE / "experiments" / "curvature_fg" / "curved_comsol_mesh_convergence.csv")
    curved_change = float(curved[-1]["change_from_previous_pct"])
    curved_comp = read(BASE / "experiments" / "curvature_fg" / "curved_comsol_vs_matlab_model_form_comparison.csv")[0]
    check("curved_comsol_three_meshes", len(curved) == 3, len(curved))
    check("curved_comsol_15_to_20_le_1pct", curved_change <= 1.0, curved_change)
    check("curved_comsol_sign_and_scale", curved_comp["sign_check"] == "pass" and curved_comp["order_of_magnitude_check"] == "pass", {"sign": curved_comp["sign_check"], "scale": curved_comp["order_of_magnitude_check"]})
    check("curved_comparison_labeled_nonisomorphic", curved_comp["interpretation"] == "not_a_cross_solver_numerical_error", curved_comp["interpretation"])
    curved_dir = BASE / "experiments" / "curvature_fg" / "comsol"
    curved_logs = [
        curved_dir / "comsol_curved_U_R0p4_10x10x10_meshcheck.log",
        curved_dir / "comsol_curved_U_R0p4_15x15x10_meshcheck.log",
        curved_dir / "comsol_curved_U_R0p4_20x20x10_final.log",
    ]
    curved_models = [path.with_name(path.stem + "_Model.mph") for path in curved_logs]
    check("curved_comsol_three_clean_logs", all(path.is_file() and clean_completed_log(path) for path in curved_logs), [path.name for path in curved_logs])
    check("curved_comsol_three_models", all(path.is_file() and path.stat().st_size > 100_000 for path in curved_models), [(path.name, path.stat().st_size if path.is_file() else 0) for path in curved_models])

    inverse_dir = BASE / "experiments" / "inverse_actuation"
    actuation = read(inverse_dir / "inverse_actuation_comsol_validation.csv")
    cross_model = read(inverse_dir / "inverse_actuation_matlab_load_comsol_crosscheck.csv")
    conditioning = read(inverse_dir / "inverse_local_constitutive_conditioning.csv")
    sensing_status = read(inverse_dir / "inverse_sensing_evidence_status.csv")
    max_actuation_residual = max(
        max(
            float(row["comsol_voltage_forward_residual_pct"]),
            float(row["comsol_magnetic_forward_residual_pct"]),
        )
        for row in actuation
    )
    check("inverse_actuation_three_targets", len(actuation) == 3, len(actuation))
    check(
        "inverse_actuation_target_specific_comsol_residual_le_0p001pct",
        max_actuation_residual <= 0.001,
        max_actuation_residual,
    )
    check(
        "inverse_local_constitutive_scaled_condition_le_1p1",
        len(conditioning) == 1
        and float(conditioning[0]["determinant"]) > 0
        and float(conditioning[0]["dimensionless_condition_number"]) <= 1.1,
        conditioning,
    )
    cross_by_channel = {row["channel"]: row for row in cross_model}
    check(
        "inverse_actuation_matlab_load_cross_applied_to_comsol",
        len(cross_model) == 2
        and set(cross_by_channel) == {"electric", "magnetic"}
        and abs(float(cross_by_channel["electric"]["comsol_cross_applied_w_mm"]) - 0.5538629038121122) <= 1e-9
        and abs(float(cross_by_channel["magnetic"]["comsol_cross_applied_w_mm"]) - 0.5463396053249225) <= 1e-9
        and 9.0 < float(cross_by_channel["magnetic"]["comsol_target_difference_pct"]) < 10.0
        and 10.0 < float(cross_by_channel["electric"]["comsol_target_difference_pct"]) < 11.0,
        cross_model,
    )
    check(
        "inverse_sensing_explicitly_not_independent_phi_psi_pde",
        len(sensing_status) == 3
        and all(row["independent_comsol_phi_psi_pde"] == "no" for row in sensing_status)
        and all(row["reporting_status"] == "exploratory_nonindependent_constitutive_postprocess" for row in sensing_status)
        and all("KTu_u_plus_KTT_T_equals_zero" in row["thermal_boundary_for_corrected_span"] for row in sensing_status),
        sensing_status,
    )
    inverse_logs = sorted(
        path
        for path in inverse_dir.glob("comsol_inverse_actuation_*_target_*.log")
        if "matlab_load_crosscheck" not in path.name
    )
    inverse_models = sorted(
        path
        for path in inverse_dir.glob("comsol_inverse_actuation_*_target_*_Model.mph")
        if "matlab_load_crosscheck" not in path.name
    )
    check(
        "inverse_actuation_six_clean_comsol_logs",
        len(inverse_logs) == 6 and all(clean_completed_log(path) for path in inverse_logs),
        [path.name for path in inverse_logs],
    )
    check(
        "inverse_actuation_six_comsol_models",
        len(inverse_models) == 6 and all(path.stat().st_size > 100_000 for path in inverse_models),
        [(path.name, path.stat().st_size) for path in inverse_models],
    )
    cross_logs = sorted(inverse_dir.glob("comsol_inverse_actuation_*_matlab_load_crosscheck.log"))
    cross_models = sorted(inverse_dir.glob("comsol_inverse_actuation_*_matlab_load_crosscheck_Model.mph"))
    check(
        "inverse_actuation_two_clean_cross_application_logs",
        len(cross_logs) == 2 and all(clean_completed_log(path) for path in cross_logs),
        [path.name for path in cross_logs],
    )
    check(
        "inverse_actuation_two_cross_application_models",
        len(cross_models) == 2 and all(path.stat().st_size > 100_000 for path in cross_models),
        [(path.name, path.stat().st_size) for path in cross_models],
    )

    tex = BASE / "phase4_reporting" / "fgmee_latest_feasible_results_report_20260715.tex"
    tex_text = tex.read_text(encoding="utf-8")
    check("latex_placeholders_resolved", "@@" not in tex_text, [line for line in tex_text.splitlines() if "@@" in line])
    check(
        "report_model_and_load_explanation_complete",
        all(
            token in tex_text
            for token in (
                "300\\,\\mathrm{mm}\\times300\\,\\mathrm{mm}\\times6\\,\\mathrm{mm}",
                "|\\Delta\\phi_{\\ell}|=300",
                "|\\Delta\\psi_{\\ell}|=200",
                "\\boldsymbol\\sigma^{E}=-\\mathbf e^{\\mathsf T}\\mathbf E",
                "\\boldsymbol\\sigma^{H}=-\\mathbf q^{\\mathsf T}\\mathbf H",
                "\\label{tab:iso_free_mid}",
                "-0.2422879984",
                "0.8109578441",
                "磁标势之差，不表示 200 A 电流",
                "x=L-10^{-9}",
                "沿用的是载荷数值",
                "不把差异唯一归因于舍入",
            )
        ),
        "geometry, potential-to-stress conversion, evidence-qualified wording, and six free-midpoint rows",
    )
    check(
        "latest_report_scope_wording",
        "数值实验" in tex_text
        and "实物样件" in tex_text
        and "加载反算" in tex_text
        and "感生势反算" in tex_text
        and "不是外加载势" in tex_text
        and "尚无独立场 PDE" in tex_text
        and "自洽回代" in tex_text
        and "交叉施加" in tex_text
        and "无外加热源" in tex_text
        and "强制等温" in tex_text
        and "数据追溯与质量控制" not in tex_text
        and "AI 使用说明" not in tex_text
        and "全部结果尚无实验数据支撑" not in tex_text,
        {
            "has_numerical_experiment": "数值实验" in tex_text,
            "has_physical_specimen_boundary": "实物样件" in tex_text,
            "removed_traceability_tail": "数据追溯与质量控制" not in tex_text,
        },
    )
    for number in (3, 4, 5):
        for suffix in ("png", "pdf"):
            matches = list((BASE / "figures").glob(f"Fig_0{number}_*.{suffix}"))
            check(f"figure_{number}_{suffix}", len(matches) == 1 and matches[0].stat().st_size > 1000 if matches else False, [str(path) for path in matches])
    for stem in ("Fig_00_curved_shell_geometry_loads", "Fig_00_material_boundary_loads"):
        for suffix in ("png", "pdf"):
            figure = BASE / "figures" / f"{stem}.{suffix}"
            check(
                f"{stem}_{suffix}",
                figure.is_file() and figure.stat().st_size > 1000,
                str(figure),
            )
    figure_script = ROOT / "tools" / "plotting" / "plot_model_geometry_loads.py"
    figure_provenance = BASE / "figures" / "model_schematic_provenance.md"
    requirement_recheck = BASE / "phase4_reporting" / "fgmee_requirement_recheck_20260718.md"
    check("model_figure_script_exists", figure_script.is_file() and figure_script.stat().st_size > 1000, str(figure_script))
    check("model_figure_provenance_exists", figure_provenance.is_file() and figure_provenance.stat().st_size > 100, str(figure_provenance))
    requirement_text = requirement_recheck.read_text(encoding="utf-8") if requirement_recheck.is_file() else ""
    check(
        "screenshot_requirements_R1_to_R9_traced",
        requirement_recheck.is_file()
        and all(f"| R{number} |" in requirement_text for number in range(1, 10))
        and "九项需求均已落实" in requirement_text,
        str(requirement_recheck),
    )
    pdf = BASE / "phase4_reporting" / "fgmee_latest_feasible_results_report_20260715.pdf"
    check("compiled_pdf_exists", pdf.is_file() and pdf.stat().st_size > 10_000, str(pdf))

    passed = all(row["status"] == "pass" for row in checks)
    payload = {"status": "pass" if passed else "fail", "checks": checks}
    out_json = BASE / "experiments" / "stage2_extension_validation_gate.json"
    out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    lines = ["# Stage-2 扩展验证门槛", "", f"总体状态：{'通过' if passed else '未通过'}", "", "| 检查 | 状态 | 证据 |", "|---|---|---|"]
    for row in checks:
        evidence = str(row["evidence"]).replace("|", "/").replace("\n", " ")
        lines.append(f"| {row['check']} | {row['status']} | {evidence} |")
    (BASE / "phase4_reporting" / "fgmee_latest_feasible_results_report_20260715_quality_check.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({"status": payload["status"], "check_count": len(checks)}, ensure_ascii=False))
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
