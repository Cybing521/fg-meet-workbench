from __future__ import annotations

import csv
import importlib.util
import inspect
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VALIDATOR_PATH = ROOT / "tools" / "package_fgmee" / "python" / "validate_package.py"
SPEC = importlib.util.spec_from_file_location("fgmee_validate_package", VALIDATOR_PATH)
assert SPEC is not None and SPEC.loader is not None
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)

BUILDER_PATH = ROOT / "tools" / "build_fgmee_minimal_package.py"
BUILDER_SPEC = importlib.util.spec_from_file_location("fgmee_build_package", BUILDER_PATH)
assert BUILDER_SPEC is not None and BUILDER_SPEC.loader is not None
BUILDER = importlib.util.module_from_spec(BUILDER_SPEC)
BUILDER_SPEC.loader.exec_module(BUILDER)


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


class InverseClosureGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.physics_path = (
            self.root / "results" / "inverse" / "comsol_four_field_physics_manifest.csv"
        )
        self.comparison_path = (
            self.root / "results" / "inverse" / "latest_cross_solver_comparison.csv"
        )
        self.isolation_path = (
            self.root / "results" / "inverse" / "comsol_four_field_channel_isolation.csv"
        )
        self.physics = {
            "case_id": "inverse_CFFF_U_Vf06",
            "solve_u": "true",
            "solve_phi": "true",
            "solve_psi": "true",
            "solve_T": "true",
            "method": "sequential_equivalent_four_field_solution",
            "evidence_tier": "A_independent_block_triangular_fields",
            "solver_strategy": "segregated_same_stationary",
            "convergence_termination": "fixed_25_segregated_iterations_with_final_residual_gate",
            "direct_error_check": "auto_enabled",
            "segregated_termination": "iter",
            "fixed_segregated_iterations": "25",
            "coupling_equivalent_to_matlab": "true",
            "layer_field_layout": "independent_per_physical_layer",
            "observable_definition": "max_minus_min_of_layer_top_bottom_area_average_potential_difference",
            "layer_drop_definition": "layer_thickness_times_volume_average_potential_gradient_equivalent_to_face_average_difference",
            "mechanical_force_balance_residual": "1e-9",
            "electric_weak_moment_residual": "2e-9",
            "magnetic_weak_moment_residual": "3e-9",
            "thermal_weak_moment_residual": "4e-9",
            "solid_discrete_segregated_group_relative_error": "5e-9",
            "electric_discrete_segregated_group_relative_error": "6e-9",
            "magnetic_discrete_segregated_group_relative_error": "7e-9",
            "thermal_discrete_segregated_group_relative_error": "8e-9",
            "solid_solver_linear_residual": "9e-9",
            "electric_solver_linear_residual": "1e-8",
            "magnetic_solver_linear_residual": "1.1e-8",
            "thermal_solver_linear_residual": "1.2e-8",
            "solver_linear_residual": "1.2e-8",
            "residual_definition": "mechanical=global_force_balance;weak_moment=max_layer_normalized_constitutive_flux_moment;discrete_group_error=max_final_outer_iteration_error_by_field;solver_linear_residual=max_final_inner_LinRes_by_field",
            "field_residual_evaluation_status": "pass",
            "solver_has_problems": "false",
            "physics_residual_limit": "1e-6",
            "solver_convergence_limit": "1e-5",
            "solver_relative_tolerance": "1e-4",
            "run_id": "fixture-run",
            "source_sha256": "a" * 64,
            "status": "completed_full_field",
            "same_stationary": "true",
            "open_circuit_electric": "true",
            "open_circuit_magnetic": "true",
            "insulated_thermal": "true",
            "independent_dof_fields": "true",
            "geometry_material_boundary_layer_observable_aligned": "true",
            "api_channel_isolation_status": "pass",
            "physical_layer_count": "10",
            "fg_mode": "U",
            "vf0": "0.6",
            "isomorphic_to_matlab_10layer": "false",
            "comparison_scope": "same_geometry_material_boundary_observable_nonisomorphic_mechanics",
            "mechanical_discretization": "COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell",
        }
        self.comparison = []
        for target in (0.5, 1.0, 2.0):
            matlab_e = 100.0 * target
            matlab_m = 0.04 * target
            comsol_e = matlab_e * 1.02
            comsol_m = matlab_m * 0.98
            self.comparison.append(
                {
                    "mesh_divisions": "10",
                    "physical_layer_count": "10",
                    "fg_mode": "U",
                    "vf0": "0.6",
                    "isomorphic_to_matlab_10layer": "false",
                    "comparison_scope": "same_geometry_material_boundary_observable_nonisomorphic_mechanics",
                    "mechanical_discretization": "COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell",
                    "method": "sequential_equivalent_four_field_solution",
                    "solver_strategy": "segregated_same_stationary",
                    "coupling_equivalent_to_matlab": "true",
                    "observable_definition": "max_minus_min_of_layer_top_bottom_area_average_potential_difference",
                    "target_w_mm": target,
                    "comsol_electric_V": comsol_e,
                    "matlab_electric_V": matlab_e,
                    "electric_error_pct": 2.0,
                    "comsol_magnetic_A": comsol_m,
                    "matlab_magnetic_A": matlab_m,
                    "magnetic_error_pct": 2.0,
                    "matlab_mechanical_thermal_relative_residual": "1e-12",
                    "matlab_sensor_relative_residual": "2e-12",
                    "matlab_solve_status": "ok",
                    "matlab_sensor_status": "ok",
                    "status": "completed_full_field",
                    "evidence_tier": "A_independent_block_triangular_fields",
                }
            )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_gate(self) -> list[dict[str, object]]:
        write_csv(self.physics_path, [self.physics])
        write_csv(self.comparison_path, self.comparison)
        write_csv(
            self.isolation_path,
            [
                {"channel": "electric", "gateE": 1, "gateM": 0, "gateT": 0, "isolation_status": "pass"},
                {"channel": "magnetic", "gateE": 0, "gateM": 1, "gateT": 0, "isolation_status": "pass"},
                {"channel": "thermal", "gateE": 0, "gateM": 0, "gateT": 1, "isolation_status": "pass"},
            ],
        )
        return VALIDATOR.validate_inverse_code_closure(self.root)

    def assert_check(self, checks: list[dict[str, object]], name: str, expected: bool) -> None:
        by_name = {str(item["name"]): bool(item["passed"]) for item in checks}
        self.assertEqual(expected, by_name[name], checks)

    def test_full_field_three_target_fixture_passes(self) -> None:
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", True)
        self.assert_check(checks, "inverse_cross_model_discrepancy", True)

    def test_legacy_b_tier_constitutive_postprocess_fails(self) -> None:
        self.physics["method"] = "3d_solid_plus_local_open_circuit_constitutive_postprocess"
        self.physics["evidence_tier"] = "B_nonisomorphic_3d_mechanics"
        for row in self.comparison:
            row["evidence_tier"] = "B_nonisomorphic_3d_mechanics"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)
        self.assert_check(checks, "inverse_cross_model_discrepancy", False)

    def test_missing_field_degree_of_freedom_fails(self) -> None:
        self.physics["solve_phi"] = "false"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_single_layer_smoke_cannot_claim_ten_layer_closure(self) -> None:
        self.physics["physical_layer_count"] = "1"
        self.physics["isomorphic_to_matlab_10layer"] = "false"
        self.physics["comparison_scope"] = "four_field_code_path_only"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_four_field_mutual_feedback_cannot_claim_matlab_equivalence(self) -> None:
        self.physics["method"] = "fully_coupled_field_solution"
        self.physics["evidence_tier"] = "A_independent_full_coupled"
        self.physics["coupling_equivalent_to_matlab"] = "false"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_solid_shell_comparison_cannot_claim_isomorphic(self) -> None:
        self.physics["isomorphic_to_matlab_10layer"] = "true"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_strong_divergence_residual_definition_is_rejected(self) -> None:
        self.physics["residual_definition"] = "strong_divergence_second_derivative_residual"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_copied_solver_linres_pseudoresiduals_are_rejected(self) -> None:
        copied = self.physics["solver_linear_residual"]
        for field in (
            "mechanical_force_balance_residual",
            "electric_weak_moment_residual",
            "magnetic_weak_moment_residual",
            "thermal_weak_moment_residual",
        ):
            self.physics[field] = copied
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_global_solver_residual_must_equal_field_max(self) -> None:
        self.physics["solver_linear_residual"] = "9e-7"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_physics_residual_2e6_still_fails(self) -> None:
        self.physics["mechanical_force_balance_residual"] = "2e-6"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_solver_convergence_residual_2e5_fails(self) -> None:
        self.physics["solid_solver_linear_residual"] = "2e-5"
        self.physics["solver_linear_residual"] = "2e-5"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_solver_convergence_residual_5e6_passes(self) -> None:
        self.physics["solid_discrete_segregated_group_relative_error"] = "5e-6"
        self.physics["solid_solver_linear_residual"] = "5e-6"
        self.physics["solver_linear_residual"] = "5e-6"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", True)

    def test_manifest_physics_residual_limit_is_required(self) -> None:
        self.physics.pop("physics_residual_limit")
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_manifest_solver_convergence_limit_must_be_1e5(self) -> None:
        self.physics["solver_convergence_limit"] = "1e-6"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_manifest_solver_relative_tolerance_must_be_1e4(self) -> None:
        self.physics["solver_relative_tolerance"] = "1e-5"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_fixed_25_segregated_iteration_contract_passes(self) -> None:
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", True)

    def test_convergence_termination_contract_is_required(self) -> None:
        self.physics.pop("convergence_termination")
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_direct_error_check_off_bypass_fails(self) -> None:
        self.physics["direct_error_check"] = "off"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_segregated_termination_off_bypass_fails(self) -> None:
        self.physics["segregated_termination"] = "off"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_fixed_segregated_iterations_24_fails(self) -> None:
        self.physics["fixed_segregated_iterations"] = "24"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_fixed_segregated_iterations_26_fails(self) -> None:
        self.physics["fixed_segregated_iterations"] = "26"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_full_field_physics", False)

    def test_missing_displacement_target_fails(self) -> None:
        self.comparison.pop()
        checks = self.run_gate()
        self.assert_check(checks, "inverse_cross_model_discrepancy", False)

    def test_stale_reported_error_is_recomputed_and_fails(self) -> None:
        self.comparison[0]["electric_error_pct"] = "0.01"
        checks = self.run_gate()
        self.assert_check(checks, "inverse_cross_model_discrepancy", False)


