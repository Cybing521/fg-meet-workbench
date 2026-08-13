function map = build_active_layer_dof_map(FinitElemInfo, MateProp, expectedDofCount)
%BUILD_ACTIVE_LAYER_DOF_MAP Map condensed MEE DOFs to physical layers.
%   The bundled element matrices allocate one electric, magnetic and
%   reciprocal-temperature slot for each smart-material layer in each
%   element. SF_Condensation removes slots for layers absent from an
%   element. This routine reconstructs that exact compact ordering.

    elemType = FinitElemInfo.ElemType;
    nodePerElem = elemType(1);
    numPhysicalLayers = elemType(3);
    dofsPerMEELayer = elemType(4);
    if dofsPerMEELayer ~= 1
        error('build_active_layer_dof_map:UnsupportedDofsPerLayer', ...
            ['Layer mapping is defined for one MEE DOF per active layer; ' ...
             'the input declares %d.'], dofsPerMEELayer);
    end

    element = FinitElemInfo.Element;
    numElements = size(element, 1);
    layerStart = nodePerElem + 1;
    physicalLayerByDof = zeros(expectedDofCount, 1);
    elementByDof = zeros(expectedDofCount, 1);
    firstDofByElement = nan(numElements, 1);
    lastDofByElement = nan(numElements, 1);
    dofIndex = 0;

    for elementIndex = 1:numElements
        for layerIndex = 1:numPhysicalLayers
            isSmart = MateProp{layerIndex, 1}.IsSmtLay == 2;
            isPresent = element(elementIndex, layerStart + layerIndex - 1) ~= 0;
            if isSmart && isPresent
                dofIndex = dofIndex + 1;
                if dofIndex > expectedDofCount
                    error('build_active_layer_dof_map:DofCountMismatch', ...
                        'Mapped more than the expected %d MEE DOFs.', expectedDofCount);
                end
                physicalLayerByDof(dofIndex) = layerIndex;
                elementByDof(dofIndex) = elementIndex;
                if isnan(firstDofByElement(elementIndex))
                    firstDofByElement(elementIndex) = dofIndex;
                end
                lastDofByElement(elementIndex) = dofIndex;
            end
        end
    end

    if dofIndex ~= expectedDofCount
        error('build_active_layer_dof_map:DofCountMismatch', ...
            'Mapped %d active layer DOFs, but the condensed system contains %d.', ...
            dofIndex, expectedDofCount);
    end

    map = struct();
    map.physical_layer_by_dof = physicalLayerByDof;
    map.element_by_dof = elementByDof;
    map.first_dof_by_element = firstDofByElement;
    map.last_dof_by_element = lastDofByElement;
    map.num_physical_layers = numPhysicalLayers;
    map.num_active_material_layers = sum(cellfun( ...
        @(entry) entry.IsSmtLay == 2, MateProp));
end
