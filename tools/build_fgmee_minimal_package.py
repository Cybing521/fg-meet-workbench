#!/usr/bin/env python3
"""Build the whitelisted, latest-results-only FG-MEE delivery package."""

from __future__ import annotations

import csv
import hashlib
import json
import math
import shutil
import zipfile
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_NAME = "fgmee_final_delivery_20260720"
OUTPUTS = ROOT / "outputs"
TARGET = OUTPUTS / PACKAGE_NAME
ZIP_PATH = OUTPUTS / f"{PACKAGE_NAME}.zip"
PAPER = ROOT / "outputs" / "paper-20260715-fgmee"
TEMPLATES = ROOT / "tools" / "package_fgmee"
CODE_CLOSURE_REPORT_RELATIVE = Path("outputs/code_closure/CODE_CLOSURE_SIX_STEP_REPORT.md")
SOURCE_PROVENANCE: list[dict[str, str]] = []

CORE_MATLAB = [
    "Main_FOSDLIN851T5MEET_V4.m",
    "SF_Assembling.m",
    "SF_Condensation.m",
    "SF_ElemComptLIN851T5MEEP_V4.m",
    "SF_FEMtoSSM_3.m",
    "SF_GetFusVect.m",
    "SF_GetInputDataMEEP.m",
    "SF_GetMatePropMEEP.m",
    "SF_GetUsedData.m",
    "SF_InitGlobMatr.m",
    "SF_InputFileCheckMEEP.m",
    "SF_ShellNotation.m",
    "SF_Totalthickness.m",
]

RUNTIME_MATLAB_HELPERS = [
    "build_active_layer_dof_map.m",
    "interpolate_shell_dof_at_point.m",
]

RESIDUAL_DEFINITION = (
    "mechanical=global_force_balance;"
    "weak_moment=max_layer_normalized_constitutive_flux_moment;"
    "discrete_group_error=max_final_outer_iteration_error_by_field;"
    "solver_linear_residual=max_final_inner_LinRes_by_field"
)
PHYSICS_RESIDUAL_LIMIT = 1.0e-6
SOLVER_CONVERGENCE_LIMIT = 1.0e-5
SOLVER_RELATIVE_TOLERANCE = 1.0e-4
PHYSICAL_RESIDUALS = (
    "mechanical_force_balance_residual",
    "electric_weak_moment_residual",
    "magnetic_weak_moment_residual",
    "thermal_weak_moment_residual",
)
DISCRETE_GROUP_RESIDUALS = (
    "solid_discrete_segregated_group_relative_error",
    "electric_discrete_segregated_group_relative_error",
    "magnetic_discrete_segregated_group_relative_error",
    "thermal_discrete_segregated_group_relative_error",
)
FIELD_SOLVER_RESIDUALS = (
    "solid_solver_linear_residual",
    "electric_solver_linear_residual",
    "magnetic_solver_linear_residual",
    "thermal_solver_linear_residual",
)
SOLVER_CONVERGENCE_RESIDUALS = (
    *DISCRETE_GROUP_RESIDUALS,
    *FIELD_SOLVER_RESIDUALS,
    "solver_linear_residual",
)
COMSOL_RESIDUAL_FIELDS = (*PHYSICAL_RESIDUALS, *SOLVER_CONVERGENCE_RESIDUALS)
LEGACY_RESIDUAL_FIELDS = (
    "mechanical_residual",
    "electric_charge_residual",
    "magnetic_flux_residual",
    "thermal_residual",
    "solver_linres",
)


