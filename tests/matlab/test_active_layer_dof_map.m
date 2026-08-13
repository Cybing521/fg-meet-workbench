function tests = test_active_layer_dof_map
tests = functiontests(localfunctions);
end

function setupOnce(~)
setup_paths();
end

function testMapsCompactedDofsBackToPhysicalLayers(testCase)
finitElemInfo = struct();
finitElemInfo.ElemType = [8, 5, 3, 1, 2];
% Columns 9:11 are physical-layer presence flags.  Layer 2 is a passive
% material and layer 3 is absent from element 2.
finitElemInfo.Element = [1:8, 1, 1, 1; 9:16, 1, 1, 0];

mateProp = cell(3, 1);
mateProp{1} = struct('IsSmtLay', 2);
mateProp{2} = struct('IsSmtLay', 1);
mateProp{3} = struct('IsSmtLay', 2);

map = build_active_layer_dof_map(finitElemInfo, mateProp, 3);

verifyEqual(testCase, map.physical_layer_by_dof, [1; 3; 1]);
verifyEqual(testCase, map.element_by_dof, [1; 1; 2]);
verifyEqual(testCase, map.first_dof_by_element, [1; 3]);
verifyEqual(testCase, map.last_dof_by_element, [2; 3]);
end

function testRejectsUnsupportedMultipleDofsPerLayer(testCase)
finitElemInfo = struct('ElemType', [8, 5, 1, 2, 1], ...
    'Element', [1:8, 1]);
mateProp = {struct('IsSmtLay', 2)};

verifyError(testCase, ...
    @() build_active_layer_dof_map(finitElemInfo, mateProp, 2), ...
    'build_active_layer_dof_map:UnsupportedDofsPerLayer');
end