class SourceIdentityTests(unittest.TestCase):
    def test_new_delivery_name_does_not_target_historical_20260717_package(self) -> None:
        self.assertEqual("fgmee_final_delivery_20260720", BUILDER.PACKAGE_NAME)
        self.assertNotEqual("fgmee_final_delivery_20260717", BUILDER.PACKAGE_NAME)

    def test_runtime_sources_are_direct_copied_without_text_rewriting(self) -> None:
        source = inspect.getsource(BUILDER.copy_runtime_code)
        self.assertNotIn(".read_text(", source)
        self.assertNotIn(".replace(", source)
        self.assertNotIn('"RunInverseSensorCfffValidation.java"', source)
        self.assertNotIn('"RunFullyCoupledInverseSensorCfffValidation.java"', source)
        self.assertIn('"RunBlockTriangularInverseSensorCfffValidation.java"', source)

    def test_inverse_matlab_runtime_helpers_are_packaged_and_required(self) -> None:
        source = inspect.getsource(BUILDER.copy_runtime_code)
        for helper in (
            "build_active_layer_dof_map.m",
            "interpolate_shell_dof_at_point.m",
        ):
            with self.subTest(helper=helper):
                self.assertIn(helper, BUILDER.RUNTIME_MATLAB_HELPERS)
                self.assertIn("RUNTIME_MATLAB_HELPERS", source)
                self.assertIn(f"code/matlab/lib/{helper}", VALIDATOR.REQUIRED_FILES)

    def test_code_closure_report_is_direct_copied(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            report = root / "outputs" / "code_closure" / "CODE_CLOSURE_SIX_STEP_REPORT.md"
            report.parent.mkdir(parents=True)
            report.write_bytes(b"# Six-step code closure\r\nformal evidence\r\n")
            previous_root = BUILDER.ROOT
            previous_target = BUILDER.TARGET
            try:
                BUILDER.ROOT = root
                BUILDER.TARGET = root / "package"
                BUILDER.SOURCE_PROVENANCE.clear()
                destination = BUILDER.copy_code_closure_report()
            finally:
                BUILDER.ROOT = previous_root
                BUILDER.TARGET = previous_target
            self.assertEqual(report.read_bytes(), destination.read_bytes())
            self.assertEqual("report/CODE_CLOSURE_SIX_STEP_REPORT.md", BUILDER.SOURCE_PROVENANCE[0]["package_path"])

    def test_delivery_scope_excludes_legacy_report_and_build_tool(self) -> None:
        runtime_source = inspect.getsource(BUILDER.copy_runtime_code)
        report_source = inspect.getsource(BUILDER.copy_models_and_code_closure_report)
        self.assertNotIn("BUILD_REPORT.ps1", runtime_source)
        self.assertNotIn("fgmee_latest_feasible_results_report_20260715", report_source)
        self.assertNotIn("curvature_fg_report_macros.tex", report_source)
        self.assertNotIn("Fig_03_isomorphic_solid_closure.pdf", report_source)
        self.assertIn("copy_code_closure_report()", report_source)

    def test_validator_requires_new_report_not_legacy_pdf(self) -> None:
        self.assertIn("report/CODE_CLOSURE_SIX_STEP_REPORT.md", VALIDATOR.REQUIRED_FILES)
        self.assertNotIn("BUILD_REPORT.ps1", VALIDATOR.REQUIRED_FILES)
        self.assertFalse(
            any("fgmee_latest_feasible_results_report_20260715" in path for path in VALIDATOR.REQUIRED_FILES)
        )

    def test_inverse_comsol_runner_sets_run_id_and_source_sha256(self) -> None:
        source = (ROOT / "tools" / "package_fgmee" / "RUN_COMSOL.ps1").read_text(
            encoding="utf-8-sig"
        )
        self.assertIn("$Config.Env['FG_FOUR_FIELD_RUN_ID']", source)
        self.assertIn("$Config.Env['FG_FOUR_FIELD_SOURCE_SHA256']", source)
        self.assertIn("[DateTime]::UtcNow.ToString", source)
        self.assertIn("Get-FileHash -LiteralPath $Source -Algorithm SHA256", source)

    def test_copy_file_records_equal_source_and_package_hashes(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            temp_path = Path(temp)
            source = temp_path / "source.m"
            source.write_bytes(b"formal solver bytes\r\n")
            previous_target = BUILDER.TARGET
            try:
                BUILDER.TARGET = temp_path / "package"
                BUILDER.SOURCE_PROVENANCE.clear()
                destination = BUILDER.copy_file(source, "code/matlab/source.m")
            finally:
                BUILDER.TARGET = previous_target
            self.assertEqual(source.read_bytes(), destination.read_bytes())
            self.assertEqual(1, len(BUILDER.SOURCE_PROVENANCE))
            record = BUILDER.SOURCE_PROVENANCE[0]
            self.assertEqual(record["source_sha256"], record["package_sha256"])

    def test_inverse_packaging_joins_same_mesh_raw_values_and_passes_gate(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            matlab_path = (
                root
                / "outputs"
                / "code_closure"
                / "inverse_sensing"
                / "matlab_inverse_structural_pyro_mesh.csv"
            )
            comsol_dir = root / "outputs" / "code_closure" / "comsol_four_field"
            matlab_rows: list[dict[str, object]] = []
            comsol_rows: list[dict[str, object]] = []
            for target in (0.5, 1.0, 2.0):
                matlab_rows.append(
                    {
                        "mesh_divisions": 10,
                        "target_w_mm": target,
                        "electric_span_V": 100.0 * target,
                        "magnetic_span_A": 0.04 * target,
                        "mechanical_thermal_relative_residual": "1e-12",
                        "sensor_relative_residual": "2e-12",
                        "solve_status": "ok",
                        "sensor_status": "ok",
                        "input_file": "Thermal_CFFF_U_Vf0.6-10x10-10layer.txt",
                    }
                )
                comsol_rows.append(
                    {
                        "mesh_divisions": 10,
                        "thickness_divisions_per_layer": 1,
                        "target_w_mm": target,
                        "comsol_electric_V": 102.0 * target,
                        "comsol_magnetic_A": 0.0392 * target,
                        "status": "completed_full_field",
                        "evidence_tier": "A_independent_block_triangular_fields",
                    }
                )
            write_csv(matlab_path, matlab_rows)
            write_csv(comsol_dir / "comsol_four_field_summary.csv", comsol_rows)
            write_csv(comsol_dir / "comsol_four_field_layers.csv", [{"layer": 1, "value": 0}])
            write_csv(
                comsol_dir / "comsol_four_field_physics_manifest.csv",
                [
                    {
                        "case_id": "inverse_CFFF_U_Vf06",
                        "solve_u": "true",
                        "solve_phi": "true",
                        "solve_psi": "true",
                        "solve_T": "true",
                        "method": "sequential_equivalent_four_field_solution",
                        "evidence_tier": "A_independent_block_triangular_fields",
                        "solver_strategy": "segregated_same_stationary",
                        "convergence_termination": "fixed_25_segregated_iterations_with_final_residual_gate",
                        "direct_error_check": "auto_enabled",
                        "segregated_termination": "iter",
                        "fixed_segregated_iterations": "25",
                        "coupling_equivalent_to_matlab": "true",
                        "layer_field_layout": "independent_per_physical_layer",
                        "observable_definition": "max_minus_min_of_layer_top_bottom_area_average_potential_difference",
                        "layer_drop_definition": "layer_thickness_times_volume_average_potential_gradient_equivalent_to_face_average_difference",
                        "mechanical_force_balance_residual": "1e-9",
                        "electric_weak_moment_residual": "2e-9",
                        "magnetic_weak_moment_residual": "3e-9",
                        "thermal_weak_moment_residual": "4e-9",
                        "solid_discrete_segregated_group_relative_error": "5e-9",
                        "electric_discrete_segregated_group_relative_error": "6e-9",
                        "magnetic_discrete_segregated_group_relative_error": "7e-9",
                        "thermal_discrete_segregated_group_relative_error": "8e-9",
                        "solid_solver_linear_residual": "9e-9",
                        "electric_solver_linear_residual": "1e-8",
                        "magnetic_solver_linear_residual": "1.1e-8",
                        "thermal_solver_linear_residual": "1.2e-8",
                        "solver_linear_residual": "1.2e-8",
                        "residual_definition": "mechanical=global_force_balance;weak_moment=max_layer_normalized_constitutive_flux_moment;discrete_group_error=max_final_outer_iteration_error_by_field;solver_linear_residual=max_final_inner_LinRes_by_field",
                        "field_residual_evaluation_status": "pass",
                        "solver_has_problems": "false",
                        "physics_residual_limit": "1e-6",
                        "solver_convergence_limit": "1e-5",
                        "solver_relative_tolerance": "1e-4",
                        "run_id": "fixture-run",
                        "source_sha256": "b" * 64,
                        "status": "completed_full_field",
                        "same_stationary": "true",
                        "open_circuit_electric": "true",
                        "open_circuit_magnetic": "true",
                        "insulated_thermal": "true",
                        "independent_dof_fields": "true",
                        "geometry_material_boundary_layer_observable_aligned": "true",
                        "api_channel_isolation_status": "pass",
                        "physical_layer_count": "10",
                        "fg_mode": "U",
                        "vf0": "0.6",
                        "isomorphic_to_matlab_10layer": "false",
                        "comparison_scope": "same_geometry_material_boundary_observable_nonisomorphic_mechanics",
                        "mechanical_discretization": "COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell",
                    }
                ],
            )
            write_csv(
                comsol_dir / "comsol_four_field_channel_isolation.csv",
                [
                    {"channel": "electric", "gateE": 1, "gateM": 0, "gateT": 0, "isolation_status": "pass"},
                    {"channel": "magnetic", "gateE": 0, "gateM": 1, "gateT": 0, "isolation_status": "pass"},
                    {"channel": "thermal", "gateE": 0, "gateM": 0, "gateT": 1, "isolation_status": "pass"},
                ],
            )

            previous_root = BUILDER.ROOT
            previous_target = BUILDER.TARGET
            try:
                BUILDER.ROOT = root
                BUILDER.TARGET = root / "package"
                BUILDER.SOURCE_PROVENANCE.clear()
                BUILDER.copy_inverse_results()
                checks = VALIDATOR.validate_inverse_code_closure(BUILDER.TARGET)
            finally:
                BUILDER.ROOT = previous_root
                BUILDER.TARGET = previous_target
            self.assertTrue(all(bool(check["passed"]) for check in checks), checks)

    def test_builder_preflight_rejects_single_layer_smoke(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "matlab").mkdir(parents=True)
            (root / "matlab" / "run_meet_static.m").write_text("formal", encoding="utf-8")
            for helper in BUILDER.RUNTIME_MATLAB_HELPERS:
                (root / "matlab" / helper).write_text("formal", encoding="utf-8")
            java = root / "tools" / "comsol" / "RunBlockTriangularInverseSensorCfffValidation.java"
            java.parent.mkdir(parents=True)
            java.write_text("formal", encoding="utf-8")
            report = root / "outputs" / "code_closure" / "CODE_CLOSURE_SIX_STEP_REPORT.md"
            report.parent.mkdir(parents=True, exist_ok=True)
            report.write_text("# Six-step code closure\n", encoding="utf-8")
            matlab_csv = (
                root / "outputs" / "code_closure" / "inverse_sensing"
                / "matlab_inverse_structural_pyro_mesh.csv"
            )
            write_csv(matlab_csv, [{"mesh_divisions": 10, "target_w_mm": 0.5}])
            comsol_dir = root / "outputs" / "code_closure" / "comsol_four_field"
            write_csv(
                comsol_dir / "comsol_four_field_summary.csv",
                [
                    {
                        "target_w_mm": target,
                        "status": "completed_full_field",
                        "evidence_tier": "A_independent_block_triangular_fields",
                    }
                    for target in (0.5, 1.0, 2.0)
                ],
            )
            write_csv(comsol_dir / "comsol_four_field_layers.csv", [{"layer": 1}])
            write_csv(
                comsol_dir / "comsol_four_field_physics_manifest.csv",
                [
                    {
                        "physical_layer_count": 1,
                        "fg_mode": "U",
                        "vf0": 0.6,
                        "isomorphic_to_matlab_10layer": "false",
                        "comparison_scope": "four_field_code_path_only",
                        "method": "sequential_equivalent_four_field_solution",
                        "evidence_tier": "A_independent_block_triangular_fields",
                        "solver_strategy": "segregated_same_stationary",
                        "coupling_equivalent_to_matlab": "true",
                        "layer_field_layout": "independent_per_physical_layer",
                        "observable_definition": "max_minus_min_of_layer_top_bottom_area_average_potential_difference",
                        "status": "completed_full_field",
                    }
                ],
            )
            write_csv(comsol_dir / "comsol_four_field_channel_isolation.csv", [{"channel": "smoke"}])
            (comsol_dir / "comsol_four_field_Model.mph").write_bytes(b"model")
            previous_root = BUILDER.ROOT
            try:
                BUILDER.ROOT = root
                with self.assertRaisesRegex(RuntimeError, "not the formal ten-layer"):
                    BUILDER.preflight_code_closure_sources()
            finally:
                BUILDER.ROOT = previous_root


if __name__ == "__main__":
    unittest.main()