def preflight_code_closure_sources() -> None:
    required = [
        ROOT / "matlab" / "run_meet_static.m",
        *(ROOT / "matlab" / name for name in RUNTIME_MATLAB_HELPERS),
        ROOT / "tools" / "comsol" / "RunBlockTriangularInverseSensorCfffValidation.java",
        ROOT / CODE_CLOSURE_REPORT_RELATIVE,
        ROOT
        / "outputs"
        / "code_closure"
        / "inverse_sensing"
        / "matlab_inverse_structural_pyro_mesh.csv",
        ROOT
        / "outputs"
        / "code_closure"
        / "comsol_four_field"
        / "comsol_four_field_summary.csv",
        ROOT
        / "outputs"
        / "code_closure"
        / "comsol_four_field"
        / "comsol_four_field_layers.csv",
        ROOT
        / "outputs"
        / "code_closure"
        / "comsol_four_field"
        / "comsol_four_field_physics_manifest.csv",
        ROOT
        / "outputs"
        / "code_closure"
        / "comsol_four_field"
        / "comsol_four_field_channel_isolation.csv",
        ROOT
        / "outputs"
        / "code_closure"
        / "comsol_four_field"
        / "comsol_four_field_Model.mph",
    ]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError(
            "Formal four-field code-closure sources are incomplete; package was not modified:\n"
            + "\n".join(missing)
        )
    manifest_path = (
        ROOT
        / "outputs"
        / "code_closure"
        / "comsol_four_field"
        / "comsol_four_field_physics_manifest.csv"
    )
    _, manifest_rows = read_csv(manifest_path)
    if len(manifest_rows) != 1:
        raise RuntimeError("Formal COMSOL physics manifest must contain exactly one case")
    manifest = manifest_rows[0]
    expected = {
        "physical_layer_count": "10",
        "fg_mode": "U",
        "isomorphic_to_matlab_10layer": "false",
        "comparison_scope": (
            "same_geometry_material_boundary_observable_nonisomorphic_mechanics"
        ),
        "mechanical_discretization": (
            "COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell"
        ),
        "method": "sequential_equivalent_four_field_solution",
        "evidence_tier": "A_independent_block_triangular_fields",
        "solver_strategy": "segregated_same_stationary",
        "convergence_termination": (
            "fixed_25_segregated_iterations_with_final_residual_gate"
        ),
        "direct_error_check": "auto_enabled",
        "segregated_termination": "iter",
        "layer_field_layout": "independent_per_physical_layer",
        "observable_definition": (
            "max_minus_min_of_layer_top_bottom_area_average_potential_difference"
        ),
        "layer_drop_definition": (
            "layer_thickness_times_volume_average_potential_gradient_equivalent_to_face_average_difference"
        ),
        "status": "completed_full_field",
    }
    mismatches = [
        f"{field}={manifest.get(field, '<missing>')}"
        for field, value in expected.items()
        if manifest.get(field, "").strip() != value
    ]
    try:
        vf0_matches = abs(float(manifest["vf0"]) - 0.6) <= 1.0e-12
    except (KeyError, TypeError, ValueError):
        vf0_matches = False
    if not vf0_matches:
        mismatches.append(f"vf0={manifest.get('vf0', '<missing>')}")
    try:
        fixed_segregated_iterations = float(manifest["fixed_segregated_iterations"])
    except (KeyError, TypeError, ValueError):
        fixed_segregated_iterations = math.nan
    if (
        not math.isfinite(fixed_segregated_iterations)
        or not fixed_segregated_iterations.is_integer()
        or fixed_segregated_iterations != 25.0
    ):
        mismatches.append("fixed_segregated_iterations_not_25")
    for field in (
        "solve_u",
        "solve_phi",
        "solve_psi",
        "solve_T",
        "same_stationary",
        "open_circuit_electric",
        "open_circuit_magnetic",
        "insulated_thermal",
        "independent_dof_fields",
        "coupling_equivalent_to_matlab",
        "geometry_material_boundary_layer_observable_aligned",
    ):
        if manifest.get(field, "").lower() != "true":
            mismatches.append(f"{field}={manifest.get(field, '<missing>')}")
    if manifest.get("api_channel_isolation_status", "").lower() != "pass":
        mismatches.append("api_channel_isolation_status_not_pass")
    if manifest.get("field_residual_evaluation_status") != "pass":
        mismatches.append("field_residual_evaluation_status_not_pass")
    if manifest.get("solver_has_problems", "").lower() != "false":
        mismatches.append("solver_has_problems")
    for field, expected_limit in (
        ("physics_residual_limit", PHYSICS_RESIDUAL_LIMIT),
        ("solver_convergence_limit", SOLVER_CONVERGENCE_LIMIT),
        ("solver_relative_tolerance", SOLVER_RELATIVE_TOLERANCE),
    ):
        try:
            declared_limit = float(manifest[field])
        except (KeyError, TypeError, ValueError):
            declared_limit = math.nan
        if not math.isclose(
            declared_limit, expected_limit, rel_tol=0.0, abs_tol=1.0e-15
        ):
            mismatches.append(f"{field}_invalid")
    if not manifest.get("run_id", ""):
        mismatches.append("run_id_missing")
    producer_source = (
        ROOT / "tools" / "comsol" / "RunBlockTriangularInverseSensorCfffValidation.java"
    )
    producer_digest = file_sha256(producer_source).lower()
    if manifest.get("source_sha256", "").lower() != producer_digest:
        mismatches.append("source_sha256_does_not_match_formal_producer")
    if manifest.get("residual_definition") != RESIDUAL_DEFINITION:
        mismatches.append("residual_definition_mismatch")
    legacy_present = [field for field in LEGACY_RESIDUAL_FIELDS if field in manifest]
    if legacy_present:
        mismatches.append(f"legacy_residual_fields={legacy_present}")
    residual_values: dict[str, float] = {}
    for field in COMSOL_RESIDUAL_FIELDS:
        try:
            residual = float(manifest[field])
        except (KeyError, TypeError, ValueError):
            residual = math.nan
        residual_values[field] = residual
        limit = (
            PHYSICS_RESIDUAL_LIMIT
            if field in PHYSICAL_RESIDUALS
            else SOLVER_CONVERGENCE_LIMIT
        )
        if not math.isfinite(residual) or residual < 0.0 or residual > limit:
            mismatches.append(f"{field}={manifest.get(field, '<missing>')}")
    if all(field in residual_values for field in FIELD_SOLVER_RESIDUALS):
        expected_global = max(residual_values[field] for field in FIELD_SOLVER_RESIDUALS)
        if not math.isclose(
            residual_values["solver_linear_residual"],
            expected_global,
            rel_tol=1.0e-9,
            abs_tol=1.0e-15,
        ):
            mismatches.append("solver_linear_residual_not_group_max")
    global_solver = residual_values.get("solver_linear_residual", math.nan)
    physical_values = [residual_values.get(field, math.nan) for field in PHYSICAL_RESIDUALS]
    if (
        math.isfinite(global_solver)
        and global_solver > 0.0
        and all(math.isfinite(value) for value in physical_values)
        and all(
            math.isclose(value, global_solver, rel_tol=0.0, abs_tol=1.0e-15)
            for value in physical_values
        )
    ):
        mismatches.append("copied_LinRes_pseudoresiduals")
    if mismatches:
        raise RuntimeError(
            "COMSOL evidence is not the formal ten-layer nonisomorphic-mechanics configuration; "
            "package was not modified: " + ", ".join(mismatches)
        )
    isolation_path = manifest_path.with_name("comsol_four_field_channel_isolation.csv")
    _, isolation_rows = read_csv(isolation_path)
    expected_gates = {
        "electric": ("1", "0", "0"),
        "magnetic": ("0", "1", "0"),
        "thermal": ("0", "0", "1"),
    }
    isolation_by_channel = {row.get("channel", ""): row for row in isolation_rows}
    if set(isolation_by_channel) != set(expected_gates):
        raise RuntimeError("COMSOL channel-isolation evidence is incomplete")
    for channel, gates in expected_gates.items():
        row = isolation_by_channel[channel]
        if (
            (row.get("gateE"), row.get("gateM"), row.get("gateT")) != gates
            or row.get("isolation_status", "").lower() != "pass"
        ):
            raise RuntimeError(f"COMSOL {channel} channel-isolation evidence failed")
    summary_path = manifest_path.with_name("comsol_four_field_summary.csv")
    _, summary_rows = read_csv(summary_path)
    try:
        targets = sorted(float(row["target_w_mm"]) for row in summary_rows)
    except (KeyError, TypeError, ValueError) as exc:
        raise RuntimeError("COMSOL four-field summary has invalid target rows") from exc
    if targets != [0.5, 1.0, 2.0]:
        raise RuntimeError(
            f"COMSOL four-field summary targets are {targets}, expected [0.5, 1.0, 2.0]"
        )
    for row in summary_rows:
        if (
            row.get("status") != "completed_full_field"
            or row.get("evidence_tier") != "A_independent_block_triangular_fields"
        ):
            raise RuntimeError("COMSOL four-field summary is not completed A-tier evidence")
        if (
            row.get("case_id") != manifest.get("case_id")
            or row.get("physical_layer_count") != "10"
            or row.get("mesh_divisions") != manifest.get("mesh_divisions")
            or row.get("thickness_divisions_per_layer")
            != manifest.get("thickness_divisions_per_layer")
            or row.get("target_solution_mode") != "independent_stationary_resolve"
            or row.get("run_id") != manifest.get("run_id")
            or row.get("source_sha256", "").lower()
            != manifest.get("source_sha256", "").lower()
        ):
            raise RuntimeError("COMSOL summary and physics manifest configurations do not match")

    matlab_path = (
        ROOT
        / "outputs"
        / "code_closure"
        / "inverse_sensing"
        / "matlab_inverse_structural_pyro_mesh.csv"
    )
    _, matlab_rows = read_csv(matlab_path)
    matlab_by_key = {
        (int(row["mesh_divisions"]), float(row["target_w_mm"])): row
        for row in matlab_rows
    }
    if len(matlab_by_key) != len(matlab_rows):
        raise RuntimeError("Formal MATLAB inverse results contain duplicate mesh/target keys")
    accuracy_errors: list[str] = []
    for row in summary_rows:
        key = (int(row["mesh_divisions"]), float(row["target_w_mm"]))
        matlab_row = matlab_by_key.get(key)
        if matlab_row is None:
            accuracy_errors.append(f"missing_matlab:{key}")
            continue
        if (
            matlab_row.get("solver_revision") != "layer_local_pyro_v3"
            or matlab_row.get("solve_status") != "ok"
            or matlab_row.get("sensor_status") != "ok"
            or "U_Vf0.6" not in matlab_row.get("input_file", "")
            or "10layer" not in matlab_row.get("input_file", "")
        ):
            accuracy_errors.append(f"matlab_contract:{key}")
            continue
        try:
            matlab_residuals = (
                float(matlab_row["mechanical_thermal_relative_residual"]),
                float(matlab_row["sensor_relative_residual"]),
            )
            matlab_e = float(matlab_row["electric_span_V"])
            matlab_m = float(matlab_row["magnetic_span_A"])
            comsol_e = float(row["comsol_electric_V"])
            comsol_m = float(row["comsol_magnetic_A"])
        except (KeyError, TypeError, ValueError):
            accuracy_errors.append(f"invalid_numeric:{key}")
            continue
        values = (*matlab_residuals, matlab_e, matlab_m, comsol_e, comsol_m)
        if not all(math.isfinite(value) for value in values):
            accuracy_errors.append(f"nonfinite:{key}")
            continue
        if any(value < 0.0 or value > 1.0e-8 for value in matlab_residuals):
            accuracy_errors.append(f"matlab_residual:{key}")
        electric_error = 100.0 * abs(comsol_e - matlab_e) / max(abs(matlab_e), 1.0e-300)
        magnetic_error = 100.0 * abs(comsol_m - matlab_m) / max(abs(matlab_m), 1.0e-300)
        if electric_error > 5.0 or magnetic_error > 5.0:
            accuracy_errors.append(
                f"cross_model_error:{key}:electric={electric_error:.9g}%:magnetic={magnetic_error:.9g}%"
            )
    if accuracy_errors:
        raise RuntimeError(
            "Formal inverse cross-model discrepancy gate failed; package was not modified: "
            + ";".join(accuracy_errors)
        )


