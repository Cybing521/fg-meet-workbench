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

    [GlobMatr, FinitElemInfo] = assemble_static_case(InputFile, OutputFile, UsedDataFile, ...
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
    nLayer = count_material_layers(caseFile);
    if nLayer < 1
        nLayer = 10;
    end

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

    PhiaMT(nLayer:nLayer:FinalDofMEE) = activeVolt;
    PhiaMT(1:nLayer:FinalDofMEE) = -activeVolt;
    MgaT(nLayer:nLayer:FinalDofMEE) = activeMagnetic;
    MgaT(1:nLayer:FinalDofMEE) = -activeMagnetic;

    FueT = FusT * loadmax;
    FuaT = -KufMT * PhiaMT;
    FumT = -KuzT * MgaT;
    FutT = zeros(FinalDofMEE, 1);

    AA = [KuuT, KutT; KtuT, KttT];
    BB = [FueT + FuaT + FumT; FutT];
    CC = AA \ BB;
    Qd = CC(1:FinalDofM);
    TQd = restore_mechanical_dof(FinitElemInfo.Node, Qd);
    SensM_T = CC(FinalDofM+1:end);
    SensM_E = nan(FinalDofMEE, 1);
    SensM_M = nan(FinalDofMEE, 1);

    if p.Results.SolveSensors
        try
            if ~isempty(KffMT) && ~isempty(KzzT)
                AA_MEE = [KffMT, KfzT; KzfT, KzzT];
                BB_MEE = [-KfuMT * Qd - KftT * SensM_T; -KzuT * Qd - KztT * SensM_T];
                CC_MEE = AA_MEE \ BB_MEE;
                SensM_E = CC_MEE(1:FinalDofMEE);
                SensM_M = CC_MEE(FinalDofMEE+1:end);
            end
        catch ME
            warning('run_meet_static:SensorSolveFailed', ...
                'Electric/magnetic sensor solve failed: %s', ME.message);
        end
    end

    centerIdx = find_nearest_node(FinitElemInfo.Node, [0.15, 0.15, 0.0]);
    wCenter = TQd(5 * (centerIdx - 1) + 3);
    thetaLayers = average_by_layer(SensM_T, nLayer);
    electricLayers = average_by_layer(SensM_E, nLayer);
    magneticLayers = average_by_layer(SensM_M, nLayer);
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
    result.theta_mean_K = mean(thetaLayers);
    result.theta_min_K = min(thetaLayers);
    result.theta_max_K = max(thetaLayers);
    result.theta_span_K = thetaSpan;
    result.electric_layers = electricLayers;
    result.magnetic_layers = magneticLayers;
    result.electric_span = electricSpan;
    result.magnetic_span = magneticSpan;
    result.magnetoelectric_efficiency = magnetoelectricEfficiency;
    result.loadScale = loadmax;
    result.volt = activeVolt;
    result.magnetic = activeMagnetic;
    result.nLayer = nLayer;
    result.centerNodeId = FinitElemInfo.Node(centerIdx, 1);
    result.centerCoord = FinitElemInfo.Node(centerIdx, 2:4);
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

function nLayer = count_material_layers(caseFile)
    nLayer = 0;
    raw = fileread(caseFile);
    startTok = 'MATERIAL START';
    endTok = 'MATERIAL END';
    i0 = strfind(raw, startTok);
    i1 = strfind(raw, endTok);
    if isempty(i0) || isempty(i1)
        return;
    end
    block = raw(i0(1) + length(startTok):i1(1) - 1);
    lines = splitlines(block);
    for i = 1:numel(lines)
        t = strtrim(lines{i});
        if ~isempty(regexp(t, '^\d', 'once'))
            nLayer = nLayer + 1;
        end
    end
end

function values = average_by_layer(vec, nLayer)
    values = nan(nLayer, 1);
    if isempty(vec) || nLayer < 1
        return;
    end
    for i = 1:nLayer
        layerVals = vec(i:nLayer:end);
        layerVals = layerVals(~isnan(layerVals));
        if ~isempty(layerVals)
            values(i) = mean(layerVals);
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

function [GlobMatr, FinitElemInfo] = assemble_static_case(InputFile, OutputFile, UsedDataFile, ...
    IsANS, DampRatio, IntegSchem, ThermalNL, useCache, quietMode)
    persistent lastCacheKey lastGlobMatr lastFinitElemInfo

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
            fprintf('Reused assembled matrices for %s\n', InputFile);
            return;
        end
    end

    if quietMode
        evalc('[GlobMatr, FinitElemInfo, ~] = Main_FOSDLIN851T5MEET_V4(InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);');
    else
        [GlobMatr, FinitElemInfo, ~] = Main_FOSDLIN851T5MEET_V4( ...
            InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);
    end

    if useCache
        lastCacheKey = cacheKey;
        lastGlobMatr = GlobMatr;
        lastFinitElemInfo = FinitElemInfo;
    end
end
