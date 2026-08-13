function tests = test_shell_probe_interpolation
tests = functiontests(localfunctions);
end

function setupOnce(~)
setup_paths();
end

function testInterpolatesElementCenterWithoutCenterNode(testCase)
node = [ ...
    1, 0.0, 0.0, 0.0; ...
    2, 1.0, 0.0, 0.0; ...
    3, 1.0, 1.0, 0.0; ...
    4, 0.0, 1.0, 0.0; ...
    5, 0.5, 0.0, 0.0; ...
    6, 1.0, 0.5, 0.0; ...
    7, 0.5, 1.0, 0.0; ...
    8, 0.0, 0.5, 0.0];
element = [1:8, 1];
fullDofs = zeros(8 * 5, 1);
for nodeIndex = 1:8
    x = node(nodeIndex, 2);
    y = node(nodeIndex, 3);
    fullDofs((nodeIndex - 1) * 5 + 3) = 2 + 3*x - 4*y + 5*x*y;
end

[value, probe] = interpolate_shell_dof_at_point( ...
    node, element, fullDofs, [0.5, 0.5, 0], 3, 5);

verifyEqual(testCase, value, 2.75, 'AbsTol', 1e-12);
verifyEqual(testCase, probe.element_index, 1);
verifyEqual(testCase, probe.natural_coordinate, [0, 0], 'AbsTol', 1e-12);
verifyEqual(testCase, sum(probe.shape_values), 1, 'AbsTol', 1e-12);
end