def require(path: Path) -> Path:
    if not path.is_file():
        raise FileNotFoundError(path)
    return path


def copy_file(source: Path, relative_target: str) -> Path:
    source = require(source)
    destination = TARGET / relative_target
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    source_digest = file_sha256(source)
    package_digest = file_sha256(destination)
    if source_digest != package_digest:
        raise RuntimeError(f"Direct-copy hash mismatch: {source} -> {destination}")
    try:
        source_label = source.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        source_label = str(source.resolve())
    SOURCE_PROVENANCE.append(
        {
            "source_path": source_label,
            "package_path": relative_target.replace("\\", "/"),
            "source_sha256": source_digest,
            "package_sha256": package_digest,
        }
    )
    return destination


def write_text(relative_target: str, content: str) -> Path:
    destination = TARGET / relative_target
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(content, encoding="utf-8", newline="\n")
    return destination


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with require(path).open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return list(reader.fieldnames or []), list(reader)


def write_csv(relative_target: str, fieldnames: list[str], rows: list[dict[str, object]]) -> Path:
    destination = TARGET / relative_target
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    return destination


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def clean_target() -> None:
    SOURCE_PROVENANCE.clear()
    target = TARGET.resolve()
    output_root = OUTPUTS.resolve()
    if target.parent != output_root or target.name != PACKAGE_NAME:
        raise RuntimeError(f"Refusing to clear unexpected path: {target}")
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    if ZIP_PATH.exists():
        ZIP_PATH.unlink()


