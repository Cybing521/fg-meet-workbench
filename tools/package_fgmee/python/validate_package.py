#!/usr/bin/env python3
"""Read-only validation for the FG-MEE minimal delivery package."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
import sys
from pathlib import Path


FORBIDDEN_SUFFIXES = {".class", ".fig", ".log", ".mat", ".pyc", ".recovery", ".status"}
FORBIDDEN_TOKEN = re.compile(
    r"(?:^|[_\-.])(attempt|debug|diag|legacy|old|pilot|recovery|smoke)(?:[_\-.]|$)",
    re.IGNORECASE,
)

FULL_FIELD_METHOD = "sequential_equivalent_four_field_solution"
FULL_FIELD_EVIDENCE_TIER = "A_independent_block_triangular_fields"
FULL_FIELD_STATUS = "completed_full_field"
INVERSE_TARGETS_MM = (0.5, 1.0, 2.0)
PHYSICS_RESIDUAL_LIMIT = 1.0e-6
SOLVER_CONVERGENCE_LIMIT = 1.0e-5
SOLVER_RELATIVE_TOLERANCE = 1.0e-4
MAX_MATLAB_NORMALIZED_RESIDUAL = 1.0e-8
MAX_INVERSE_RELATIVE_ERROR_PCT = 5.0
RESIDUAL_DEFINITION = (
    "mechanical=global_force_balance;"
    "weak_moment=max_layer_normalized_constitutive_flux_moment;"
    "discrete_group_error=max_final_outer_iteration_error_by_field;"
    "solver_linear_residual=max_final_inner_LinRes_by_field"
)
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
REQUIRED_FILES = (
    "README.md",
    "RUN_CHECK.ps1",
    "RUN_MATLAB.ps1",
    "RUN_COMSOL.ps1",
    "code/matlab/lib/run_meet_static.m",
    "code/matlab/lib/build_active_layer_dof_map.m",
    "code/matlab/lib/interpolate_shell_dof_at_point.m",
    "code/matlab/jobs/run_inverse_validation.m",
    "code/comsol/RunBlockTriangularInverseSensorCfffValidation.java",
    "models/comsol/inverse_four_field.mph",
    "report/CODE_CLOSURE_SIX_STEP_REPORT.md",
    "results/isomorphic/cross_solver_comparison.csv",
    "results/curvature/final_30x30_results.csv",
    "results/curvature/all_radius_interaction_30x30.csv",
    "results/curvature/all_radius_mesh_summary.csv",
    "results/curvature/curved_comsol_mesh_convergence.csv",
    "results/curvature/curved_comsol_vs_matlab_model_form.csv",
    "results/inverse/matlab_inverse_structural_pyro_mesh.csv",
    "results/inverse/comsol_four_field_summary.csv",
    "results/inverse/comsol_four_field_layers.csv",
    "results/inverse/comsol_four_field_physics_manifest.csv",
    "results/inverse/comsol_four_field_channel_isolation.csv",
    "results/inverse/latest_cross_solver_comparison.csv",
    "metadata/MANIFEST.csv",
    "metadata/SHA256SUMS.txt",
    "metadata/SOURCE_PROVENANCE.csv",
)


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def number(row: dict[str, str], field: str) -> float:
    return float(row[field])


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def percentage_error(reference: float, candidate: float) -> float:
    if reference == 0.0:
        return 0.0 if candidate == 0.0 else math.inf
    return 100.0 * abs(candidate - reference) / abs(reference)


def _is_true(value: str) -> bool:
    return value.strip().lower() == "true"


def _finite_at_most(row: dict[str, str], field: str, limit: float) -> bool:
    try:
        value = float(row[field])
    except (KeyError, TypeError, ValueError):
        return False
    return math.isfinite(value) and 0.0 <= value <= limit


def _finite_equals(row: dict[str, str], field: str, expected: float) -> bool:
    try:
        value = float(row[field])
    except (KeyError, TypeError, ValueError):
        return False
    return math.isfinite(value) and math.isclose(
        value, expected, rel_tol=0.0, abs_tol=1.0e-15
    )


def validate_inverse_code_closure(root: Path) -> list[dict[str, object]]:
    """Validate that inverse sensing is an independent four-field code closure.

    This intentionally rejects the older solid-mechanics plus constitutive
    post-processing evidence, even when its precomputed error columns are below
    the numerical tolerance.
    """
    checks: list[dict[str, object]] = []

    def check(name: str, passed: bool, detail: str) -> None:
        checks.append({"name": name, "passed": bool(passed), "detail": detail})

    manifest_path = root / "results/inverse/comsol_four_field_physics_manifest.csv"
    physics_errors: list[str] = []
    if not manifest_path.is_file():
        physics_rows: list[dict[str, str]] = []
        physics_errors.append("physics_manifest_missing")
    else:
        physics_rows = read_rows(manifest_path)
        if not physics_rows:
            physics_errors.append("physics_manifest_empty")
        elif len(physics_rows) != 1:
            physics_errors.append(f"physics_manifest_rows={len(physics_rows)},expected=1")

    required_true_fields = (
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
    )
    for row_index, row in enumerate(physics_rows, start=1):
        prefix = f"row{row_index}"
        for field in required_true_fields:
            if not _is_true(row.get(field, "")):
                physics_errors.append(f"{prefix}:{field}=false_or_missing")
        if row.get("method") != FULL_FIELD_METHOD:
            physics_errors.append(f"{prefix}:method={row.get('method', '<missing>')}")
        if row.get("solver_strategy") != "segregated_same_stationary":
            physics_errors.append(f"{prefix}:solver_strategy_not_segregated_same_stationary")
        if (
            row.get("convergence_termination")
            != "fixed_25_segregated_iterations_with_final_residual_gate"
        ):
            physics_errors.append(f"{prefix}:convergence_termination_mismatch")
        if row.get("direct_error_check") != "auto_enabled":
            physics_errors.append(f"{prefix}:direct_error_check_not_auto_enabled")
        if row.get("segregated_termination") != "iter":
            physics_errors.append(f"{prefix}:segregated_termination_not_iter")
        try:
            fixed_segregated_iterations = float(row["fixed_segregated_iterations"])
        except (KeyError, TypeError, ValueError):
            fixed_segregated_iterations = math.nan
        if (
            not math.isfinite(fixed_segregated_iterations)
            or not fixed_segregated_iterations.is_integer()
            or fixed_segregated_iterations != 25.0
        ):
            physics_errors.append(f"{prefix}:fixed_segregated_iterations_not_25")
        if row.get("layer_field_layout") != "independent_per_physical_layer":
            physics_errors.append(f"{prefix}:layer_field_layout_not_independent")
        if (
            row.get("observable_definition")
            != "max_minus_min_of_layer_top_bottom_area_average_potential_difference"
        ):
            physics_errors.append(f"{prefix}:observable_definition_mismatch")
        if (
            row.get("layer_drop_definition")
            != "layer_thickness_times_volume_average_potential_gradient_equivalent_to_face_average_difference"
        ):
            physics_errors.append(f"{prefix}:layer_drop_definition_mismatch")
        if row.get("evidence_tier") != FULL_FIELD_EVIDENCE_TIER:
            physics_errors.append(
                f"{prefix}:evidence_tier={row.get('evidence_tier', '<missing>')}"
            )
        if row.get("status") != FULL_FIELD_STATUS:
            physics_errors.append(f"{prefix}:status={row.get('status', '<missing>')}")
        if row.get("api_channel_isolation_status", "").lower() != "pass":
            physics_errors.append(f"{prefix}:api_channel_isolation_status_not_pass")
        if row.get("physical_layer_count") != "10":
            physics_errors.append(f"{prefix}:physical_layer_count_not_10")
        if row.get("fg_mode") != "U":
            physics_errors.append(f"{prefix}:fg_mode_not_U")
        try:
            vf0 = float(row["vf0"])
        except (KeyError, TypeError, ValueError):
            vf0 = math.nan
        if not math.isfinite(vf0) or not math.isclose(vf0, 0.6, rel_tol=0.0, abs_tol=1e-12):
            physics_errors.append(f"{prefix}:vf0_not_0p6")
        if row.get("isomorphic_to_matlab_10layer", "").lower() != "false":
            physics_errors.append(f"{prefix}:isomorphic_flag_must_be_false")
        if (
            row.get("comparison_scope")
            != "same_geometry_material_boundary_observable_nonisomorphic_mechanics"
        ):
            physics_errors.append(f"{prefix}:comparison_scope_mismatch")
        if (
            row.get("mechanical_discretization")
            != "COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell"
        ):
            physics_errors.append(f"{prefix}:mechanical_discretization_mismatch")
        if row.get("field_residual_evaluation_status") != "pass":
            physics_errors.append(f"{prefix}:field_residual_evaluation_status_not_pass")
        if row.get("solver_has_problems", "").lower() != "false":
            physics_errors.append(f"{prefix}:solver_has_problems")
        if not _finite_equals(
            row, "physics_residual_limit", PHYSICS_RESIDUAL_LIMIT
        ):
            physics_errors.append(f"{prefix}:physics_residual_limit_invalid")
        if not _finite_equals(
            row, "solver_convergence_limit", SOLVER_CONVERGENCE_LIMIT
        ):
            physics_errors.append(f"{prefix}:solver_convergence_limit_invalid")
        if not _finite_equals(
            row, "solver_relative_tolerance", SOLVER_RELATIVE_TOLERANCE
        ):
            physics_errors.append(f"{prefix}:solver_relative_tolerance_invalid")
        if not row.get("run_id", ""):
            physics_errors.append(f"{prefix}:run_id_missing")
        source_digest = row.get("source_sha256", "")
        if len(source_digest) != 64 or any(ch not in "0123456789abcdefABCDEF" for ch in source_digest):
            physics_errors.append(f"{prefix}:source_sha256_invalid")
        if row.get("residual_definition") != RESIDUAL_DEFINITION:
            physics_errors.append(f"{prefix}:residual_definition_mismatch")
        legacy_present = [field for field in LEGACY_RESIDUAL_FIELDS if field in row]
        if legacy_present:
            physics_errors.append(f"{prefix}:legacy_residual_fields={legacy_present}")
        for field in PHYSICAL_RESIDUALS:
            if not _finite_at_most(row, field, PHYSICS_RESIDUAL_LIMIT):
                physics_errors.append(f"{prefix}:{field}_invalid_or_above_limit")
        for field in SOLVER_CONVERGENCE_RESIDUALS:
            if not _finite_at_most(row, field, SOLVER_CONVERGENCE_LIMIT):
                physics_errors.append(f"{prefix}:{field}_invalid_or_above_limit")
        try:
            field_solver_values = [float(row[field]) for field in FIELD_SOLVER_RESIDUALS]
            global_solver_value = float(row["solver_linear_residual"])
            physical_values = [float(row[field]) for field in PHYSICAL_RESIDUALS]
        except (KeyError, TypeError, ValueError):
            field_solver_values = []
            global_solver_value = math.nan
            physical_values = []
        if field_solver_values and not math.isclose(
            global_solver_value,
            max(field_solver_values),
            rel_tol=1.0e-9,
            abs_tol=1.0e-15,
        ):
            physics_errors.append(f"{prefix}:solver_linear_residual_not_group_max")
        if (
            math.isfinite(global_solver_value)
            and global_solver_value > 0.0
            and physical_values
            and all(
                math.isclose(value, global_solver_value, rel_tol=0.0, abs_tol=1.0e-15)
                for value in physical_values
            )
        ):
            physics_errors.append(f"{prefix}:copied_LinRes_pseudoresiduals")

    isolation_path = root / "results/inverse/comsol_four_field_channel_isolation.csv"
    expected_channels = {
        "electric": ("1", "0", "0"),
        "magnetic": ("0", "1", "0"),
        "thermal": ("0", "0", "1"),
    }
    if not isolation_path.is_file():
        physics_errors.append("channel_isolation_missing")
    else:
        isolation_rows = read_rows(isolation_path)
        isolation_by_channel = {row.get("channel", ""): row for row in isolation_rows}
        if len(isolation_rows) != 3 or set(isolation_by_channel) != set(expected_channels):
            physics_errors.append(
                f"channel_set={sorted(isolation_by_channel)},expected={sorted(expected_channels)}"
            )
        for channel, expected_gates in expected_channels.items():
            row = isolation_by_channel.get(channel, {})
            actual_gates = (row.get("gateE"), row.get("gateM"), row.get("gateT"))
            if actual_gates != expected_gates:
                physics_errors.append(f"{channel}:gate_tuple={actual_gates}")
            if row.get("isolation_status", "").lower() != "pass":
                physics_errors.append(f"{channel}:isolation_status_not_pass")

    check(
        "inverse_full_field_physics",
        not physics_errors,
        (
            f"rows={len(physics_rows)}, four_fields=true, physics_residual<="
            f"{PHYSICS_RESIDUAL_LIMIT:.1e}, solver_convergence<="
            f"{SOLVER_CONVERGENCE_LIMIT:.1e}"
            if not physics_errors
            else ";".join(physics_errors)
        ),
    )

    comparison_path = root / "results/inverse/latest_cross_solver_comparison.csv"
    comparison_errors: list[str] = []
    if not comparison_path.is_file():
        comparison_rows: list[dict[str, str]] = []
        comparison_errors.append("comparison_missing")
    else:
        comparison_rows = read_rows(comparison_path)

    found_targets: list[float] = []
    for row_index, row in enumerate(comparison_rows, start=1):
        prefix = f"row{row_index}"
        try:
            target = float(row["target_w_mm"])
            matlab_e = float(row["matlab_electric_V"])
            comsol_e = float(row["comsol_electric_V"])
            reported_e = float(row["electric_error_pct"])
            matlab_m = float(row["matlab_magnetic_A"])
            comsol_m = float(row["comsol_magnetic_A"])
            reported_m = float(row["magnetic_error_pct"])
        except (KeyError, TypeError, ValueError) as exc:
            comparison_errors.append(f"{prefix}:missing_or_invalid_numeric_field:{exc}")
            continue

        values = (target, matlab_e, comsol_e, reported_e, matlab_m, comsol_m, reported_m)
        if not all(math.isfinite(value) for value in values):
            comparison_errors.append(f"{prefix}:nonfinite_value")
            continue
        found_targets.append(target)

        calculated_e = percentage_error(matlab_e, comsol_e)
        calculated_m = percentage_error(matlab_m, comsol_m)
        if not math.isclose(reported_e, calculated_e, rel_tol=1.0e-9, abs_tol=1.0e-9):
            comparison_errors.append(
                f"{prefix}:electric_error_stale(reported={reported_e:.12g},calc={calculated_e:.12g})"
            )
        if not math.isclose(reported_m, calculated_m, rel_tol=1.0e-9, abs_tol=1.0e-9):
            comparison_errors.append(
                f"{prefix}:magnetic_error_stale(reported={reported_m:.12g},calc={calculated_m:.12g})"
            )
        if calculated_e > MAX_INVERSE_RELATIVE_ERROR_PCT:
            comparison_errors.append(f"{prefix}:electric_error_above_5pct")
        if calculated_m > MAX_INVERSE_RELATIVE_ERROR_PCT:
            comparison_errors.append(f"{prefix}:magnetic_error_above_5pct")
        if row.get("evidence_tier") != FULL_FIELD_EVIDENCE_TIER:
            comparison_errors.append(f"{prefix}:evidence_tier_not_A")
        if row.get("status") != FULL_FIELD_STATUS:
            comparison_errors.append(f"{prefix}:status_not_completed_full_field")
        if row.get("physical_layer_count") != "10" or row.get("fg_mode") != "U":
            comparison_errors.append(f"{prefix}:configuration_not_ten_layer_U")
        try:
            comparison_vf0 = float(row["vf0"])
        except (KeyError, TypeError, ValueError):
            comparison_vf0 = math.nan
        if not math.isfinite(comparison_vf0) or not math.isclose(
            comparison_vf0, 0.6, rel_tol=0.0, abs_tol=1e-12
        ):
            comparison_errors.append(f"{prefix}:vf0_not_0p6")
        if row.get("isomorphic_to_matlab_10layer", "").lower() != "false":
            comparison_errors.append(f"{prefix}:isomorphic_flag_must_be_false")
        if (
            row.get("comparison_scope")
            != "same_geometry_material_boundary_observable_nonisomorphic_mechanics"
        ):
            comparison_errors.append(f"{prefix}:comparison_scope_mismatch")
        if (
            row.get("mechanical_discretization")
            != "COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell"
        ):
            comparison_errors.append(f"{prefix}:mechanical_discretization_mismatch")
        if row.get("method") != FULL_FIELD_METHOD:
            comparison_errors.append(f"{prefix}:method_not_matlab_equivalent")
        if row.get("solver_strategy") != "segregated_same_stationary":
            comparison_errors.append(f"{prefix}:solver_strategy_mismatch")
        if not _is_true(row.get("coupling_equivalent_to_matlab", "")):
            comparison_errors.append(f"{prefix}:coupling_not_equivalent_to_matlab")
        if (
            row.get("observable_definition")
            != "max_minus_min_of_layer_top_bottom_area_average_potential_difference"
        ):
            comparison_errors.append(f"{prefix}:observable_definition_mismatch")
        if row.get("matlab_solve_status", "") != "ok":
            comparison_errors.append(f"{prefix}:matlab_solve_status_not_ok")
        if row.get("matlab_sensor_status", "") != "ok":
            comparison_errors.append(f"{prefix}:matlab_sensor_status_not_ok")
        for field in (
            "matlab_mechanical_thermal_relative_residual",
            "matlab_sensor_relative_residual",
        ):
            if not _finite_at_most(row, field, MAX_MATLAB_NORMALIZED_RESIDUAL):
                comparison_errors.append(f"{prefix}:{field}_invalid_or_above_limit")

    expected_targets = sorted(INVERSE_TARGETS_MM)
    actual_targets = sorted(found_targets)
    if len(actual_targets) != len(expected_targets) or any(
        not math.isclose(actual, expected, rel_tol=0.0, abs_tol=1.0e-12)
        for actual, expected in zip(actual_targets, expected_targets)
    ):
        comparison_errors.append(f"target_set={actual_targets},expected={expected_targets}")

    check(
        "inverse_cross_model_discrepancy",
        not comparison_errors,
        (
            f"targets={actual_targets}, nonisomorphic mechanics, recalculated electric/magnetic differences<="
            f"{MAX_INVERSE_RELATIVE_ERROR_PCT:.1f}%"
            if not comparison_errors
            else ";".join(comparison_errors)
        ),
    )
    return checks


def validate(root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []

    def check(name: str, passed: bool, detail: str) -> None:
        checks.append({"name": name, "passed": bool(passed), "detail": detail})

    missing = [item for item in REQUIRED_FILES if not (root / item).is_file()]
    check("required_files", not missing, "missing=" + ",".join(missing) if missing else "all present")

    closure_report = root / "report/CODE_CLOSURE_SIX_STEP_REPORT.md"
    try:
        closure_report_text = closure_report.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError) as exc:
        check("code_closure_report", False, str(exc))
    else:
        check(
            "code_closure_report",
            bool(closure_report_text.strip()),
            f"bytes={closure_report.stat().st_size}",
        )

    dirty_names: list[str] = []
    dirty_suffixes: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        if rel.startswith("results/recomputed/"):
            continue
        if FORBIDDEN_TOKEN.search(path.name):
            dirty_names.append(rel)
        if any(path.name.lower().endswith(suffix) for suffix in FORBIDDEN_SUFFIXES):
            dirty_suffixes.append(rel)
    check("filename_hygiene", not dirty_names, "clean" if not dirty_names else ";".join(dirty_names))
    check("artifact_hygiene", not dirty_suffixes, "clean" if not dirty_suffixes else ";".join(dirty_suffixes))

    manifest_path = root / "metadata/MANIFEST.csv"
    manifest_errors: list[str] = []
    if manifest_path.is_file():
        manifest_rows = read_rows(manifest_path)
        for row in manifest_rows:
            path = root / row["relative_path"]
            if not path.is_file():
                manifest_errors.append(f"missing:{row['relative_path']}")
                continue
            if path.stat().st_size != int(row["size_bytes"]):
                manifest_errors.append(f"size:{row['relative_path']}")
            if sha256(path) != row["sha256"].upper():
                manifest_errors.append(f"sha256:{row['relative_path']}")
        payload = {
            path.relative_to(root).as_posix()
            for path in root.rglob("*")
            if path.is_file()
            and not path.relative_to(root).as_posix().startswith("results/recomputed/")
            and path.relative_to(root).as_posix()
            not in {"metadata/MANIFEST.csv", "metadata/SHA256SUMS.txt"}
        }
        recorded = {row["relative_path"] for row in manifest_rows}
        for extra in sorted(payload - recorded):
            manifest_errors.append(f"unrecorded:{extra}")
        for stale in sorted(recorded - payload):
            manifest_errors.append(f"stale:{stale}")
    else:
        manifest_rows = []
        manifest_errors.append("manifest_missing")
    check(
        "manifest_integrity",
        not manifest_errors,
        f"{len(manifest_rows)} payload files verified" if not manifest_errors else ";".join(manifest_errors),
    )

    provenance_path = root / "metadata/SOURCE_PROVENANCE.csv"
    provenance_errors: list[str] = []
    if provenance_path.is_file():
        provenance_rows = read_rows(provenance_path)
        provenance_by_package = {row.get("package_path", ""): row for row in provenance_rows}
        if len(provenance_by_package) != len(provenance_rows):
            provenance_errors.append("duplicate_package_path")
        for formal_path in (
            "RUN_MATLAB.ps1",
            "RUN_COMSOL.ps1",
            "code/python/validate_package.py",
            "code/matlab/lib/run_meet_static.m",
            "code/matlab/jobs/run_inverse_validation.m",
            "code/matlab/lib/meet_core/SF_ElemComptLIN851T5MEEP_V4.m",
            "code/matlab/lib/meet_core/SF_GetMatePropMEEP.m",
            "code/matlab/lib/meet_core/SF_Condensation.m",
            "code/comsol/RunBlockTriangularInverseSensorCfffValidation.java",
            "models/comsol/inverse_four_field.mph",
            "report/CODE_CLOSURE_SIX_STEP_REPORT.md",
        ):
            if formal_path not in provenance_by_package:
                provenance_errors.append(f"formal_source_unrecorded:{formal_path}")
        for row in provenance_rows:
            package_path = row.get("package_path", "")
            packaged = root / package_path
            if not row.get("source_path", ""):
                provenance_errors.append(f"source_path_empty:{package_path or '<empty>'}")
            if not package_path or not packaged.is_file():
                provenance_errors.append(f"missing:{package_path or '<empty>'}")
                continue
            actual = sha256(packaged)
            source_digest = row.get("source_sha256", "").upper()
            package_digest = row.get("package_sha256", "").upper()
            if source_digest != package_digest:
                provenance_errors.append(f"source_package_mismatch:{package_path}")
            if actual != package_digest:
                provenance_errors.append(f"package_sha256:{package_path}")
    else:
        provenance_rows = []
        provenance_errors.append("source_provenance_missing")
    check(
        "formal_source_identity",
        bool(provenance_rows) and not provenance_errors,
        (
            f"{len(provenance_rows)} direct-copy source hashes verified"
            if not provenance_errors
            else ";".join(provenance_errors)
        ),
    )

    producer_link_errors: list[str] = []
    producer_source = root / "code/comsol/RunBlockTriangularInverseSensorCfffValidation.java"
    physics_manifest = root / "results/inverse/comsol_four_field_physics_manifest.csv"
    inverse_summary = root / "results/inverse/comsol_four_field_summary.csv"
    if producer_source.is_file() and physics_manifest.is_file():
        physics_rows = read_rows(physics_manifest)
        if len(physics_rows) != 1:
            producer_link_errors.append(f"physics_rows={len(physics_rows)}")
        else:
            evidence_row = physics_rows[0]
            actual_source_digest = sha256(producer_source).lower()
            if evidence_row.get("source_sha256", "").lower() != actual_source_digest:
                producer_link_errors.append("physics_source_sha256_mismatch")
            if inverse_summary.is_file():
                for index, row in enumerate(read_rows(inverse_summary), start=1):
                    if row.get("run_id") != evidence_row.get("run_id"):
                        producer_link_errors.append(f"summary_row{index}_run_id_mismatch")
                    if row.get("source_sha256", "").lower() != actual_source_digest:
                        producer_link_errors.append(f"summary_row{index}_source_sha256_mismatch")
            else:
                producer_link_errors.append("inverse_summary_missing")
    else:
        producer_link_errors.append("producer_or_physics_manifest_missing")
    check(
        "evidence_producer_identity",
        not producer_link_errors,
        "manifest and summary linked to packaged producer"
        if not producer_link_errors
        else ";".join(producer_link_errors),
    )

    iso = read_rows(root / "results/isomorphic/cross_solver_comparison.csv")
    iso_max = max(number(row, "center_relative_error_pct") for row in iso)
    iso_probe_max = max(number(row, "free_mid_relative_error_pct") for row in iso)
    check(
        "isomorphic_closure",
        len(iso) == 6 and iso_max <= 0.1 and iso_probe_max <= 0.1
        and all(row["acceptance_gate"].lower() == "pass" for row in iso),
        f"rows={len(iso)}, center_max={iso_max:.9g}%, free_probe_max={iso_probe_max:.9g}%",
    )

    curvature = read_rows(root / "results/curvature/final_30x30_results.csv")
    curvature_max = max(number(row, "w_change_20_to_30_pct") for row in curvature)
    check(
        "curvature_mesh_gate",
        len(curvature) == 24 and curvature_max <= 0.5
        and all(row["mesh_gate_0p5pct"].lower() == "pass" for row in curvature),
        f"rows={len(curvature)}, max_20_to_30={curvature_max:.9g}%",
    )

    interaction = read_rows(root / "results/curvature/all_radius_interaction_30x30.csv")
    check(
        "curvature_interaction_resolution",
        len(interaction) == 12
        and all(row["resolved_above_3x_mesh_bound"].lower() == "pass" for row in interaction),
        f"rows={len(interaction)}",
    )

    curved_mesh = read_rows(root / "results/curvature/curved_comsol_mesh_convergence.csv")
    final_mesh_change = number(curved_mesh[-1], "change_from_previous_pct")
    check(
        "curved_comsol_mesh_gate",
        len(curved_mesh) == 3 and final_mesh_change <= 1.0
        and curved_mesh[-1]["mesh_gate_1pct"].lower() == "pass",
        f"rows={len(curved_mesh)}, final_change={final_mesh_change:.9g}%",
    )

    model_form = read_rows(root / "results/curvature/curved_comsol_vs_matlab_model_form.csv")
    model_gap = number(model_form[0], "relative_model_form_gap_pct")
    check(
        "curved_model_form_classification",
        len(model_form) == 1 and 5.0 <= model_gap <= 15.0
        and model_form[0]["evidence_level"].startswith("B_"),
        f"gap={model_gap:.9g}% (Tier-B model-form sensitivity)",
    )

    checks.extend(validate_inverse_code_closure(root))

    failures = [item for item in checks if not item["passed"]]
    return {
        "package_root": str(root),
        "status": "PASS_FULL_CODE_CLOSURE" if not failures else "FAIL",
        "checks": checks,
        "failed_checks": len(failures),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package-root", type=Path, required=True)
    args = parser.parse_args()
    result = validate(args.package_root.resolve())
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "PASS_FULL_CODE_CLOSURE" else 1


if __name__ == "__main__":
    sys.exit(main())
