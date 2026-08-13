"""Rebuild the inverse-potential audit from frozen MATLAB, COMSOL and Qian evidence."""

from __future__ import annotations

import csv
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PAPER = ROOT / "outputs" / "paper-20260715-fgmee"
EXPERIMENTS = PAPER / "experiments"
OUT = EXPERIMENTS / "inverse_actuation"
SENSING = EXPERIMENTS / "inverse_sensing"
COMSOL = EXPERIMENTS / "comsol"

TARGETS_MM = (0.5, 1.0, 2.0)
MATLAB_ELECTRIC_DISP_AT_300V_MM = 0.0522570949262148
MATLAB_MAGNETIC_DISP_AT_200A_MM = 0.174585747179692
COMSOL_ELECTRIC_DISP_AT_300V_MM = 0.05788658848890287
COMSOL_MAGNETIC_DISP_AT_200A_MM = 0.19076621638710417
QIAN_ELECTRIC_PRESENT_AT_300V_MM = 0.0523
QIAN_ELECTRIC_COMSOL_AT_300V_MM = 0.0523
QIAN_MAGNETIC_PRESENT_AT_200A_MM = 0.175
QIAN_MAGNETIC_COMSOL_AT_200A_MM = 0.173


def read_one(path: Path) -> dict[str, str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return next(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def relative_difference(value: float, reference: float) -> float:
    return abs(value - reference) / abs(reference) * 100.0


def target_tag(target: float) -> str:
    return f"{target:.1f}".replace(".", "p")


def required_load(target: float, reference_load: float, response: float) -> float:
    return target * reference_load / abs(response)


def build_actuation_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for target in TARGETS_MM:
        tag = target_tag(target)
        electric_summary = read_one(
            OUT / f"comsol_inverse_actuation_electric_target_{tag}mm_summary.csv"
        )
        magnetic_summary = read_one(
            OUT / f"comsol_inverse_actuation_magnetic_target_{tag}mm_summary.csv"
        )

        matlab_voltage = required_load(target, 300.0, MATLAB_ELECTRIC_DISP_AT_300V_MM)
        comsol_voltage = required_load(target, 300.0, COMSOL_ELECTRIC_DISP_AT_300V_MM)
        matlab_magnetic = required_load(target, 200.0, MATLAB_MAGNETIC_DISP_AT_200A_MM)
        comsol_magnetic = required_load(target, 200.0, COMSOL_MAGNETIC_DISP_AT_200A_MM)
        solved_electric_w = abs(float(electric_summary["w_center_mm"]))
        solved_magnetic_w = abs(float(magnetic_summary["w_center_mm"]))

        rows.append(
            {
                "target_abs_w_mm": target,
                "matlab_required_voltage_V": matlab_voltage,
                "comsol_required_voltage_V": comsol_voltage,
                "comsol_voltage_vs_matlab_pct": (comsol_voltage / matlab_voltage - 1.0) * 100.0,
                "comsol_voltage_forward_check_w_mm": solved_electric_w,
                "comsol_voltage_forward_residual_pct": relative_difference(solved_electric_w, target),
                "qian_present_required_voltage_V": required_load(
                    target, 300.0, QIAN_ELECTRIC_PRESENT_AT_300V_MM
                ),
                "qian_comsol_required_voltage_V": required_load(
                    target, 300.0, QIAN_ELECTRIC_COMSOL_AT_300V_MM
                ),
                "matlab_required_magnetic_potential_A": matlab_magnetic,
                "comsol_required_magnetic_potential_A": comsol_magnetic,
                "comsol_magnetic_vs_matlab_pct": (comsol_magnetic / matlab_magnetic - 1.0) * 100.0,
                "comsol_magnetic_forward_check_w_mm": solved_magnetic_w,
                "comsol_magnetic_forward_residual_pct": relative_difference(solved_magnetic_w, target),
                "qian_present_required_magnetic_potential_A": required_load(
                    target, 200.0, QIAN_MAGNETIC_PRESENT_AT_200A_MM
                ),
                "qian_comsol_required_magnetic_potential_A": required_load(
                    target, 200.0, QIAN_MAGNETIC_COMSOL_AT_200A_MM
                ),
                "status": "completed_target_specific_comsol_direct_field_check_nonisomorphic",
            }
        )
    return rows


def build_conditioning_rows() -> list[dict[str, object]]:
    young = 1.206e11
    nu = 0.3398
    d31 = -5.404e-11
    c11 = young / (1.0 - nu * nu)
    c12 = young * nu / (1.0 - nu * nu)
    e31 = d31 * (c11 + c12)
    g_effective = 9.203e-9 - 2.0 * d31 * e31
    k33 = 1.755e-8
    r33 = 7.536e-5
    determinant = g_effective * r33 - k33 * k33
    rho = k33 / math.sqrt(g_effective * r33)
    scaled_condition = (1.0 + abs(rho)) / (1.0 - abs(rho))
    return [
        {
            "c11_Pa": c11,
            "c12_Pa": c12,
            "e31_C_per_m2": e31,
            "g_effective": g_effective,
            "k33": k33,
            "r33": r33,
            "determinant": determinant,
            "normalized_coupling_rho": rho,
            "dimensionless_condition_number": scaled_condition,
            "verdict": "well_conditioned_after_unit_scaling",
        }
    ]


def build_cross_model_rows() -> list[dict[str, object]]:
    target = 0.5
    rows: list[dict[str, object]] = []
    cases = (
        (
            "electric",
            required_load(target, 300.0, MATLAB_ELECTRIC_DISP_AT_300V_MM),
            OUT / "comsol_inverse_actuation_electric_target_0p5mm_matlab_load_crosscheck_summary.csv",
        ),
        (
            "magnetic",
            required_load(target, 200.0, MATLAB_MAGNETIC_DISP_AT_200A_MM),
            OUT / "comsol_inverse_actuation_magnetic_target_0p5mm_matlab_load_crosscheck_summary.csv",
        ),
    )
    for channel, applied_load, path in cases:
        solved = abs(float(read_one(path)["w_center_mm"]))
        rows.append(
            {
                "channel": channel,
                "target_abs_w_mm": target,
                "matlab_inverted_load": applied_load,
                "comsol_cross_applied_w_mm": solved,
                "comsol_w_over_target": solved / target,
                "comsol_target_difference_pct": (solved / target - 1.0) * 100.0,
                "interpretation": "nonisomorphic_model_form_difference_not_solver_failure",
            }
        )
    return rows


def build_sensing_status_rows() -> list[dict[str, object]]:
    comparison_path = SENSING / "inverse_sensor_corrected_comparison.csv"
    with comparison_path.open("r", encoding="utf-8-sig", newline="") as handle:
        comparison = list(csv.DictReader(handle))
    rows: list[dict[str, object]] = []
    for row in comparison:
        if int(row["mesh_inplane"]) != 20:
            continue
        rows.append(
            {
                "target_abs_w_mm": float(row["target_w_mm"]),
                "matlab_zero_temperature_layer_span_V": float(row["matlab_zero_e_V"]),
                "three_d_mechanics_zero_temperature_layer_span_V": float(row["comsol_zero_e_V"]),
                "matlab_zero_temperature_layer_span_A": float(row["matlab_zero_m_A"]),
                "three_d_mechanics_zero_temperature_layer_span_A": float(row["comsol_zero_m_A"]),
                "matlab_layer_span_V": float(row["matlab_corrected_e_V"]),
                "three_d_mechanics_postprocess_layer_span_V": float(row["comsol_corrected_e_V"]),
                "matlab_layer_span_A": float(row["matlab_corrected_m_A"]),
                "three_d_mechanics_postprocess_layer_span_A": float(row["comsol_corrected_m_A"]),
                "shared_mechanical_scale_difference_pct": float(row["corrected_e_error_pct"]),
                "observable_definition": "max_minus_min_of_layerwise_potential_difference_dofs",
                "thermal_boundary_for_corrected_span": (
                    "no_external_thermal_load_with_reciprocal_temperature_response_"
                    "from_KTu_u_plus_KTT_T_equals_zero"
                ),
                "independent_comsol_phi_psi_pde": "no",
                "reporting_status": "exploratory_nonindependent_constitutive_postprocess",
            }
        )
    return rows


def main() -> None:
    actuation = build_actuation_rows()
    cross_model = build_cross_model_rows()
    conditioning = build_conditioning_rows()
    sensing = build_sensing_status_rows()
    write_csv(OUT / "inverse_actuation_comsol_validation.csv", actuation)
    write_csv(OUT / "inverse_actuation_matlab_load_comsol_crosscheck.csv", cross_model)
    write_csv(OUT / "inverse_local_constitutive_conditioning.csv", conditioning)
    write_csv(OUT / "inverse_sensing_evidence_status.csv", sensing)

    max_e_residual = max(float(row["comsol_voltage_forward_residual_pct"]) for row in actuation)
    max_m_residual = max(float(row["comsol_magnetic_forward_residual_pct"]) for row in actuation)
    max_residual = max(max_e_residual, max_m_residual)
    # Target-specific direct-field solves include interpolation and stationary
    # solver tolerances.  A 0.001% gate remains far below the model-form
    # differences being audited while accepting the observed numerical noise.
    if max_residual > 1e-3:
        raise RuntimeError(f"COMSOL inverse-actuation forward residual too large: {max_residual}%")

    print(f"actuation_rows={len(actuation)}")
    print(f"cross_model_rows={len(cross_model)}")
    print(f"sensing_rows={len(sensing)}")
    print(f"max_comsol_forward_residual_pct={max_residual:.12g}")
    print(f"output={OUT / 'inverse_actuation_comsol_validation.csv'}")


if __name__ == "__main__":
    main()