def copy_runtime_code() -> None:
    for name in ["RUN_CHECK.ps1", "RUN_MATLAB.ps1", "RUN_COMSOL.ps1"]:
        copy_file(TEMPLATES / name, name)
    copy_file(TEMPLATES / "python" / "validate_package.py", "code/python/validate_package.py")
    copy_file(TEMPLATES / "python" / "requirements.txt", "code/python/requirements.txt")
    copy_file(TEMPLATES / "matlab" / "setup_paths.m", "code/matlab/setup_paths.m")
    copy_file(
        TEMPLATES / "matlab" / "jobs" / "run_isomorphic_validation.m",
        "code/matlab/jobs/run_isomorphic_validation.m",
    )
    copy_file(
        TEMPLATES / "matlab" / "jobs" / "run_curvature_validation.m",
        "code/matlab/jobs/run_curvature_validation.m",
    )
    copy_file(
        TEMPLATES / "matlab" / "jobs" / "run_inverse_validation.m",
        "code/matlab/jobs/run_inverse_validation.m",
    )
    copy_file(
        ROOT / "matlab" / "run_meet_static.m",
        "code/matlab/lib/run_meet_static.m",
    )
    copy_file(
        ROOT / "matlab" / "run_isomorphic_solid_cfff.m",
        "code/matlab/lib/run_isomorphic_solid_cfff.m",
    )
    for name in RUNTIME_MATLAB_HELPERS:
        copy_file(ROOT / "matlab" / name, f"code/matlab/lib/{name}")
    for name in CORE_MATLAB:
        copy_file(ROOT / "matlab" / "meet-fem-core" / name, f"code/matlab/lib/meet_core/{name}")

    for name in (
        "RunIsomorphicSolidCfffValidation.java",
        "RunCurvedSolidCfffValidation.java",
        "RunBlockTriangularInverseSensorCfffValidation.java",
    ):
        copy_file(ROOT / "tools" / "comsol" / name, f"code/comsol/{name}")


