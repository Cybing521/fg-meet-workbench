%% run_dynamic_modal_sensitivity_30x30
% Modal-order sensitivity for the 30x30 FG-MEET CFFF plate.
%
% Default case:
%   U / Vf0=0.6 / 30x30 / 10 layers / Case A mechanical step load.
%
% The script assembles the 30x30 model once, solves the first max(N) modes
% once, then evaluates multiple retained-mode counts such as 4/6/8/12/16.
% This gives a convergence check for the modal-superposition workflow without
% repeating the expensive matrix assembly.
%
% Optional environment overrides:
%   FG_MODAL_SENS_CASE        input case file, default U/Vf0=0.6 30x30
%   FG_MODAL_SENS_LOAD_CASE   elastic | electro | magneto, default elastic
%   FG_MODAL_SENS_LOAD_SCALE  mechanical load scale, default -15000
%   FG_MODAL_SENS_VOLT        electric potential, default 300
%   FG_MODAL_SENS_MAGNETIC    magnetic potential, default 200
%   FG_MODAL_SENS_DT          output time step, default 1e-4
%   FG_MODAL_SENS_TTOTAL      total time, default 4e-2
%   FG_MODAL_SENS_MODES       comma list, default 4,6,8,12,16
%   FG_MODAL_SENS_DAMPING     modal damping ratio, default 0.008
%   FG_MODAL_SENS_DAMPING_LIST optional comma list for damping sensitivity
%   FG_MODAL_SENS_TAG         output tag, default dynamic_modal_30x30_U_Vf06_elastic_sensitivity

clear; clc;
totalTimer = tic;
paths = setup_paths();

caseFile = env_text({'FG_MODAL_SENS_CASE', 'FG_MODAL_CASE'}, '');
if isempty(caseFile)
    caseFile = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
else
    caseFile = resolve_case_path(caseFile, paths.workbench);
end
if ~isfile(caseFile)
    error('run_dynamic_modal_sensitivity_30x30:NoInput', ...
        'Input file not found: %s', caseFile);
end

loadCase = lower(env_text({'FG_MODAL_SENS_LOAD_CASE', 'FG_MODAL_LOAD_CASE'}, 'elastic'));
if ~any(strcmp(loadCase, {'elastic', 'electro', 'magneto'}))
    error('run_dynamic_modal_sensitivity_30x30:BadLoadCase', ...
        'FG_MODAL_SENS_LOAD_CASE must be elastic, electro, or magneto.');
end

loadScale = env_number({'FG_MODAL_SENS_LOAD_SCALE', 'FG_MODAL_LOAD_SCALE'}, -15000);
volt = env_number({'FG_MODAL_SENS_VOLT', 'FG_MODAL_VOLT'}, 300);
magnetic = env_number({'FG_MODAL_SENS_MAGNETIC', 'FG_MODAL_MAGNETIC'}, 200);
dt = env_number({'FG_MODAL_SENS_DT', 'FG_MODAL_DT'}, 1e-4);
tTotal = env_number({'FG_MODAL_SENS_TTOTAL', 'FG_MODAL_TTOTAL'}, 4e-2);
baseDampingRatio = env_number({'FG_MODAL_SENS_DAMPING', 'FG_MODAL_DAMPING'}, 0.8 / 100);
dampingRatios = env_number_list({'FG_MODAL_SENS_DAMPING_LIST', 'FG_MODAL_DAMPING_LIST'}, baseDampingRatio);
modeCounts = env_mode_list({'FG_MODAL_SENS_MODES', 'FG_MODAL_NMODES'}, [4, 6, 8, 12, 16]);
tag = env_text({'FG_MODAL_SENS_TAG', 'FG_MODAL_TAG'}, '');
if isempty(tag)
    tag = sprintf('dynamic_modal_30x30_U_Vf06_%s_sensitivity', loadCase);
end
tag = sanitize_tag(tag);

maxModes = max(modeCounts);
fprintf('30x30 modal sensitivity case: %s\n', caseFile);
fprintf('Load case: %s, modes = %s, damping = %s, dt = %.6g s, total = %.6g s\n', ...
    loadCase, sprintf('%d ', modeCounts), sprintf('%.4g ', dampingRatios), dt, tTotal);

