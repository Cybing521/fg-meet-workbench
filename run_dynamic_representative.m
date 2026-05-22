%% run_dynamic_representative
% Representative Newmark dynamic response for the FG-MEET CFFF plate.
%
% Default case:
%   U / Vf0=0.6 / 10x10 / 10 layers / Case A mechanical step load.
%
% The 10x10 case is the default pilot because it finishes quickly enough for
% interactive reporting. Use FG_DYNAMIC_CASE to point at a 30x30 input when
% running the full-size Newmark calculation as a longer job.
%
% Optional environment overrides:
%   FG_DYNAMIC_CASE        input case file, default U/Vf0=0.6
%   FG_DYNAMIC_LOAD_CASE   elastic | electro | magneto, default elastic
%   FG_DYNAMIC_LOAD_SCALE  mechanical load scale, default -15000
%   FG_DYNAMIC_VOLT        electric potential, default 300
%   FG_DYNAMIC_MAGNETIC    magnetic potential, default 200
%   FG_DYNAMIC_DT          Newmark time step, default 2e-4
%   FG_DYNAMIC_TTOTAL      total time, default 2e-2
%   FG_DYNAMIC_TAG         output tag, default dynamic_U_Vf06_elastic

clear; clc;
paths = setup_paths();

caseFile = getenv('FG_DYNAMIC_CASE');
if isempty(caseFile)
    caseFile = fullfile(paths.meet_elastic, 'InputFile', 'Thermal_CFFFplate_0.6Vf-10x10-10layer.txt');
else
    caseFile = resolve_case_path(caseFile, paths.workbench);
end
if ~isfile(caseFile)
    error('run_dynamic_representative:NoInput', 'Input file not found: %s', caseFile);
end

loadCase = lower(char(getenv('FG_DYNAMIC_LOAD_CASE')));
if isempty(loadCase)
    loadCase = 'elastic';
end
if ~any(strcmp(loadCase, {'elastic', 'electro', 'magneto'}))
    error('run_dynamic_representative:BadLoadCase', ...
        'FG_DYNAMIC_LOAD_CASE must be elastic, electro, or magneto.');
end

loadScale = env_number('FG_DYNAMIC_LOAD_SCALE', -15000);
volt = env_number('FG_DYNAMIC_VOLT', 300);
magnetic = env_number('FG_DYNAMIC_MAGNETIC', 200);
dt = env_number('FG_DYNAMIC_DT', 2e-4);
tTotal = env_number('FG_DYNAMIC_TTOTAL', 2e-2);
tag = char(getenv('FG_DYNAMIC_TAG'));
if isempty(tag)
    tag = sprintf('dynamic_U_Vf06_%s_10x10', loadCase);
end
tag = sanitize_tag(tag);

fprintf('Dynamic representative case: %s\n', caseFile);
fprintf('Load case: %s, dt = %.6g s, total = %.6g s\n', loadCase, dt, tTotal);

oldDir = pwd;
cleanup = onCleanup(@() cd(oldDir)); %#ok<NASGU>
cd(paths.meet_elastic);

InputFile = caseFile;
OutputFile = [];
UsedDataFile = fullfile(paths.output, sprintf('%s_linear_used_data.txt', tag));
IsANS = 0;
DampRatio = 0.8 / 100;
IntegSchem = 'G2';
ThermalNL = 0;

[GlobMatr, FinitElemInfo] = Main_FOSDLIN851T5MEET_V4(InputFile, ...
    OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);

nLayer = count_material_layers(caseFile);
if nLayer < 1
    nLayer = 10;
end

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
FusT = GlobMatr.FusT;

finalDofM = size(KuuT, 1);
finalDofMEE = size(KttT, 1);

activeLoad = 0;
activeVolt = 0;
activeMagnetic = 0;
switch loadCase
    case 'elastic'
        activeLoad = loadScale;
    case 'electro'
        activeVolt = volt;
    case 'magneto'
        activeMagnetic = magnetic;
end

PhiaMT = zeros(finalDofMEE, 1);
MgaT = zeros(finalDofMEE, 1);
PhiaMT(nLayer:nLayer:finalDofMEE) = activeVolt;
PhiaMT(1:nLayer:finalDofMEE) = -activeVolt;
MgaT(nLayer:nLayer:finalDofMEE) = activeMagnetic;
MgaT(1:nLayer:finalDofMEE) = -activeMagnetic;