def copy_cases() -> None:
    for mesh in (10, 15, 20, 30):
        name = f"Thermal_CFFF_U_Vf0.6-{mesh}x{mesh}-10layer.txt"
        copy_file(ROOT / "cases" / "validation_mesh" / name, f"cases/inverse/{name}")
    for mesh in (20, 30):
        source_dir = ROOT / "cases" / "curvature_fg" / f"{mesh}x{mesh}"
        cases = sorted(source_dir.glob("Thermal_CFFF_[UX]_Vf0.6_R*m-*-10layer.txt"))
        if len(cases) != 8:
            raise RuntimeError(f"Expected 8 final cases for mesh {mesh}, found {len(cases)}")
        for case in cases:
            copy_file(case, f"cases/curvature/{mesh}x{mesh}/{case.name}")


def copy_isomorphic_results() -> None:
    source_dir = PAPER / "experiments" / "isomorphic_solid"
    comsol_dir = source_dir / "comsol"
    fields, rows = read_csv(source_dir / "isomorphic_solid_cross_solver_comparison.csv")
    for row in rows:
        load = row["load_case"]
        mesh = int(row["inplane_divisions"])
        short = "electric" if load == "electric_equivalent_stress" else "magnetic"
        source_name = f"comsol_isomorphic_{load}_{mesh}x_summary.csv"
        target_name = f"results/isomorphic/comsol_runs/{short}_{mesh}x_summary.csv"
        copy_file(comsol_dir / source_name, target_name)
        row["comsol_source_file"] = target_name
    write_csv("results/isomorphic/cross_solver_comparison.csv", fields, rows)
    copy_file(source_dir / "matlab_isomorphic_solid_results.csv", "results/isomorphic/matlab_mesh_results.csv")


def copy_curvature_results() -> None:
    source_dir = PAPER / "experiments" / "curvature_fg"
    comsol_dir = source_dir / "comsol"
    mappings = {
        "curvature_fg_final_30x30_results.csv": "results/curvature/final_30x30_results.csv",
        "curvature_fg_all_radius_interaction_30x30.csv": "results/curvature/all_radius_interaction_30x30.csv",
        "curvature_fg_all_radius_mesh_summary.csv": "results/curvature/all_radius_mesh_summary.csv",
        "curvature_fg_case_passport_audit.csv": "results/curvature/case_passport_audit.csv",
        "curved_comsol_vs_matlab_model_form_comparison.csv": "results/curvature/curved_comsol_vs_matlab_model_form.csv",
    }
    for source_name, target_name in mappings.items():
        copy_file(source_dir / source_name, target_name)

    fields, rows = read_csv(source_dir / "curvature_fg_full_mesh_20_30_raw.csv")
    for row in rows:
        mesh = int(row["mesh"])
        row["case_file"] = f"cases/curvature/{mesh}x{mesh}/{Path(row['case_file']).name}"
    write_csv("results/curvature/full_mesh_20_30_raw.csv", fields, rows)

    fields, rows = read_csv(source_dir / "curved_comsol_mesh_convergence.csv")
    for row in rows:
        mesh = int(row["axial_divisions"])
        source_tag = {
            10: "10x10x10_meshcheck",
            15: "15x15x10_meshcheck",
            20: "20x20x10_final",
        }[mesh]
        target_name = f"results/curvature/comsol_runs/curved_mesh{mesh}_summary.csv"
        copy_file(comsol_dir / f"comsol_curved_U_R0p4_{source_tag}_summary.csv", target_name)
        row["source_file"] = target_name
    write_csv("results/curvature/curved_comsol_mesh_convergence.csv", fields, rows)
    copy_file(
        comsol_dir / "comsol_curved_U_R0p4_20x20x10_final_midarc.csv",
        "results/curvature/comsol_runs/curved_mesh20_midarc.csv",
    )


