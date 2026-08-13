function result = run_meet_static(caseFile, loadCase, varargin)
%RUN_MEET_STATIC  Static thermo-magneto-electro-elastic solve (bundled MEET FEM).
%
%   result = run_meet_static(caseFile, loadCase)
%   result = run_meet_static(..., 'LoadScale', -15000, 'OutTag', 'U_Vf06')
%
%   loadCase: 'elastic' | 'electro' | 'magneto'  (Case A / B / C)
%   caseFile: path to MEET input txt (from cases/)

    p = inputParser;
    addRequired(p, 'caseFile', @(x) ischar(x) || isstring(x));
    addRequired(p, 'loadCase', @(x) any(strcmpi(x, {'elastic','electro','magneto'})));
    addParameter(p, 'LoadScale', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'Volt', 300, @isnumeric);
    addParameter(p, 'Magnetic', 200, @isnumeric);
    addParameter(p, 'OutTag', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'SolveSensors', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'UseCache', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'Quiet', true, @(x) islogical(x) || isnumeric(x));
    parse(p, caseFile, loadCase, varargin{:});

    paths = setup_paths();
    caseFile = char(caseFile);
    loadCase = char(loadCase);
    if ~isfile(caseFile)
        error('run_meet_static:NoInput', 'Input file not found: %s', caseFile);
    end

    switch lower(loadCase)
        case 'elastic'
            meetDir = paths.meet_elastic;
            defaultLoad = -15000;
        case 'electro'
            meetDir = paths.meet_electro;
            defaultLoad = 0;
        case 'magneto'
            meetDir = paths.meet_magneto;
            defaultLoad = 0;
    end

    if isempty(p.Results.LoadScale)
        loadmax = defaultLoad;
    else
        loadmax = p.Results.LoadScale;
    end

    oldDir = pwd;
    cleanup = onCleanup(@() cd(oldDir)); %#ok<NASGU>
    cd(meetDir);

    InputFile = caseFile;
    OutputFile = [];
    UsedDataFile = fullfile(paths.output, 'LINEAR_DataUsed_runtime.txt');
    IsANS = 0;
    DampRatio = 0.8/100;
    IntegSchem = 'G2';
    Theory = 4;
    ThermalNL = 0;

    [GlobMatr, FinitElemInfo, MateProp] = assemble_static_case(InputFile, OutputFile, UsedDataFile, ...
        IsANS, DampRatio, IntegSchem, ThermalNL, p.Results.UseCache, p.Results.Quiet);

    KuuT = GlobMatr.KuuT;
    KutT = GlobMatr.KutT;
    KtuT = GlobMatr.KtuT;
    KttT = GlobMatr.KttT;
    KufMT = GlobMatr.KufMT;
    KfuMT = GlobMatr.KfuMT;
    KffMT = GlobMatr.KffMT;
    KfzT = GlobMatr.KfzT;
    KzfT = GlobMatr.KzfT;
    KuzT = GlobMatr.KuzT;
    KzuT = GlobMatr.KzuT;
    KzzT = GlobMatr.KzzT;
    KftT = GlobMatr.KftT;
    KztT = GlobMatr.KztT;
    FusT = GlobMatr.FusT;

    FinalDofM = size(KuuT, 1);
    FinalDofMEE = size(KttT, 1);
    layerDofMap = build_active_layer_dof_map(FinitElemInfo, MateProp, FinalDofMEE);
    nPhysicalLayer = layerDofMap.num_physical_layers;
    nActiveMaterialLayer = layerDofMap.num_active_material_layers;
    % Pyroelectric and pyromagnetic terms are assembled layer-locally by
    % SF_GetMatePropMEEP/SF_ElemComptLIN851T5MEEP_V4. No global scaling is
    % valid for nonuniform or partially active layer stacks.

    PhiaMT = zeros(FinalDofMEE, 1);
    MgaT = zeros(FinalDofMEE, 1);

    activeVolt = 0;
    activeMagnetic = 0;
    switch lower(loadCase)
        case 'electro'
            activeVolt = p.Results.Volt;
        case 'magneto'
            activeMagnetic = p.Results.Magnetic;
    end

    PhiaMT = apply_element_boundary_values(PhiaMT, layerDofMap, activeVolt);
    MgaT = apply_element_boundary_values(MgaT, layerDofMap, activeMagnetic);

    FueT = FusT * loadmax;
    FuaT = -KufMT * PhiaMT;
    FumT = -KuzT * MgaT;
    FutT = zeros(FinalDofMEE, 1);

    AA = [KuuT, KutT; KtuT, KttT];
    BB = [FueT + FuaT + FumT; FutT];
    lastwarn('');
    CC = AA \ BB;
    [mechanicalThermalWarning, mechanicalThermalWarningId] = lastwarn();
    assert_finite_solution(CC, 'mechanical-thermal');
    [mechanicalThermalRelativeResidual, mechanicalThermalBackwardError] = ...
        linear_solve_residuals(AA, CC, BB);
    mechanicalThermalRcondEstimate = reciprocal_condition_estimate(AA);
    Qd = CC(1:FinalDofM);
    TQd = restore_mechanical_dof(FinitElemInfo.Node, Qd);
    SensM_T = CC(FinalDofM+1:end);
    SensM_E = nan(FinalDofMEE, 1);
    SensM_M = nan(FinalDofMEE, 1);
    sensorStatus = 'not_requested';
    sensorRelativeResidual = NaN;
    sensorBackwardError = NaN;
    sensorRcondEstimate = NaN;
    sensorWarning = '';
    sensorWarningId = '';

    if p.Results.SolveSensors
        if isempty(KffMT) || isempty(KzzT)
            error('run_meet_static:MissingSensorMatrices', ...
                'SolveSensors=true requires nonempty electric and magnetic matrices.');
        end
        AA_MEE = [KffMT, KfzT; KzfT, KzzT];
        BB_MEE = [-KfuMT * Qd - KftT * SensM_T; -KzuT * Qd - KztT * SensM_T];
        lastwarn('');
        CC_MEE = AA_MEE \ BB_MEE;
        [sensorWarning, sensorWarningId] = lastwarn();
        assert_finite_solution(CC_MEE, 'electric-magnetic sensor');
        [sensorRelativeResidual, sensorBackwardError] = ...
            linear_solve_residuals(AA_MEE, CC_MEE, BB_MEE);
        sensorRcondEstimate = reciprocal_condition_estimate(AA_MEE);
        SensM_E = CC_MEE(1:FinalDofMEE);
        SensM_M = CC_MEE(FinalDofMEE+1:end);
        sensorStatus = 'ok';
    end

    coordinateBlock = FinitElemInfo.Node(:, 2:4);
    targetCenter = (min(coordinateBlock, [], 1) + max(coordinateBlock, [], 1)) / 2;
    centerIdx = find_nearest_node(FinitElemInfo.Node, targetCenter);
    [wCenter, centerProbe] = interpolate_shell_dof_at_point( ...
        FinitElemInfo.Node, FinitElemInfo.Element, TQd, targetCenter, 3, 5);
    thetaLayers = average_by_physical_layer(SensM_T, layerDofMap);
    electricLayers = average_by_physical_layer(SensM_E, layerDofMap);
    magneticLayers = average_by_physical_layer(SensM_M, layerDofMap);
    electricSpan = span_value(electricLayers);
    magneticSpan = span_value(magneticLayers);
    thetaSpan = span_value(thetaLayers);
    magnetoelectricEfficiency = NaN;
    if activeMagnetic ~= 0 && ~isnan(electricSpan)
        magnetoelectricEfficiency = electricSpan / (2 * abs(activeMagnetic));
    end

    result = struct();
    result.loadCase = lower(loadCase);
    result.inputFile = caseFile;
    result.wCenter_m = wCenter;
    result.wCenter_mm = wCenter * 1000;
    result.theta_layers = thetaLayers;
    result.theta_mean_K = mean(thetaLayers, 'omitnan');
    result.theta_min_K = min(thetaLayers, [], 'omitnan');
    result.theta_max_K = max(thetaLayers, [], 'omitnan');
    result.theta_span_K = thetaSpan;
    result.electric_layers = electricLayers;
    result.magnetic_layers = magneticLayers;
    result.electric_span = electricSpan;
    result.magnetic_span = magneticSpan;
    result.magnetoelectric_efficiency = magnetoelectricEfficiency;
    result.loadScale = loadmax;
    result.volt = activeVolt;
    result.magnetic = activeMagnetic;
    result.nLayer = nPhysicalLayer;
    result.nPhysicalLayer = nPhysicalLayer;
    result.nActiveMaterialLayer = nActiveMaterialLayer;
    result.active_layer_dof_count = FinalDofMEE;
    result.active_layer_dof_map = layerDofMap;
    result.correct_pyro_assembly = true;
    result.pyro_assembly_mode = 'layer_local';
    result.solver_revision = 'layer_local_pyro_v3';
    result.solve_status = 'ok';
    result.sensor_status = sensorStatus;
    result.coupling_sequence = 'simultaneous_u_T_then_simultaneous_phi_psi';
    result.mechanical_thermal_relative_residual = mechanicalThermalRelativeResidual;
    result.mechanical_thermal_backward_error = mechanicalThermalBackwardError;
    result.mechanical_thermal_rcond_estimate = mechanicalThermalRcondEstimate;
    result.mechanical_thermal_warning = mechanicalThermalWarning;
    result.mechanical_thermal_warning_id = mechanicalThermalWarningId;
    result.sensor_relative_residual = sensorRelativeResidual;
    result.sensor_backward_error = sensorBackwardError;
    result.sensor_rcond_estimate = sensorRcondEstimate;
    result.sensor_warning = sensorWarning;
    result.sensor_warning_id = sensorWarningId;
    result.observable_definition = ...
        'max_minus_min_of_physical_layer_average_active_MEE_dofs';
    result.boundary_definition = struct( ...
        'mechanical', 'input_node_flags; bundled CFFF fixes all five shell DOFs on x=0', ...
        'pressure', 'FusT multiplied by LoadScale as uniform transverse surface pressure', ...
        'actuation_potential', ['per element: first retained active-layer DOF=-amplitude, ' ...
            'last=+amplitude; one retained layer uses zero gauge'], ...
        'sensor', ['zero external electric charge and magnetic flux right-hand sides; ' ...
            'layer-local open-circuit algebraic solve'], ...
        'temperature', 'reciprocal algebraic temperature DOF solved in the u-T block', ...
        'probe', centerProbe.method);
    result.centerNodeId = FinitElemInfo.Node(centerIdx, 1);
    result.centerCoord = FinitElemInfo.Node(centerIdx, 2:4);
    result.centerTargetCoord = targetCenter;
    result.centerProbe = centerProbe;
    result.centerProbeMethod = centerProbe.method;
    result.timestamp = datestr(now);

    tag = char(p.Results.OutTag);
    if isempty(tag)
        [~, tag, ~] = fileparts(caseFile);
    end
    outMat = fullfile(paths.output, sprintf('static_%s_%s.mat', lower(loadCase), tag));
    result.output_mat = outMat;
    save(outMat, 'result', 'Qd', 'TQd', 'SensM_T', 'SensM_E', 'SensM_M');
    fprintf('Saved %s\n', outMat);
    fprintf('w_center = %.6f mm\n', result.wCenter_mm);
    fprintf('theta_span = %.6f K\n', result.theta_span_K);
