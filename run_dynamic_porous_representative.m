%% run_dynamic_porous_representative
% Dynamic response for porous FG-MEE CFFF plate (Phase 6.4).
%
% Default case: U / Vf0=0.5 / e0=0.2 / Even / 10x10 / Case A step load.
%
% Environment overrides:
%   FG_POROUS_DYN_FG       FG mode (U or X), default U
%   FG_POROUS_DYN_VF       volume fraction, default 0.5
%   FG_POROUS_DYN_E0       porosity parameter, default 0.2
%   FG_POROUS_DYN_PMODE    porosity mode (1=Even,2=Uneven,3=LogUneven), default 1
%   FG_POROUS_DYN_GRID     10x10 or 30x30, default 10x10
%   FG_POROUS_DYN_DT       time step, default 1e-4
%   FG_POROUS_DYN_TTOTAL   total time, default 4e-2

clear; clc;
paths = setup_paths();

%% Parse parameters
fgMode = getenv('FG_POROUS_DYN_FG');
if isempty(fgMode), fgMode = 'U'; end

vf0 = env_number('FG_POROUS_DYN_VF', 0.5);
e0 = env_number('FG_POROUS_DYN_E0', 0.2);
poroMode = env_number('FG_POROUS_DYN_PMODE', 1);
gridTag = char(getenv('FG_POROUS_DYN_GRID'));
if isempty(gridTag), gridTag = '10x10'; end
dt = env_number('FG_POROUS_DYN_DT', 1e-4);
tTotal = env_number('FG_POROUS_DYN_TTOTAL', 4e-2);
loadScale = -15000;

poroNames = {'Even', 'Uneven', 'LogUneven'};
poroName = poroNames{poroMode};
vfTag = sprintf('Vf%02d', round(vf0 * 100));
e0Tag = sprintf('e%02d', round(e0 * 100));
tag = sprintf('dynamic_porous_%s_%s_%s_%s', fgMode, vfTag, e0Tag, poroName);

%% Locate input file
caseName = sprintf('Porous_CFFF_%s_Vf%.1f_%s_%s-%s-10layer.txt', ...
    fgMode, vf0, e0Tag, poroName, gridTag);
caseFile = fullfile(paths.workbench, 'cases', 'porous', caseName);

if strcmpi(gridTag, '10x10') && ~isfile(caseFile)
    generator = fullfile(paths.tools, 'generate_porous_dynamic_case.py');
    status = system(sprintf('python "%s" %s %.12g %.12g %s', ...
        generator, fgMode, vf0, e0, poroName));
    if status ~= 0
        error('run_dynamic_porous:GenerateFailed', ...
            'Cannot generate 10x10 porous dynamic case.');
    end
end

% If the requested grid doesn't exist, fall back to the other available grid.
if ~isfile(caseFile)
    altGrid = '30x30';
    if strcmpi(gridTag, '30x30')
        altGrid = '10x10';
    end
    altName = sprintf('Porous_CFFF_%s_Vf%.1f_%s_%s-%s-10layer.txt', ...
        fgMode, vf0, e0Tag, poroName, altGrid);
    altFile = fullfile(paths.workbench, 'cases', 'porous', altName);
    if isfile(altFile)
        caseFile = altFile;
        gridTag = altGrid;
    else
        error('run_dynamic_porous:NoInput', ...
            'Input file not found: %s\nRun generate_porous_cases.py first.', caseFile);
    end
end
tag = sprintf('%s_%s', tag, gridTag);

fprintf('=== Porous Dynamic Representative ===\n');
fprintf('FG=%s, Vf0=%.1f, e0=%.1f, Porosity=%s, Grid=%s\n', ...
    fgMode, vf0, e0, poroName, gridTag);
fprintf('Input: %s\n', caseFile);
fprintf('dt=%.6g s, total=%.6g s\n', dt, tTotal);

%% Assemble global matrices
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
if nLayer < 1, nLayer = 10; end