def copy_inverse_results() -> None:
    matlab_source = (
        ROOT
        / "outputs"
        / "code_closure"
        / "inverse_sensing"
        / "matlab_inverse_structural_pyro_mesh.csv"
    )
    comsol_source_dir = ROOT / "outputs" / "code_closure" / "comsol_four_field"
    comsol_summary = comsol_source_dir / "comsol_four_field_summary.csv"
    comsol_layers = comsol_source_dir / "comsol_four_field_layers.csv"
    comsol_manifest = comsol_source_dir / "comsol_four_field_physics_manifest.csv"
    comsol_isolation = comsol_source_dir / "comsol_four_field_channel_isolation.csv"

    copy_file(matlab_source, "results/inverse/matlab_inverse_structural_pyro_mesh.csv")
    copy_file(comsol_summary, "results/inverse/comsol_four_field_summary.csv")
    copy_file(comsol_layers, "results/inverse/comsol_four_field_layers.csv")
    copy_file(comsol_manifest, "results/inverse/comsol_four_field_physics_manifest.csv")
    copy_file(comsol_isolation, "results/inverse/comsol_four_field_channel_isolation.csv")

    _, matlab_rows = read_csv(matlab_source)
    _, comsol_rows = read_csv(comsol_summary)
    _, manifest_rows = read_csv(comsol_manifest)
    manifest = manifest_rows[0]
    matlab_by_key: dict[tuple[int, float], dict[str, str]] = {}
    for row in matlab_rows:
        key = (int(row["mesh_divisions"]), float(row["target_w_mm"]))
        if key in matlab_by_key:
            raise RuntimeError(f"Duplicate MATLAB inverse result key: {key}")
        matlab_by_key[key] = row

    output_fields = [
        "mesh_divisions",
        "thickness_divisions_per_layer",
        "physical_layer_count",
        "fg_mode",
        "vf0",
        "isomorphic_to_matlab_10layer",
        "comparison_scope",
        "mechanical_discretization",
        "method",
        "solver_strategy",
        "coupling_equivalent_to_matlab",
        "observable_definition",
        "target_w_mm",
        "comsol_electric_V",
        "matlab_electric_V",
        "electric_error_pct",
        "comsol_magnetic_A",
        "matlab_magnetic_A",
        "magnetic_error_pct",
        "matlab_mechanical_thermal_relative_residual",
        "matlab_sensor_relative_residual",
        "matlab_solve_status",
        "matlab_sensor_status",
        "status",
        "evidence_tier",
    ]
    comparison_rows: list[dict[str, object]] = []
    for comsol_row in comsol_rows:
        mesh = int(comsol_row["mesh_divisions"])
        target = float(comsol_row["target_w_mm"])
        key = (mesh, target)
        if key not in matlab_by_key:
            raise RuntimeError(f"Missing matching MATLAB inverse result for {key}")
        matlab_row = matlab_by_key[key]
        input_file = matlab_row.get("input_file", "")
        if "U_Vf0.6" not in input_file or "10layer" not in input_file:
            raise RuntimeError(f"MATLAB inverse row is not the formal ten-layer U configuration: {key}")
        matlab_e = float(matlab_row["electric_span_V"])
        matlab_m = float(matlab_row["magnetic_span_A"])
        comsol_e = float(comsol_row["comsol_electric_V"])
        comsol_m = float(comsol_row["comsol_magnetic_A"])
        electric_error = 100.0 * abs(comsol_e - matlab_e) / max(abs(matlab_e), 1.0e-300)
        magnetic_error = 100.0 * abs(comsol_m - matlab_m) / max(abs(matlab_m), 1.0e-300)
        comparison_rows.append(
            {
                "mesh_divisions": mesh,
                "thickness_divisions_per_layer": comsol_row["thickness_divisions_per_layer"],
                "physical_layer_count": manifest["physical_layer_count"],
                "fg_mode": manifest["fg_mode"],
                "vf0": manifest["vf0"],
                "isomorphic_to_matlab_10layer": manifest["isomorphic_to_matlab_10layer"],
                "comparison_scope": manifest["comparison_scope"],
                "mechanical_discretization": manifest["mechanical_discretization"],
                "method": manifest["method"],
                "solver_strategy": manifest["solver_strategy"],
                "coupling_equivalent_to_matlab": manifest["coupling_equivalent_to_matlab"],
                "observable_definition": manifest["observable_definition"],
                "target_w_mm": f"{target:.16g}",
                "comsol_electric_V": f"{comsol_e:.17g}",
                "matlab_electric_V": f"{matlab_e:.17g}",
                "electric_error_pct": f"{electric_error:.17g}",
                "comsol_magnetic_A": f"{comsol_m:.17g}",
                "matlab_magnetic_A": f"{matlab_m:.17g}",
                "magnetic_error_pct": f"{magnetic_error:.17g}",
                "matlab_mechanical_thermal_relative_residual": matlab_row[
                    "mechanical_thermal_relative_residual"
                ],
                "matlab_sensor_relative_residual": matlab_row["sensor_relative_residual"],
                "matlab_solve_status": matlab_row["solve_status"],
                "matlab_sensor_status": matlab_row["sensor_status"],
                "status": comsol_row["status"],
                "evidence_tier": comsol_row["evidence_tier"],
            }
        )

    comparison_rows.sort(key=lambda row: float(row["target_w_mm"]))
    write_csv(
        "results/inverse/latest_cross_solver_comparison.csv",
        output_fields,
        comparison_rows,
    )


