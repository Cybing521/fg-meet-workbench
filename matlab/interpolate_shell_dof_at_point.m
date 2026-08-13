function [value, probe] = interpolate_shell_dof_at_point( ...
        Node, Element, fullDofVector, targetCoord, dofIndex, dofsPerNode)
%INTERPOLATE_SHELL_DOF_AT_POINT Evaluate an 8-node shell field at a point.
%   Bundled validation meshes are rectangular in the first two shell
%   coordinates and use the standard serendipity node order 1..8.  Odd mesh
%   divisions do not contain a node at the geometric center, so selecting a
%   nearest node biases the reported center displacement.

    if size(Element, 2) < 8
        error('interpolate_shell_dof_at_point:InvalidElement', ...
            'Element connectivity must contain eight shell nodes.');
    end
    if dofIndex < 1 || dofIndex > dofsPerNode
        error('interpolate_shell_dof_at_point:InvalidDof', ...
            'Requested DOF %d is outside 1..%d.', dofIndex, dofsPerNode);
    end

    targetXY = targetCoord(1:2);
    tolerance = 1e-10 * max(1, max(abs(Node(:, 2:3)), [], 'all'));
    selectedElement = NaN;
    selectedNodeIds = [];
    xi = NaN;
    eta = NaN;

    for elementIndex = 1:size(Element, 1)
        nodeIds = Element(elementIndex, 1:8);
        cornerXY = Node(nodeIds(1:4), 2:3);
        xyMin = min(cornerXY, [], 1);
        xyMax = max(cornerXY, [], 1);
        if all(targetXY >= xyMin - tolerance) && all(targetXY <= xyMax + tolerance)
            span = xyMax - xyMin;
            if any(span <= tolerance)
                continue;
            end
            selectedElement = elementIndex;
            selectedNodeIds = nodeIds;
            xi = 2 * (targetXY(1) - mean([xyMin(1), xyMax(1)])) / span(1);
            eta = 2 * (targetXY(2) - mean([xyMin(2), xyMax(2)])) / span(2);
            break;
        end
    end

    if isnan(selectedElement)
        error('interpolate_shell_dof_at_point:PointOutsideMesh', ...
            'Target point (%.9g, %.9g) is outside the shell mesh.', ...
            targetXY(1), targetXY(2));
    end

    shapeValues = [ ...
        0.25*(1-xi)*(1-eta)*(-xi-eta-1), ...
        0.25*(1+xi)*(1-eta)*( xi-eta-1), ...
        0.25*(1+xi)*(1+eta)*( xi+eta-1), ...
        0.25*(1-xi)*(1+eta)*(-xi+eta-1), ...
        0.5*(1-xi^2)*(1-eta), ...
        0.5*(1-eta^2)*(1+xi), ...
        0.5*(1-xi^2)*(1+eta), ...
        0.5*(1-eta^2)*(1-xi)];
    dofPositions = (selectedNodeIds - 1) * dofsPerNode + dofIndex;
    value = shapeValues * fullDofVector(dofPositions);

    probe = struct();
    probe.method = 'eight_node_serendipity_interpolation';
    probe.element_index = selectedElement;
    probe.node_ids = selectedNodeIds;
    probe.natural_coordinate = [xi, eta];
    probe.shape_values = shapeValues;
    probe.target_coordinate = targetCoord;
end