KuuT = GlobMatr.KuuT;
KutT = GlobMatr.KutT;
KtuT = GlobMatr.KtuT;
KttT = GlobMatr.KttT;
KufMT = GlobMatr.KufMT;
KuzT = GlobMatr.KuzT;
FusT = GlobMatr.FusT;

finalDofM = size(KuuT, 1);
finalDofMEE = size(KttT, 1);

%% Apply loads
PhiaMT = zeros(finalDofMEE, 1);
MgaT = zeros(finalDofMEE, 1);
FueT = FusT * loadScale;
F_nmk = FueT + (-KufMT * PhiaMT) + (-KuzT * MgaT);

%% Static solution for reference
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

fprintf('Static center deflection: %.4f mm\n', staticCenterMm);

%% Newmark time integration
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

fprintf('Running Newmark integration...\n');
tic;
XY_Value = SF_NewmarkRefinedMEET(GlobMatr, KuuT, F_nmk, ...
    timePara, centerReducedDof, positionMEE, DelT, QFdva, isDamp);
elapsed = toc;
fprintf('Newmark done in %.1f s\n', elapsed);

%% Post-process
timeS = XY_Value.X_Time;
wCenterMm = 1000 * XY_Value.Y_Disp(:, 1);
thetaLayerTime = average_layers_over_time(XY_Value.Y_SensM_T, nLayer);
thetaSpanK = max(thetaLayerTime, [], 2) - min(thetaLayerTime, [], 2);

[peakAbsMm, peakIdx] = max(abs(wCenterMm));
peakMm = wCenterMm(peakIdx);
peakTimeS = timeS(peakIdx);
overshootRatio = peakAbsMm / max(abs(staticCenterMm), eps);

[freqHz, freqStatus] = estimate_modes(GlobMatr.KuuT, GlobMatr.MuuT, 6);

%% Save results
outCsv = fullfile(paths.output, sprintf('%s_timeseries.csv', tag));
outSummary = fullfile(paths.output, sprintf('%s_summary.csv', tag));

T = table(timeS, wCenterMm, thetaSpanK, ...
    'VariableNames', {'time_s', 'w_center_mm', 'theta_span_K'});
writetable(T, outCsv);

summary = table(string(tag), string(caseFile), string('elastic'), loadScale, ...
    dt, tTotal, height(T), centerNodeId, staticCenterMm, peakMm, peakAbsMm, ...
    peakTimeS, overshootRatio, max(thetaSpanK), string(freqStatus), ...
    'VariableNames', {'tag','case_file','load_case','load_scale', ...
    'dt_s','total_s','steps','center_node_id','static_center_mm', ...
    'peak_center_mm','peak_abs_center_mm','peak_time_s', ...
    'overshoot_ratio','theta_span_max_K','frequency_status'});
if strcmp(freqStatus, 'ok')
    for fi = 1:min(6, numel(freqHz))
        summary.(sprintf('freq_%02d_Hz', fi)) = freqHz(fi);
    end
end
writetable(summary, outSummary);

fprintf('\n=== Results ===\n');
fprintf('Static center:  %.4f mm\n', staticCenterMm);
fprintf('Peak center:    %.4f mm (t=%.4f ms)\n', peakMm, peakTimeS*1000);
fprintf('Overshoot:      %.3f\n', overshootRatio);
fprintf('Max theta span: %.4f K\n', max(thetaSpanK));
if strcmp(freqStatus, 'ok')
    fprintf('f1 = %.2f Hz\n', freqHz(1));
end
fprintf('\nTimeseries: %s\n', outCsv);
fprintf('Summary:    %s\n', outSummary);

function value = env_number(name, defaultValue)
    raw = getenv(name);
    if isempty(raw)
        value = defaultValue;
        return;
    end
    value = str2double(raw);
    if isnan(value)
        error('run_dynamic_porous:BadEnv', '%s must be numeric, got: %s', name, raw);
    end
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
                    error('run_dynamic_porous:ConstrainedCenter', ...
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
