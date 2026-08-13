# Stage-2 扩展验证门槛

总体状态：通过

| 检查 | 状态 | 证据 |
|---|---|---|
| isomorphic_six_rows | pass | 6 |
| isomorphic_center_error_le_0p1pct | pass | 0.00017690163831768046 |
| isomorphic_all_acceptance_gates | pass | ['pass', 'pass', 'pass', 'pass', 'pass', 'pass'] |
| isomorphic_comsol_six_clean_logs | pass | ['comsol_isomorphic_electric_equivalent_stress_10x.log', 'comsol_isomorphic_electric_equivalent_stress_15x.log', 'comsol_isomorphic_electric_equivalent_stress_20x.log', 'comsol_isomorphic_magnetic_external_stress_10x.log', 'comsol_isomorphic_magnetic_external_stress_15x.log', 'comsol_isomorphic_magnetic_external_stress_20x.log'] |
| isomorphic_comsol_six_models | pass | [('comsol_isomorphic_electric_equivalent_stress_10x_Model.mph', 3616217), ('comsol_isomorphic_electric_equivalent_stress_15x_Model.mph', 5040373), ('comsol_isomorphic_electric_equivalent_stress_20x_Model.mph', 6939455), ('comsol_isomorphic_magnetic_external_stress_10x_Model.mph', 3616155), ('comsol_isomorphic_magnetic_external_stress_15x_Model.mph', 5040154), ('comsol_isomorphic_magnetic_external_stress_20x_Model.mph', 6939410)] |
| matlab_h20_equilibrium_residual_le_1e_6 | pass | 5.74063548165051e-09 |
| discrepancy_decomposition_six_rows | pass | 6 |
| wrong_radius_anomaly_closed_by_audited_inputs | pass | {'old_curve_gap_pct': 3.287301162891138, 'corrected_curve_gap_pct': 0.005858832940377537, 'isomorphic_cross_solver_max_pct': 0.00017690163831768046} |
| curvature_raw_48_rows | pass | 48 |
| curvature_raw_48_unique_keys | pass | 48 |
| curvature_raw_completed | pass | ['completed_corrected_pyro'] |
| curvature_final_24_rows | pass | 24 |
| curvature_interaction_12_rows | pass | 12 |
| curvature_radius_summary_4_rows | pass | 4 |
| curvature_all_1pct_mesh_gate | pass | 0.007877531344657773 |
| curvature_material_and_radius_passport | pass | {'manifest_cases': '24', 'U_unique_material_numeric_hashes': '1', 'X_unique_material_numeric_hashes': '1', 'radius_mismatch_count': '0', 'audit_status': 'pass'} |
| curved_comsol_three_meshes | pass | 3 |
| curved_comsol_15_to_20_le_1pct | pass | 0.9651346744455362 |
| curved_comsol_sign_and_scale | pass | {'sign': 'pass', 'scale': 'pass'} |
| curved_comparison_labeled_nonisomorphic | pass | not_a_cross_solver_numerical_error |
| curved_comsol_three_clean_logs | pass | ['comsol_curved_U_R0p4_10x10x10_meshcheck.log', 'comsol_curved_U_R0p4_15x15x10_meshcheck.log', 'comsol_curved_U_R0p4_20x20x10_final.log'] |
| curved_comsol_three_models | pass | [('comsol_curved_U_R0p4_10x10x10_meshcheck_Model.mph', 2785108), ('comsol_curved_U_R0p4_15x15x10_meshcheck_Model.mph', 3568318), ('comsol_curved_U_R0p4_20x20x10_final_Model.mph', 4745131)] |
| latex_placeholders_resolved | pass | [] |
| figure_3_png | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_03_isomorphic_solid_closure.png'] |
| figure_3_pdf | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_03_isomorphic_solid_closure.pdf'] |
| figure_4_png | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_04_all_radius_curvature_validation.png'] |
| figure_4_pdf | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_04_all_radius_curvature_validation.pdf'] |
| figure_5_png | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_05_curved_comsol_validation.png'] |
| figure_5_pdf | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_05_curved_comsol_validation.pdf'] |
| compiled_pdf_exists | pass | G:\fg-meet-workbench\output\pdf\stage2_validation_report_20260715_v3.pdf |