end

function TQd = restore_mechanical_dof(Node, Qd)
    dofPerNode = 5;
    dofFlagStart = 5;
    numNode = size(Node, 1);
    TQd = zeros(numNode * dofPerNode, 1);
    qIndex = 1;
    for nodeIndex = 1:numNode
        for dofIndex = 1:dofPerNode
            fullIndex = (nodeIndex - 1) * dofPerNode + dofIndex;
            if Node(nodeIndex, dofFlagStart + dofIndex - 1) == 0
                TQd(fullIndex) = Qd(qIndex);
                qIndex = qIndex + 1;
            end
        end
    end
    if qIndex - 1 ~= numel(Qd)
        error('run_meet_static:DofRestoreMismatch', ...
            'Restored %d reduced mechanical DOFs, but Qd has %d entries.', qIndex - 1, numel(Qd));
    end
end

function nodeIndex = find_nearest_node(Node, targetCoord)
    diff = Node(:, 2:4) - targetCoord;
    [~, nodeIndex] = min(sum(diff .^ 2, 2));
end

function values = average_by_physical_layer(vec, layerDofMap)
    values = nan(layerDofMap.num_physical_layers, 1);
    if isempty(vec)
        return;
    end
    for i = 1:layerDofMap.num_physical_layers
        layerVals = vec(layerDofMap.physical_layer_by_dof == i);
        layerVals = layerVals(~isnan(layerVals));
        if ~isempty(layerVals)
            values(i) = mean(layerVals);
        end
    end