oldDir = pwd;
cleanup = onCleanup(@() cd(oldDir)); %#ok<NASGU>
cd(paths.meet_elastic);

InputFile = caseFile;
OutputFile = [];
UsedDataFile = fullfile(paths.output, sprintf('%s_linear_used_data.txt', tag));
IsANS = 0;
DampRatio = baseDampingRatio;
IntegSchem = 'G2';
ThermalNL = 0;

assemblyTimer = tic;
assemblyLog = evalc(['[GlobMatr, FinitElemInfo] = Main_FOSDLIN851T5MEET_V4(' ...
    'InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);']);
assemblyRuntimeS = toc(assemblyTimer);
write_text(fullfile(paths.output, sprintf('%s_assembly.log', tag)), assemblyLog);

nLayer = count_material_layers(caseFile);
if nLayer < 1
    nLayer = 10;
end

KuuT = GlobMatr.KuuT;
MuuT = GlobMatr.MuuT;
KutT = GlobMatr.KutT;
KtuT = GlobMatr.KtuT;
KttT = GlobMatr.KttT;
KufMT = GlobMatr.KufMT;
KuzT = GlobMatr.KuzT;
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

Fstep = FusT * activeLoad - KufMT * PhiaMT - KuzT * MgaT;

staticTimer = tic;
fprintf('Solving coupled and mechanical static references...\n');
CC = [KuuT, KutT; KtuT, KttT] \ [Fstep; zeros(finalDofMEE, 1)];
QdCoupledStatic = CC(1:finalDofM);
QdMechanicalStatic = KuuT \ Fstep;
staticRuntimeS = toc(staticTimer);

[centerNodeIndex, centerNodeId, centerCoord] = find_nearest_node(FinitElemInfo.Node, [0.15, 0.15, 0.0]);
centerReducedDof = find_reduced_mechanical_dof(FinitElemInfo.Node, centerNodeIndex, 3);
coupledStaticCenterMm = QdCoupledStatic(centerReducedDof) * 1000;
mechanicalStaticCenterMm = QdMechanicalStatic(centerReducedDof) * 1000;

eigsTimer = tic;
fprintf('Solving first %d modes once...\n', maxModes);
[Phi, lambda, eigStatus] = solve_modes(KuuT, MuuT, maxModes);
eigsRuntimeS = toc(eigsTimer);
availableModes = size(Phi, 2);
if availableModes < maxModes
    warning('run_dynamic_modal_sensitivity_30x30:FewerModes', ...
        'Requested %d modes but only kept %d positive finite modes.', maxModes, availableModes);
end
modeCounts = modeCounts(modeCounts <= availableModes);
if isempty(modeCounts)
    error('run_dynamic_modal_sensitivity_30x30:NoModeSet', ...
        'No requested mode count is available after eigen filtering.');
end

omega = sqrt(lambda);
freqHz = omega / (2 * pi);
modalForce = Phi' * Fstep;
etaStatic = modalForce ./ (omega .^ 2);
centerShape = Phi(centerReducedDof, :);
centerContributionMm = 1000 * centerShape(:) .* etaStatic(:);
cumulativeCenterMm = cumsum(centerContributionMm);
cumulativeCaptureRatio = cumulativeCenterMm / mechanicalStaticCenterMm;

try
    thermalSolver = decomposition(KttT, 'auto');
    hasThermalSolver = true;
catch ME
    warning('run_dynamic_modal_sensitivity_30x30:ThermalDecomp', ...
        'Thermal decomposition failed, falling back to backslash: %s', ME.message);
    thermalSolver = [];
    hasThermalSolver = false;
end

timeS = (0:dt:tTotal)';
nSteps = numel(timeS);
nSets = numel(modeCounts) * numel(dampingRatios);
timeseries = table(timeS, 'VariableNames', {'time_s'});