def write_flat_reference() -> None:
    _, rows = read_csv(ROOT / "output" / "results_static.csv")
    selected = [
        row for row in rows
        if abs(float(row["vf0"]) - 0.6) < 1e-12
        and row["fg_mode"] in {"U", "X"}
        and row["load_case"] in {"elastic", "electro", "magneto"}
        and row["status"] == "ok"
    ]
    if len(selected) != 6:
        raise RuntimeError(f"Expected six flat reference rows, found {len(selected)}")
    output = [
        {
            "mode": row["fg_mode"],
            "vf0": row["vf0"],
            "mesh": "30x30",
            "load_case": row["load_case"],
            "w_center_mm": row["w_center_mm"],
            "source_case": Path(row["input_file"]).name,
        }
        for row in selected
    ]
    write_csv(
        "results/baseline/flat_reference_30x30.csv",
        ["mode", "vf0", "mesh", "load_case", "w_center_mm", "source_case"],
        output,
    )


def copy_code_closure_report() -> Path:
    return copy_file(
        ROOT / CODE_CLOSURE_REPORT_RELATIVE,
        "report/CODE_CLOSURE_SIX_STEP_REPORT.md",
    )


def copy_models_and_code_closure_report() -> None:
    models = {
        PAPER / "experiments" / "isomorphic_solid" / "comsol" / "comsol_isomorphic_electric_equivalent_stress_20x_Model.mph": "models/comsol/isomorphic_electric_20x.mph",
        PAPER / "experiments" / "isomorphic_solid" / "comsol" / "comsol_isomorphic_magnetic_external_stress_20x_Model.mph": "models/comsol/isomorphic_magnetic_20x.mph",
        PAPER / "experiments" / "curvature_fg" / "comsol" / "comsol_curved_U_R0p4_20x20x10_final_Model.mph": "models/comsol/curved_U_R0p4_20x.mph",
        ROOT / "outputs" / "code_closure" / "comsol_four_field" / "comsol_four_field_Model.mph": "models/comsol/inverse_four_field.mph",
    }
    for source, target in models.items():
        copy_file(source, target)
    copy_code_closure_report()


def write_readme_and_metadata() -> None:
    readme = r"""# FG-MEE 六步代码闭环包（封装日期 2026-07-20）

本包只交付六步代码闭环所需的正式源码、算例、原始数值证据、COMSOL 模型、执行入口和哈希清单。2026-07-15 论文式 TEX/PDF、报告图、宏文件、旧版、尝试版、调试、恢复、日志和中间缓存均不进入本包。

## 结论状态

- 平板外部基准：公开文献量级内，误差范围为 0.010%--0.92%。
- MATLAB/COMSOL 三维同构实体：6 个点全部通过，中心位移最大相对误差约 0.000177%。
- 曲率与功能梯度：4 个半径、U/X 两种梯度、3 类载荷，共 24 个 30x30 正文点；20x30 最大变化约 0.00788%。
- 代表性独立曲壳 COMSOL：15x20 网格变化约 0.965%，满足 1% 门槛；与 MATLAB 曲壳的 8.083% 差异被归类为模型形式敏感性，不是同构求解误差。
- 反向传感仅接受同一稳态步中以独立自由度求解 u、phi、psi、T，且与 MATLAB 的 uT→phiPsi 块三角耦合严格等价的 A 级字段证据；COMSOL 二次三维实体与 MATLAB LRT5 五自由度壳的机械离散明确标记为非同构。0.5/1.0/2.0 mm 三个目标、真实离散残差和重算差异须全部通过代码门禁，差异门槛只作为跨模型数值检查，不作为同构精度证明。

这里的“实验”指 MATLAB/COMSOL 数值实验与交叉验证，不是实体样件、传感器台架或物理加载实验。报告中的结论可以支撑数值研究论文，但不能表述成已有实物实验支撑。

## 目录

- `code/matlab`：两个清晰入口、两个求解器和 13 个必要 MEET 核心函数。
- `code/comsol`：同构实体、代表曲壳、块三角四场反向传感 3 个未经改写的 Java API 模型源。
- `cases/curvature`：仅 20x20 与 30x30 的 16 个最终曲率算例。
- `results`：正文采用的最新 CSV 结果；复跑结果统一写入 `results/recomputed`。
- `models/comsol`：4 个代表性最终模型，不含中间网格模型。
- `report/CODE_CLOSURE_SIX_STEP_REPORT.md`：按实际执行顺序整理的六步代码闭环报告。
- `metadata`：文件白名单、SHA-256 和交付自检记录。

## 快速核验

```powershell
.\RUN_CHECK.ps1
```

核验包括：正式源码与六步报告的同一性、文件白名单和 SHA-256、旧/调试文件名扫描、同构闭合、曲率网格门槛、独立曲壳网格门槛，以及反向传感四场物理、残差、三目标和重算误差门槛。

## MATLAB 复算

```powershell
.\RUN_MATLAB.ps1 -Target isomorphic
.\RUN_MATLAB.ps1 -Target curvature
.\RUN_MATLAB.ps1 -Target inverse
```

`isomorphic` 会复算 10/15/20 网格；`curvature` 会复算 20/30 网格的 48 个载荷解；`inverse` 会复算 10/15/20/30 网格与 0.5/1.0/2.0 mm 三个目标，并拒绝求解器版本或算例哈希不一致的旧断点。可通过 `FGMEE_MATLAB` 指定 `matlab.exe`。

## COMSOL 复算

```powershell
.\RUN_COMSOL.ps1 -Target curved -CompileOnly
.\RUN_COMSOL.ps1 -Target isomorphic-electric
.\RUN_COMSOL.ps1 -Target isomorphic-magnetic
.\RUN_COMSOL.ps1 -Target curved
.\RUN_COMSOL.ps1 -Target inverse
```

可通过 `FGMEE_COMSOL_BIN` 指定 COMSOL 的 `bin\win64` 目录。运行产生的模型和日志写入 `results/recomputed/comsol`，不会污染交付白名单。

## 软件条件

- MATLAB R2026a（或兼容版本）；
- COMSOL Multiphysics 6.0 Java API（仅 COMSOL 复算需要）；
- Python 3（完整自检需要，无第三方 Python 依赖）。
"""
    write_text("README.md", readme)

    validation = """# 交付自检基线

构建时已确认：

- 六步代码闭环报告已按源文件字节复制，并纳入 SHA-256 溯源；
- 同构实体 6/6 点通过 0.1% 门槛；
- 曲率正文 24/24 点通过 0.5% 的 20x30 网格门槛；
- 曲率--梯度交互 12/12 点均高于三倍网格误差界；
- 代表曲壳独立 COMSOL 的 15x20 变化为 0.9651%，通过 1% 门槛；
- 反向传感必须以 A 级块三角等价字段模型完成 0.5、1.0、2.0 mm 三个目标，真实离散残差和从原始值重算的电势、磁势跨模型差异全部通过；机械离散必须明确标记为非同构；
- 交付白名单不含 attempt、smoke、pilot、debug、diag、recovery、legacy、日志、MAT 缓存或 Java class 文件。

运行根目录下的 `RUN_CHECK.ps1` 可重新验证源码哈希、四场物理声明、残差和全部数值门槛；旧 B 级本构后处理结果会被明确拒绝。
"""
    write_text("metadata/VALIDATION.md", validation)
    info = {
        "package": PACKAGE_NAME,
        "built_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "delivery_date": "2026-07-20",
        "scope": "six_step_code_closure_only",
        "report_path": "report/CODE_CLOSURE_SIX_STEP_REPORT.md",
        "closure_steps": 6,
        "curvature_cases": 16,
        "representative_comsol_models": 4,
        "generated_outputs_directory": "results/recomputed",
        "physical_experiment_included": False,
    }
    write_text("metadata/package_info.json", json.dumps(info, ensure_ascii=False, indent=2) + "\n")