end

function values = apply_element_boundary_values(values, layerDofMap, amplitude)
    for elementIndex = 1:numel(layerDofMap.first_dof_by_element)
        firstDof = layerDofMap.first_dof_by_element(elementIndex);
        lastDof = layerDofMap.last_dof_by_element(elementIndex);
        if isnan(firstDof)
            continue;
        end
        if firstDof == lastDof
            % One retained layer has no independent top/bottom potential
            % difference in this layer-constant DOF model; zero is its gauge.
            values(firstDof) = 0;
        else
            values(firstDof) = -amplitude;
            values(lastDof) = amplitude;
        end
    end
end

function s = span_value(vec)
    vals = vec(~isnan(vec));
    if isempty(vals)
        s = NaN;
    else
        s = max(vals) - min(vals);
    end
end

function assert_finite_solution(solution, label)
    if any(~isfinite(solution))
        error('run_meet_static:NonFiniteSolution', ...
            '%s solve returned NaN or Inf.', label);
    end
end

function [relativeResidual, backwardError] = linear_solve_residuals(A, x, b)
    residual = A * x - b;
    residualNorm = norm(residual, 2);
    relativeResidual = residualNorm / max(norm(b, 2), eps);
    backwardDenominator = norm(A, 'fro') * norm(x, 2) + norm(b, 2);
    backwardError = residualNorm / max(backwardDenominator, eps);