FueT = FusT * activeLoad;
FuaT = -KufMT * PhiaMT;
FumT = -KuzT * MgaT;
F_nmk = FueT + FuaT + FumT;

DelT = zeros(finalDofMEE, 1);
FutT = zeros(finalDofMEE, 1);
AA = [KuuT, KutT; KtuT, KttT];
BB = [F_nmk; FutT];
CC = AA \ BB;
QdStatic = CC(1:finalDofM);
SensTStatic = CC(finalDofM + 1:end);

[centerNodeIndex, centerNodeId, centerCoord] = find_nearest_node(FinitElemInfo.Node, [0.15, 0.15, 0.0]);
centerReducedDof = find_reduced_mechanical_dof(FinitElemInfo.Node, centerNodeIndex, 3);
staticCenterMm = QdStatic(centerReducedDof) * 1000;

Qd = zeros(finalDofM, 1);
Qv = zeros(finalDofM, 1);
Qa = zeros(finalDofM, 1);
PhiaM = zeros(finalDofMEE, 1);
PhisM = zeros(finalDofMEE, 1);
Mga = zeros(finalDofMEE, 1);
Mgs = zeros(finalDofMEE, 1);
QFdva = struct('Qd', Qd, 'Qv', Qv, 'Qa', Qa, ...
    'PhiaM', PhiaM, 'PhisM', PhisM, 'Mga', Mga, 'Mgs', Mgs);

timePara = [0, dt, tTotal];
positionMEE = 1:finalDofMEE;
isDamp = 0;

XY_Value = SF_NewmarkRefinedMEET(GlobMatr, KuuT, F_nmk, ...
    timePara, centerReducedDof, positionMEE, DelT, QFdva, isDamp);

timeS = XY_Value.X_Time;
wCenterMm = 1000 * XY_Value.Y_Disp(:, 1);
thetaLayerTime = average_layers_over_time(XY_Value.Y_SensM_T, nLayer);
thetaSpanK = max(thetaLayerTime, [], 2) - min(thetaLayerTime, [], 2);

[peakAbsMm, peakIdx] = max(abs(wCenterMm));
peakMm = wCenterMm(peakIdx);
peakTimeS = timeS(peakIdx);
finalMm = wCenterMm(end);
overshootRatio = peakAbsMm / max(abs(staticCenterMm), eps);
thetaStaticLayers = average_by_layer(SensTStatic, nLayer);

[freqHz, freqStatus] = estimate_modes(GlobMatr.KuuT, GlobMatr.MuuT, 6);

outCsv = fullfile(paths.output, sprintf('%s_timeseries.csv', tag));
outSummary = fullfile(paths.output, sprintf('%s_summary.csv', tag));
outMat = fullfile(paths.output, sprintf('%s.mat', tag));

T = table(timeS, wCenterMm, thetaSpanK, ...
    'VariableNames', {'time_s', 'w_center_mm', 'theta_span_K'});
for i = 1:nLayer
    T.(sprintf('theta_layer_%02d_K', i)) = thetaLayerTime(:, i);
end
writetable(T, outCsv);

summary = table(string(tag), string(caseFile), string(loadCase), activeLoad, ...
    activeVolt, activeMagnetic, dt, tTotal, height(T), centerNodeId, ...
    centerCoord(1), centerCoord(2), centerCoord(3), centerReducedDof, ...
    staticCenterMm, finalMm, peakMm, peakAbsMm, peakTimeS, overshootRatio, ...
    min(thetaSpanK), max(thetaSpanK), string(freqStatus), ...
    'VariableNames', {'tag', 'case_file', 'load_case', 'load_scale', ...
    'volt', 'magnetic', 'dt_s', 'total_s', 'steps', 'center_node_id', ...
    'center_x_m', 'center_y_m', 'center_z_m', 'center_reduced_dof', ...
    'static_center_mm', 'final_center_mm', 'peak_center_mm', ...
    'peak_abs_center_mm', 'peak_time_s', 'overshoot_ratio', ...
    'theta_span_min_K', 'theta_span_max_K', 'frequency_status'});
for i = 1:numel(freqHz)
    summary.(sprintf('freq_%02d_Hz', i)) = freqHz(i);
end
writetable(summary, outSummary);

