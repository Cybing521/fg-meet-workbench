function tests = test_pyro_layer_mapping
%TEST_PYRO_LAYER_MAPPING Verify physical layers map to their own MEE DOF.
    tests = functiontests(localfunctions);
end

function testUniformTenLayerMapsOneDofPerLayer(testCase)
    paths = setup_paths();
    caseFile = fullfile(paths.cases, 'validation_mesh', ...
        'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt');
    [fem, material] = SF_GetInputDataMEEP(caseFile);
    mateProp = SF_GetMatePropMEEP(material, fem);

    verifyLayerMaps(testCase, mateProp, material, 1:10);
end

function testNonuniformXPreservesLayerCoefficients(testCase)
    paths = setup_paths();
    caseFile = fullfile(paths.cases, 'curvature_fg', '20x20', ...
        'Thermal_CFFF_X_Vf0.6_R0.4m-20x20-10layer.txt');
    [fem, material] = SF_GetInputDataMEEP(caseFile);
    mateProp = SF_GetMatePropMEEP(material, fem);

    verifyLayerMaps(testCase, mateProp, material, 1:10);
    verifyNotEqual(testCase, material(1, 20), material(5, 20));
    verifyNotEqual(testCase, material(1, 21), material(5, 21));
end

function testAnisotropicPiezoComponentsUseTheirOwnPermittivityTerms(testCase)
    paths = setup_paths();
    caseFile = fullfile(paths.cases, 'validation_mesh', ...
        'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt');
    [~, material] = SF_GetInputDataMEEP(caseFile);
    material = material(1, :);
    material(1) = 1;
    material(2:5) = [12, 5, 0.2, 0.3];
    material(6:8) = [4, 3, 2];
    material(9:10) = [2, 3];
    material(11) = 0;
    material(15) = 200;
    material(27) = 2;
    fem = struct('ElemType', [8, 5, 1, 1, 1]);

    mateProp = SF_GetMatePropMEEP(material, fem);
    e31 = mateProp{1}.eM(1, 1);
    e32 = mateProp{1}.eM(1, 2);
    expectedG33 = material(15) - material(9) * e31 - material(10) * e32;
    legacyWrongG33 = material(15) - ...
        (material(9) + material(10)) * e31;

    verifyGreaterThan(testCase, abs(e31 - e32), 1);
    verifyGreaterThan(testCase, abs(expectedG33 - legacyWrongG33), 1);
    verifyEqual(testCase, mateProp{1}.gM(1, 1), expectedG33, 'AbsTol', 1e-12);
end

function testInactiveLayersUseCompactedActiveDofs(testCase)
    paths = setup_paths();
    caseFile = fullfile(paths.cases, 'validation_mesh', ...
        'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt');
    [~, material] = SF_GetInputDataMEEP(caseFile);
    material = material(1:4, :);
    material(:, 1) = (1:4)';
    material(:, 27) = [2; 1; 2; 1];
    fem = struct('ElemType', [8, 5, 4, 1, 2]);
    mateProp = SF_GetMatePropMEEP(material, fem);

    expectedP1 = diag([material(1, 20), 0]);
    expectedT1 = diag([material(1, 21), 0]);
    expectedP3 = diag([0, material(3, 20)]);
    expectedT3 = diag([0, material(3, 21)]);
    verifyEqual(testCase, mateProp{1}.p, expectedP1, 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{1}.t, expectedT1, 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{2}.p, zeros(2), 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{2}.t, zeros(2), 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{3}.p, expectedP3, 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{3}.t, expectedT3, 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{4}.p, zeros(2), 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{4}.t, zeros(2), 'AbsTol', 1e-15);
end

function testSingleLayerMapsSingleDof(testCase)
    paths = setup_paths();
    caseFile = fullfile(paths.cases, 'validation_mesh', ...
        'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt');
    [~, material] = SF_GetInputDataMEEP(caseFile);
    material = material(1, :);
    material(1) = 1;
    material(27) = 2;
    fem = struct('ElemType', [8, 5, 1, 1, 1]);
    mateProp = SF_GetMatePropMEEP(material, fem);

    verifyEqual(testCase, mateProp{1}.p, material(20), 'AbsTol', 1e-15);
    verifyEqual(testCase, mateProp{1}.t, material(21), 'AbsTol', 1e-15);
end

function verifyLayerMaps(testCase, mateProp, material, layerIndices)
    nActive = numel(layerIndices);
    for activeIndex = 1:nActive
        layerIndex = layerIndices(activeIndex);
        expectedP = zeros(nActive);
        expectedT = zeros(nActive);
        expectedP(activeIndex, activeIndex) = material(layerIndex, 20);
        expectedT(activeIndex, activeIndex) = material(layerIndex, 21);
        verifyEqual(testCase, mateProp{layerIndex}.p, expectedP, 'AbsTol', 1e-15);
        verifyEqual(testCase, mateProp{layerIndex}.t, expectedT, 'AbsTol', 1e-15);
    end
end