def write_source_provenance() -> None:
    rows = sorted(SOURCE_PROVENANCE, key=lambda row: row["package_path"])
    package_paths = [row["package_path"] for row in rows]
    if len(package_paths) != len(set(package_paths)):
        raise RuntimeError("Duplicate package paths in source provenance")
    write_csv(
        "metadata/SOURCE_PROVENANCE.csv",
        ["source_path", "package_path", "source_sha256", "package_sha256"],
        rows,
    )


def write_manifest_and_zip() -> tuple[int, int]:
    excluded = {"metadata/MANIFEST.csv", "metadata/SHA256SUMS.txt"}
    files = [
        path for path in TARGET.rglob("*")
        if path.is_file() and path.relative_to(TARGET).as_posix() not in excluded
    ]
    files.sort(key=lambda path: path.relative_to(TARGET).as_posix())
    rows: list[dict[str, object]] = []
    sha_lines: list[str] = []
    for path in files:
        rel = path.relative_to(TARGET).as_posix()
        digest = file_sha256(path)
        rows.append({"relative_path": rel, "size_bytes": path.stat().st_size, "sha256": digest})
        sha_lines.append(f"{digest} *{rel}")
    write_csv("metadata/MANIFEST.csv", ["relative_path", "size_bytes", "sha256"], rows)
    write_text("metadata/SHA256SUMS.txt", "\n".join(sha_lines) + "\n")

    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(TARGET.rglob("*")):
            if path.is_file():
                arcname = (Path(PACKAGE_NAME) / path.relative_to(TARGET)).as_posix()
                archive.write(path, arcname)
    return len(rows), ZIP_PATH.stat().st_size


def main() -> None:
    preflight_code_closure_sources()
    clean_target()
    copy_runtime_code()
    copy_cases()
    copy_isomorphic_results()
    copy_curvature_results()
    copy_inverse_results()
    write_flat_reference()
    copy_models_and_code_closure_report()
    write_readme_and_metadata()
    write_source_provenance()
    payload_count, zip_size = write_manifest_and_zip()
    print(
        json.dumps(
            {
                "package_dir": str(TARGET),
                "zip": str(ZIP_PATH),
                "payload_files": payload_count,
                "zip_size_bytes": zip_size,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