if env_flag('FG_DYNAMIC_SAVE_MATRICES', false)
    save(outMat, 'XY_Value', 'summary', 'T', 'thetaLayerTime', ...
        'thetaStaticLayers', 'freqHz', 'GlobMatr', 'FinitElemInfo', '-v7.3');
else
    save(outMat, 'XY_Value', 'summary', 'T', 'thetaLayerTime', ...
        'thetaStaticLayers', 'freqHz', 'FinitElemInfo', '-v7.3');
end

fprintf('\nWrote %s\n', outCsv);
fprintf('Wrote %s\n', outSummary);
fprintf('Wrote %s\n', outMat);
disp(summary(:, {'tag', 'load_case', 'static_center_mm', 'peak_center_mm', ...
    'peak_time_s', 'overshoot_ratio', 'theta_span_max_K'}));

function value = env_number(name, defaultValue)
    raw = getenv(name);
    if isempty(raw)
        value = defaultValue;
        return;
    end
    value = str2double(raw);
    if isnan(value)
        error('run_dynamic_representative:BadEnv', ...
            '%s must be numeric, got: %s', name, raw);
    end
end

function value = env_flag(name, defaultValue)
    raw = lower(strtrim(char(getenv(name))));
    if isempty(raw)
        value = defaultValue;
    else
        value = any(strcmp(raw, {'1', 'true', 'yes', 'on'}));
    end
end

function caseFile = resolve_case_path(inputFile, workbench)
    inputFile = char(inputFile);
    if ~isempty(regexp(inputFile, '^[A-Za-z]:[\\/]|^[/\\]', 'once'))
        caseFile = inputFile;
    else
        caseFile = fullfile(workbench, inputFile);
    end
    if ~isfile(caseFile) && isfile(inputFile)
        caseFile = inputFile;
    end
end

function tag = sanitize_tag(raw)
    tag = regexprep(raw, '[^A-Za-z0-9_]+', '_');
end

function nLayer = count_material_layers(caseFile)
    nLayer = 0;
    raw = fileread(caseFile);
    i0 = strfind(raw, 'MATERIAL START');
    i1 = strfind(raw, 'MATERIAL END');
    if isempty(i0) || isempty(i1)
        return;
    end
    block = raw(i0(1) + length('MATERIAL START'):i1(1) - 1);
    lines = splitlines(block);
    for i = 1:numel(lines)
        if ~isempty(regexp(strtrim(lines{i}), '^\d', 'once'))
            nLayer = nLayer + 1;
        end
    end
end

function [nodeIndex, nodeId, coord] = find_nearest_node(Node, targetCoord)
    diff = Node(:, 2:4) - targetCoord;
    [~, nodeIndex] = min(sum(diff .^ 2, 2));
    nodeId = Node(nodeIndex, 1);
    coord = Node(nodeIndex, 2:4);
end

function reducedDof = find_reduced_mechanical_dof(Node, nodeIndex, localDof)
    dofPerNode = 5;
    dofFlagStart = 5;
    reducedDof = 0;
    for ni = 1:nodeIndex
        for di = 1:dofPerNode
            if Node(ni, dofFlagStart + di - 1) == 0
                reducedDof = reducedDof + 1;
            end
            if ni == nodeIndex && di == localDof
                if Node(ni, dofFlagStart + di - 1) ~= 0
                    error('run_dynamic_representative:ConstrainedCenter', ...
                        'Requested center DOF is constrained.');
                end
                return;
            end
        end
    end
end

function layerTime = average_layers_over_time(sensorTime, nLayer)
    layerTime = nan(size(sensorTime, 1), nLayer);
    for i = 1:nLayer
        layerTime(:, i) = mean(sensorTime(:, i:nLayer:end), 2);
    end
end

function values = average_by_layer(vec, nLayer)
    values = nan(nLayer, 1);
    for i = 1:nLayer
        values(i) = mean(vec(i:nLayer:end));
    end
end

function [freqHz, status] = estimate_modes(K, M, nModes)
    freqHz = nan(1, nModes);
    status = "not_run";
    try
        opts = struct();
        opts.disp = 0;
        opts.isreal = true;
        [~, D] = eigs(K, M, nModes, 'smallestabs', opts);
        vals = sort(real(diag(D)), 'ascend');
        vals = vals(vals > 0);
        n = min(nModes, numel(vals));
        freqHz(1:n) = sqrt(vals(1:n)) / (2 * pi);
        status = "ok";
    catch ME
        status = "failed: " + string(ME.message);
    end
end
