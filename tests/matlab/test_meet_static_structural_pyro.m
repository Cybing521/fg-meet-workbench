function tests = test_meet_static_structural_pyro
%TEST_MEET_STATIC_STRUCTURAL_PYRO End-to-end regression for the official solver.
    tests = functiontests(localfunctions);
end

function testUniformTenLayerMatchesCorrectedBaseline(testCase)
    paths = setup_paths();
    caseFile = fullfile(paths.cases, 'validation_mesh', ...
        'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt');
    result = run_meet_static(caseFile, 'elastic', ...
        'LoadScale', -15000, 'OutTag', 'test_structural_pyro_u10', ...
        'SolveSensors', true, 'UseCache', false, 'Quiet', true);

    scaleToHalfMillimetre = 0.5 / abs(result.wCenter_mm);
    verifyEqual(testCase, result.wCenter_mm, -2.12849830358636, 'AbsTol', 1e-10);
    verifyEqual(testCase, result.electric_span * scaleToHalfMillimetre, ...
        78.4316893709343, 'AbsTol', 1e-8);
    verifyEqual(testCase, result.magnetic_span * scaleToHalfMillimetre, ...
        0.0308809095657324, 'AbsTol', 1e-11);
    verifyEqual(testCase, result.solve_status, 'ok');
    verifyEqual(testCase, result.sensor_status, 'ok');
    verifyEqual(testCase, result.solver_revision, 'layer_local_pyro_v3');
    verifyEqual(testCase, result.centerProbeMethod, ...
        'eight_node_serendipity_interpolation');
    verifyLessThan(testCase, result.mechanical_thermal_relative_residual, 1e-10);
    verifyLessThan(testCase, result.mechanical_thermal_backward_error, 1e-10);
    verifyLessThan(testCase, result.sensor_relative_residual, 1e-10);
    verifyLessThan(testCase, result.sensor_backward_error, 1e-10);
    verifyGreaterThan(testCase, result.mechanical_thermal_rcond_estimate, 0);
    verifyGreaterThan(testCase, result.sensor_rcond_estimate, 0);
    verifyTrue(testCase, isfield(result, 'boundary_definition'));
    verifyEqual(testCase, result.observable_definition, ...
        'max_minus_min_of_physical_layer_average_active_MEE_dofs');
end
