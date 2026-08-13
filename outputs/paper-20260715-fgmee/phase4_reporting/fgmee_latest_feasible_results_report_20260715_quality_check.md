# Stage-2 扩展验证门槛

总体状态：通过

| 检查 | 状态 | 证据 |
|---|---|---|
| isomorphic_six_rows | pass | 6 |
| isomorphic_center_error_le_0p1pct | pass | 0.00017690163831768046 |
| isomorphic_free_mid_error_le_0p1pct | pass | 0.00012127289258313264 |
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
| inverse_actuation_three_targets | pass | 3 |
| inverse_actuation_target_specific_comsol_residual_le_0p001pct | pass | 0.00037503631278301697 |
| inverse_local_constitutive_scaled_condition_le_1p1 | pass | [{'c11_Pa': '136342676220.87405', 'c12_Pa': '46329241379.853004', 'e31_C_per_m2': '-9.87159042714329', 'g_effective': '8.136078506634354e-09', 'k33': '1.755e-08', 'r33': '7.536e-05', 'determinant': '6.128268737599648e-13', 'normalized_coupling_rho': '0.02241295456018969', 'dimensionless_condition_number': '1.0458536243186534', 'verdict': 'well_conditioned_after_unit_scaling'}] |
| inverse_actuation_matlab_load_cross_applied_to_comsol | pass | [{'channel': 'electric', 'target_abs_w_mm': '0.5', 'matlab_inverted_load': '2870.423627868996', 'comsol_cross_applied_w_mm': '0.5538629038121122', 'comsol_w_over_target': '1.1077258076242245', 'comsol_target_difference_pct': '10.772580762422447', 'interpretation': 'nonisomorphic_model_form_difference_not_solver_failure'}, {'channel': 'magnetic', 'target_abs_w_mm': '0.5', 'matlab_inverted_load': '572.7844432631446', 'comsol_cross_applied_w_mm': '0.5463396053249225', 'comsol_w_over_target': '1.092679210649845', 'comsol_target_difference_pct': '9.267921064984508', 'interpretation': 'nonisomorphic_model_form_difference_not_solver_failure'}] |
| inverse_sensing_explicitly_not_independent_phi_psi_pde | pass | [{'target_abs_w_mm': '0.5', 'matlab_zero_temperature_layer_span_V': '68.9062639956534', 'three_d_mechanics_zero_temperature_layer_span_V': '71.29415727195605', 'matlab_zero_temperature_layer_span_A': '0.05326589070453365', 'three_d_mechanics_zero_temperature_layer_span_A': '0.05511177894304917', 'matlab_layer_span_V': '78.4802748394657', 'three_d_mechanics_postprocess_layer_span_V': '81.1999480555809', 'matlab_layer_span_A': '0.030900039122573032', 'three_d_mechanics_postprocess_layer_span_A': '0.03197085607562874', 'shared_mechanical_scale_difference_pct': '3.465422644961939', 'observable_definition': 'max_minus_min_of_layerwise_potential_difference_dofs', 'thermal_boundary_for_corrected_span': 'no_external_thermal_load_with_reciprocal_temperature_response_from_KTu_u_plus_KTT_T_equals_zero', 'independent_comsol_phi_psi_pde': 'no', 'reporting_status': 'exploratory_nonindependent_constitutive_postprocess'}, {'target_abs_w_mm': '1.0', 'matlab_zero_temperature_layer_span_V': '137.8125279913068', 'three_d_mechanics_zero_temperature_layer_span_V': '142.5883145439121', 'matlab_zero_temperature_layer_span_A': '0.1065317814090673', 'three_d_mechanics_zero_temperature_layer_span_A': '0.11022355788609833', 'matlab_layer_span_V': '156.9605496789314', 'three_d_mechanics_postprocess_layer_span_V': '162.3998961111618', 'matlab_layer_span_A': '0.061800078245146065', 'three_d_mechanics_postprocess_layer_span_A': '0.06394171215125748', 'shared_mechanical_scale_difference_pct': '3.465422644961939', 'observable_definition': 'max_minus_min_of_layerwise_potential_difference_dofs', 'thermal_boundary_for_corrected_span': 'no_external_thermal_load_with_reciprocal_temperature_response_from_KTu_u_plus_KTT_T_equals_zero', 'independent_comsol_phi_psi_pde': 'no', 'reporting_status': 'exploratory_nonindependent_constitutive_postprocess'}, {'target_abs_w_mm': '2.0', 'matlab_zero_temperature_layer_span_V': '275.6250559826136', 'three_d_mechanics_zero_temperature_layer_span_V': '285.1766290878242', 'matlab_zero_temperature_layer_span_A': '0.2130635628181346', 'three_d_mechanics_zero_temperature_layer_span_A': '0.22044711577219667', 'matlab_layer_span_V': '313.9210993578628', 'three_d_mechanics_postprocess_layer_span_V': '324.7997922223236', 'matlab_layer_span_A': '0.12360015649029213', 'three_d_mechanics_postprocess_layer_span_A': '0.12788342430251495', 'shared_mechanical_scale_difference_pct': '3.465422644961939', 'observable_definition': 'max_minus_min_of_layerwise_potential_difference_dofs', 'thermal_boundary_for_corrected_span': 'no_external_thermal_load_with_reciprocal_temperature_response_from_KTu_u_plus_KTT_T_equals_zero', 'independent_comsol_phi_psi_pde': 'no', 'reporting_status': 'exploratory_nonindependent_constitutive_postprocess'}] |
| inverse_actuation_six_clean_comsol_logs | pass | ['comsol_inverse_actuation_electric_target_0p5mm.log', 'comsol_inverse_actuation_electric_target_1p0mm.log', 'comsol_inverse_actuation_electric_target_2p0mm.log', 'comsol_inverse_actuation_magnetic_target_0p5mm.log', 'comsol_inverse_actuation_magnetic_target_1p0mm.log', 'comsol_inverse_actuation_magnetic_target_2p0mm.log'] |
| inverse_actuation_six_comsol_models | pass | [('comsol_inverse_actuation_electric_target_0p5mm_Model.mph', 27194631), ('comsol_inverse_actuation_electric_target_1p0mm_Model.mph', 27194613), ('comsol_inverse_actuation_electric_target_2p0mm_Model.mph', 27195161), ('comsol_inverse_actuation_magnetic_target_0p5mm_Model.mph', 26189843), ('comsol_inverse_actuation_magnetic_target_1p0mm_Model.mph', 26189698), ('comsol_inverse_actuation_magnetic_target_2p0mm_Model.mph', 26189689)] |
| inverse_actuation_two_clean_cross_application_logs | pass | ['comsol_inverse_actuation_electric_target_0p5mm_matlab_load_crosscheck.log', 'comsol_inverse_actuation_magnetic_target_0p5mm_matlab_load_crosscheck.log'] |
| inverse_actuation_two_cross_application_models | pass | [('comsol_inverse_actuation_electric_target_0p5mm_matlab_load_crosscheck_Model.mph', 27194862), ('comsol_inverse_actuation_magnetic_target_0p5mm_matlab_load_crosscheck_Model.mph', 26189994)] |
| latex_placeholders_resolved | pass | [] |
| report_model_and_load_explanation_complete | pass | geometry, potential-to-stress conversion, evidence-qualified wording, and six free-midpoint rows |
| latest_report_scope_wording | pass | {'has_numerical_experiment': True, 'has_physical_specimen_boundary': True, 'removed_traceability_tail': True} |
| figure_3_png | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_03_isomorphic_solid_closure.png'] |
| figure_3_pdf | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_03_isomorphic_solid_closure.pdf'] |
| figure_4_png | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_04_all_radius_curvature_validation.png'] |
| figure_4_pdf | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_04_all_radius_curvature_validation.pdf'] |
| figure_5_png | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_05_curved_comsol_validation.png'] |
| figure_5_pdf | pass | ['G:\\fg-meet-workbench\\outputs\\paper-20260715-fgmee\\figures\\Fig_05_curved_comsol_validation.pdf'] |
| Fig_00_curved_shell_geometry_loads_png | pass | G:\fg-meet-workbench\outputs\paper-20260715-fgmee\figures\Fig_00_curved_shell_geometry_loads.png |
| Fig_00_curved_shell_geometry_loads_pdf | pass | G:\fg-meet-workbench\outputs\paper-20260715-fgmee\figures\Fig_00_curved_shell_geometry_loads.pdf |
| Fig_00_material_boundary_loads_png | pass | G:\fg-meet-workbench\outputs\paper-20260715-fgmee\figures\Fig_00_material_boundary_loads.png |
| Fig_00_material_boundary_loads_pdf | pass | G:\fg-meet-workbench\outputs\paper-20260715-fgmee\figures\Fig_00_material_boundary_loads.pdf |
| model_figure_script_exists | pass | G:\fg-meet-workbench\tools\plotting\plot_model_geometry_loads.py |
| model_figure_provenance_exists | pass | G:\fg-meet-workbench\outputs\paper-20260715-fgmee\figures\model_schematic_provenance.md |
| screenshot_requirements_R1_to_R9_traced | pass | G:\fg-meet-workbench\outputs\paper-20260715-fgmee\phase4_reporting\fgmee_requirement_recheck_20260718.md |
| compiled_pdf_exists | pass | G:\fg-meet-workbench\outputs\paper-20260715-fgmee\phase4_reporting\fgmee_latest_feasible_results_report_20260715.pdf |