end

function estimate = reciprocal_condition_estimate(A)
    conditionEstimate = condest(A);
    estimate = 1 / conditionEstimate;
    if isnan(estimate)
        error('run_meet_static:ConditionEstimateFailed', ...
            'condest returned NaN for a solved system.');
    end
end

function [GlobMatr, FinitElemInfo, MateProp] = assemble_static_case(InputFile, OutputFile, UsedDataFile, ...
    IsANS, DampRatio, IntegSchem, ThermalNL, useCache, quietMode)
    persistent lastCacheKey lastGlobMatr lastFinitElemInfo lastMateProp

    info = dir(InputFile);
    if isempty(info)
        error('run_meet_static:NoInput', 'Input file not found: %s', InputFile);
    end
    cacheKey = sprintf('%s|%.12f|%d|%.12g|%s|%d', InputFile, info.datenum, ...
        IsANS, DampRatio, IntegSchem, ThermalNL);

    if useCache && ~isempty(lastCacheKey)
        if strcmp(lastCacheKey, cacheKey)
            GlobMatr = lastGlobMatr;
            FinitElemInfo = lastFinitElemInfo;
            MateProp = lastMateProp;
            fprintf('Reused assembled matrices for %s\n', InputFile);
            return;
        end
    end

    if quietMode
        evalc('[GlobMatr, FinitElemInfo, MateProp] = Main_FOSDLIN851T5MEET_V4(InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);');
    else
        [GlobMatr, FinitElemInfo, MateProp] = Main_FOSDLIN851T5MEET_V4( ...
            InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);
    end

    if useCache
        lastCacheKey = cacheKey;
        lastGlobMatr = GlobMatr;
        lastFinitElemInfo = FinitElemInfo;
        lastMateProp = MateProp;
    end
end