runModeCounts = nan(nSets, 1);
runDampingRatios = nan(nSets, 1);
modalStaticCenterMm = nan(nSets, 1);
modalCaptureRatio = nan(nSets, 1);
finalMm = nan(nSets, 1);
peakMm = nan(nSets, 1);
peakAbsMm = nan(nSets, 1);
peakTimeS = nan(nSets, 1);
overshootRatio = nan(nSets, 1);
thetaSpanMinK = nan(nSets, 1);
thetaSpanMaxK = nan(nSets, 1);
freqLastHz = nan(nSets, 1);
recoveryRuntimeS = nan(nSets, 1);

sensitivityTimer = tic;
si = 0;
for di = 1:numel(dampingRatios)
    dampingRatio = dampingRatios(di);
    for mi = 1:numel(modeCounts)
    si = si + 1;
    nModes = modeCounts(mi);
    runModeCounts(si) = nModes;
    runDampingRatios(si) = dampingRatio;
    fprintf('Evaluating %d retained modes at damping %.4g...\n', nModes, dampingRatio);
    setTimer = tic;

    PhiN = Phi(:, 1:nModes);
    omegaN = omega(1:nModes);
    modalForceN = modalForce(1:nModes);
    centerShapeN = centerShape(1:nModes);
    etaStaticN = etaStatic(1:nModes);

    modalStaticCenterMm(si) = 1000 * (centerShapeN * etaStaticN);
    modalCaptureRatio(si) = modalStaticCenterMm(si) / mechanicalStaticCenterMm;

    eta = modal_step_response(timeS, omegaN, modalForceN, dampingRatio);
    wCenterMm = 1000 * (centerShapeN * eta)';

    qTime = PhiN * eta;
    thermalRhs = -KtuT * qTime;
    if hasThermalSolver
        thetaTime = thermalSolver \ thermalRhs;
    else
        thetaTime = KttT \ thermalRhs;
    end
    thetaLayerTime = average_layers_over_time(thetaTime', nLayer);
    thetaSpanK = max(thetaLayerTime, [], 2) - min(thetaLayerTime, [], 2);

    [peakAbsMm(si), peakIdx] = max(abs(wCenterMm));
    peakMm(si) = wCenterMm(peakIdx);
    peakTimeS(si) = timeS(peakIdx);
    finalMm(si) = wCenterMm(end);
    overshootRatio(si) = peakAbsMm(si) / max(abs(mechanicalStaticCenterMm), eps);
    thetaSpanMinK(si) = min(thetaSpanK);
    thetaSpanMaxK(si) = max(thetaSpanK);
    freqLastHz(si) = freqHz(nModes);
    recoveryRuntimeS(si) = toc(setTimer);

    if isscalar(dampingRatios)
        label = sprintf('%02d_modes', nModes);
    else
        label = sprintf('zeta_%04d_%02d_modes', round(dampingRatio * 10000), nModes);
    end
    timeseries.(sprintf('w_center_%s_mm', label)) = wCenterMm;
    timeseries.(sprintf('theta_span_%s_K', label)) = thetaSpanK;
    for layerIndex = 1:nLayer
        timeseries.(sprintf('theta_layer_%02d_%s_K', layerIndex, label)) = thetaLayerTime(:, layerIndex);
    end
    end
end
sensitivityRuntimeS = toc(sensitivityTimer);
totalRuntimeS = toc(totalTimer);

freq01Hz = repmat(freqHz(1), nSets, 1);
captureDeltaVsMax = modalCaptureRatio - modalCaptureRatio(end);
peakAbsDeltaVsMaxMm = peakAbsMm - peakAbsMm(end);
peakTimeDeltaVsMaxMs = (peakTimeS - peakTimeS(end)) * 1000;
thetaSpanDeltaVsMaxK = thetaSpanMaxK - thetaSpanMaxK(end);

summary = table( ...
    repmat(string(tag), nSets, 1), repmat(string(caseFile), nSets, 1), ...
    repmat(string(loadCase), nSets, 1), repmat(activeLoad, nSets, 1), ...
    repmat(activeVolt, nSets, 1), repmat(activeMagnetic, nSets, 1), ...
    runModeCounts, repmat(maxModes, nSets, 1), runDampingRatios, ...
    repmat(dt, nSets, 1), repmat(tTotal, nSets, 1), repmat(nSteps, nSets, 1), ...
    repmat(centerNodeId, nSets, 1), repmat(centerCoord(1), nSets, 1), ...
    repmat(centerCoord(2), nSets, 1), repmat(centerCoord(3), nSets, 1), ...
    repmat(centerReducedDof, nSets, 1), repmat(coupledStaticCenterMm, nSets, 1), ...
    repmat(mechanicalStaticCenterMm, nSets, 1), modalStaticCenterMm, ...
    modalCaptureRatio, finalMm, peakMm, peakAbsMm, peakTimeS, ...
    overshootRatio, thetaSpanMinK, thetaSpanMaxK, freq01Hz, freqLastHz, ...
    captureDeltaVsMax, peakAbsDeltaVsMaxMm, peakTimeDeltaVsMaxMs, ...
    thetaSpanDeltaVsMaxK, recoveryRuntimeS, repmat(assemblyRuntimeS, nSets, 1), ...
    repmat(staticRuntimeS, nSets, 1), repmat(eigsRuntimeS, nSets, 1), ...
    repmat(sensitivityRuntimeS, nSets, 1), repmat(totalRuntimeS, nSets, 1), ...
    repmat(string(eigStatus), nSets, 1), ...
    'VariableNames', {'tag', 'case_file', 'load_case', 'load_scale', ...
    'volt', 'magnetic', 'n_modes', 'max_modes_solved', 'damping_ratio', ...
    'dt_s', 'total_s', 'steps', 'center_node_id', 'center_x_m', ...
    'center_y_m', 'center_z_m', 'center_reduced_dof', ...
    'coupled_static_center_mm', 'mechanical_static_center_mm', ...
    'modal_static_center_mm', 'modal_capture_ratio', 'final_center_mm', ...
    'peak_center_mm', 'peak_abs_center_mm', 'peak_time_s', ...
    'overshoot_ratio', 'theta_span_min_K', 'theta_span_max_K', ...
    'freq_01_Hz', 'freq_last_Hz', 'capture_delta_vs_max', ...
    'peak_abs_delta_vs_max_mm', 'peak_time_delta_vs_max_ms', ...
    'theta_span_delta_vs_max_K', 'recovery_runtime_s', 'assembly_runtime_s', ...
    'static_runtime_s', 'eigs_runtime_s', 'sensitivity_runtime_s', ...
    'total_runtime_s', 'eigen_status'});

modes = table((1:availableModes)', freqHz(:), omega(:), modalForce(:), ...
    etaStatic(:), centerShape(:), centerContributionMm(:), ...
    cumulativeCenterMm(:), cumulativeCaptureRatio(:), ...
    'VariableNames', {'mode', 'freq_Hz', 'omega_rad_s', 'modal_force', ...
    'eta_static', 'center_shape', 'center_static_contribution_mm', ...
    'cumulative_center_static_mm', 'cumulative_capture_ratio'});

outCsv = fullfile(paths.output, sprintf('%s_timeseries.csv', tag));
outModes = fullfile(paths.output, sprintf('%s_modes.csv', tag));
outSummary = fullfile(paths.output, sprintf('%s_summary.csv', tag));
outMat = fullfile(paths.output, sprintf('%s.mat', tag));

writetable(timeseries, outCsv);
writetable(modes, outModes);
writetable(summary, outSummary);
save(outMat, 'summary', 'modes', 'timeseries', 'modeCounts', 'dampingRatios', 'freqHz', ...
    'omega', 'modalForce', 'etaStatic', 'centerShape', 'centerReducedDof', ...
    'centerNodeId', 'centerCoord', '-v7.3');

fprintf('\nWrote %s\n', outCsv);
fprintf('Wrote %s\n', outModes);
fprintf('Wrote %s\n', outSummary);
fprintf('Wrote %s\n', outMat);
disp(summary(:, {'n_modes', 'modal_capture_ratio', 'peak_center_mm', ...
    'damping_ratio', 'peak_time_s', 'overshoot_ratio', 'theta_span_max_K', ...
    'peak_abs_delta_vs_max_mm'}));

function value = env_text(names, defaultValue)
    if ischar(names)
        names = {names};
    end
    for i = 1:numel(names)
        raw = getenv(names{i});
        if ~isempty(raw)
            value = char(raw);
            return;
        end
    end
    value = defaultValue;
end

function value = env_number(names, defaultValue)
    raw = env_text(names, '');
    if isempty(raw)
        value = defaultValue;
        return;
    end
    value = str2double(raw);
    if isnan(value)
        error('run_dynamic_modal_sensitivity_30x30:BadEnv', ...
            '%s must be numeric, got: %s', strjoin(names, '/'), raw);
    end
end

function values = env_number_list(names, defaultValues)
    raw = env_text(names, '');
    if isempty(raw)
        values = defaultValues;
        return;
    end
    parts = regexp(raw, '[,;\s]+', 'split');
    parts = parts(~cellfun('isempty', parts));
    values = zeros(1, numel(parts));
    for i = 1:numel(parts)
        values(i) = str2double(parts{i});
        if isnan(values(i))
            error('run_dynamic_modal_sensitivity_30x30:BadNumberList', ...
                'Expected numeric list, got: %s', raw);
        end
    end
    values = unique(values, 'stable');
end

function modes = env_mode_list(names, defaultModes)
    raw = env_text(names, '');
    if isempty(raw)
        modes = defaultModes;
        return;
    end
    parts = regexp(raw, '[,;\s]+', 'split');
    parts = parts(~cellfun('isempty', parts));
    modes = zeros(1, numel(parts));
    for i = 1:numel(parts)
        modes(i) = round(str2double(parts{i}));
        if isnan(modes(i)) || modes(i) < 1
            error('run_dynamic_modal_sensitivity_30x30:BadModes', ...
                'Mode counts must be positive integers, got: %s', raw);
        end
    end
    modes = unique(modes, 'stable');
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

function write_text(path, text)
    fid = fopen(path, 'w');
    if fid < 0
        error('run_dynamic_modal_sensitivity_30x30:WriteFailed', ...
            'Cannot write %s', path);
    end
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fwrite(fid, text);
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
                    error('run_dynamic_modal_sensitivity_30x30:ConstrainedCenter', ...
                        'Requested center DOF is constrained.');
                end
                return;
            end
        end
    end
end

function [Phi, lambda, status] = solve_modes(K, M, nModes)
    status = "ok";
    opts = struct();
    opts.disp = 0;
    opts.isreal = true;
    try
        [Phi, D] = eigs(K, M, nModes, 'smallestabs', opts);
    catch ME
        status = "fallback_smallestreal: " + string(ME.message);
        [Phi, D] = eigs(K, M, nModes, 'smallestreal', opts);
    end
    lambda = real(diag(D));
    keep = lambda > 0 & isfinite(lambda);
    Phi = real(Phi(:, keep));
    lambda = lambda(keep);
    [lambda, idx] = sort(lambda, 'ascend');
    Phi = Phi(:, idx);
    for i = 1:size(Phi, 2)
        normM = sqrt(Phi(:, i)' * (M * Phi(:, i)));
        Phi(:, i) = Phi(:, i) / normM;
    end
end

function eta = modal_step_response(timeS, omega, modalForce, dampingRatio)
    nModes = numel(omega);
    eta = zeros(nModes, numel(timeS));
    for i = 1:nModes
        statEta = modalForce(i) / (omega(i)^2);
        zeta = dampingRatio;
        if zeta <= 0
            eta(i, :) = statEta * (1 - cos(omega(i) * timeS'));
        elseif zeta < 1
            wd = omega(i) * sqrt(1 - zeta^2);
            transient = exp(-zeta * omega(i) * timeS') .* ...
                (cos(wd * timeS') + zeta / sqrt(1 - zeta^2) * sin(wd * timeS'));
            eta(i, :) = statEta * (1 - transient);
        else
            eta(i, :) = statEta * (1 - exp(-omega(i) * timeS'));
        end
    end
end

function layerTime = average_layers_over_time(sensorTime, nLayer)
    layerTime = nan(size(sensorTime, 1), nLayer);
    for i = 1:nLayer
        layerTime(:, i) = mean(sensorTime(:, i:nLayer:end), 2);
    end
end
