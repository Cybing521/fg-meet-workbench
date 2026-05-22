%% run_dynamic_modal_30x30
% 30x30 modal superposition dynamic response for the FG-MEET CFFF plate.
%
% Default case:
%   U / Vf0=0.6 / 30x30 / 10 layers / Case A mechanical step load.
%
% This is the follow-up to the full Newmark attempt: keep the 30x30 spatial
% model, compute a small set of mechanical modes, and reconstruct the center
% displacement time history by modal superposition. The thermal layer response
% is recovered after the displacement history with Ktt \ (-Ktu*u).
%
% Optional environment overrides:
%   FG_MODAL_CASE        input case file, default U/Vf0=0.6 30x30
%   FG_MODAL_LOAD_CASE   elastic | electro | magneto, default elastic
%   FG_MODAL_LOAD_SCALE  mechanical load scale, default -15000
%   FG_MODAL_VOLT        electric potential, default 300
%   FG_MODAL_MAGNETIC    magnetic potential, default 200
%   FG_MODAL_DT          output time step, default 1e-4
%   FG_MODAL_TTOTAL      total time, default 4e-2
%   FG_MODAL_NMODES      number of modes, default 12
%   FG_MODAL_DAMPING     modal damping ratio, default 0.008
%   FG_MODAL_TAG         output tag, default dynamic_modal_30x30_U_Vf06_elastic

clear; clc;
paths = setup_paths();

caseFile = getenv('FG_MODAL_CASE');
if isempty(caseFile)
    caseFile = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
else
    caseFile = resolve_case_path(caseFile, paths.workbench);
end
if ~isfile(caseFile)
    error('run_dynamic_modal_30x30:NoInput', 'Input file not found: %s', caseFile);
end

loadCase = lower(char(getenv('FG_MODAL_LOAD_CASE')));
if isempty(loadCase)
    loadCase = 'elastic';
end
if ~any(strcmp(loadCase, {'elastic', 'electro', 'magneto'}))
    error('run_dynamic_modal_30x30:BadLoadCase', ...
        'FG_MODAL_LOAD_CASE must be elastic, electro, or magneto.');
end

loadScale = env_number('FG_MODAL_LOAD_SCALE', -15000);
volt = env_number('FG_MODAL_VOLT', 300);
magnetic = env_number('FG_MODAL_MAGNETIC', 200);
dt = env_number('FG_MODAL_DT', 1e-4);
tTotal = env_number('FG_MODAL_TTOTAL', 4e-2);
nModes = round(env_number('FG_MODAL_NMODES', 12));
dampingRatio = env_number('FG_MODAL_DAMPING', 0.8 / 100);
tag = char(getenv('FG_MODAL_TAG'));
if isempty(tag)
    tag = sprintf('dynamic_modal_30x30_U_Vf06_%s', loadCase);
end
tag = sanitize_tag(tag);

fprintf('30x30 modal dynamic case: %s\n', caseFile);
fprintf('Load case: %s, modes = %d, damping = %.4g, dt = %.6g s, total = %.6g s\n', ...
    loadCase, nModes, dampingRatio, dt, tTotal);

oldDir = pwd;
cleanup = onCleanup(@() cd(oldDir)); %#ok<NASGU>
cd(paths.meet_elastic);

InputFile = caseFile;
OutputFile = [];
UsedDataFile = fullfile(paths.output, sprintf('%s_linear_used_data.txt', tag));
IsANS = 0;
DampRatio = dampingRatio;
IntegSchem = 'G2';
ThermalNL = 0;

assemblyLog = evalc(['[GlobMatr, FinitElemInfo] = Main_FOSDLIN851T5MEET_V4(' ...
    'InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);']);
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

fprintf('Solving coupled static reference...\n');
CC = [KuuT, KutT; KtuT, KttT] \ [Fstep; zeros(finalDofMEE, 1)];
QdCoupledStatic = CC(1:finalDofM);
SensTStatic = CC(finalDofM + 1:end);

fprintf('Solving mechanical static reference...\n');
QdMechanicalStatic = KuuT \ Fstep;

[centerNodeIndex, centerNodeId, centerCoord] = find_nearest_node(FinitElemInfo.Node, [0.15, 0.15, 0.0]);
centerReducedDof = find_reduced_mechanical_dof(FinitElemInfo.Node, centerNodeIndex, 3);
coupledStaticCenterMm = QdCoupledStatic(centerReducedDof) * 1000;
mechanicalStaticCenterMm = QdMechanicalStatic(centerReducedDof) * 1000;

fprintf('Solving first %d modes...\n', nModes);
[Phi, lambda, eigStatus] = solve_modes(KuuT, MuuT, nModes);
omega = sqrt(lambda);
freqHz = omega / (2 * pi);

modalForce = Phi' * Fstep;
etaStatic = modalForce ./ (omega .^ 2);
centerShape = Phi(centerReducedDof, :);
modalStaticCenterMm = 1000 * (centerShape * etaStatic);

timeS = (0:dt:tTotal)';
eta = modal_step_response(timeS, omega, modalForce, dampingRatio);
wCenterMm = 1000 * (centerShape * eta)';

fprintf('Recovering thermal layer response...\n');
qTime = Phi * eta;
thetaTime = KttT \ (-KtuT * qTime);
thetaLayerTime = average_layers_over_time(thetaTime', nLayer);
thetaSpanK = max(thetaLayerTime, [], 2) - min(thetaLayerTime, [], 2);
thetaStaticLayers = average_by_layer(SensTStatic, nLayer);

[peakAbsMm, peakIdx] = max(abs(wCenterMm));
peakMm = wCenterMm(peakIdx);
peakTimeS = timeS(peakIdx);
finalMm = wCenterMm(end);
modalCaptureRatio = modalStaticCenterMm / mechanicalStaticCenterMm;
overshootRatio = peakAbsMm / max(abs(mechanicalStaticCenterMm), eps);

outCsv = fullfile(paths.output, sprintf('%s_timeseries.csv', tag));
outModes = fullfile(paths.output, sprintf('%s_modes.csv', tag));
outSummary = fullfile(paths.output, sprintf('%s_summary.csv', tag));
outMat = fullfile(paths.output, sprintf('%s.mat', tag));

T = table(timeS, wCenterMm, thetaSpanK, ...
    'VariableNames', {'time_s', 'w_center_mm', 'theta_span_K'});
for i = 1:nLayer
    T.(sprintf('theta_layer_%02d_K', i)) = thetaLayerTime(:, i);
end
writetable(T, outCsv);

modes = table((1:numel(freqHz))', freqHz(:), omega(:), modalForce(:), ...
    etaStatic(:), centerShape(:), 1000 * centerShape(:) .* etaStatic(:), ...
    'VariableNames', {'mode', 'freq_Hz', 'omega_rad_s', 'modal_force', ...
    'eta_static', 'center_shape', 'center_static_contribution_mm'});
writetable(modes, outModes);

summary = table(string(tag), string(caseFile), string(loadCase), activeLoad, ...
    activeVolt, activeMagnetic, nModes, dampingRatio, dt, tTotal, height(T), ...
    centerNodeId, centerCoord(1), centerCoord(2), centerCoord(3), centerReducedDof, ...
    coupledStaticCenterMm, mechanicalStaticCenterMm, modalStaticCenterMm, ...
    modalCaptureRatio, finalMm, peakMm, peakAbsMm, peakTimeS, overshootRatio, ...
    min(thetaSpanK), max(thetaSpanK), string(eigStatus), ...
    'VariableNames', {'tag', 'case_file', 'load_case', 'load_scale', ...
    'volt', 'magnetic', 'n_modes', 'damping_ratio', 'dt_s', 'total_s', ...
    'steps', 'center_node_id', 'center_x_m', 'center_y_m', 'center_z_m', ...
    'center_reduced_dof', 'coupled_static_center_mm', ...
    'mechanical_static_center_mm', 'modal_static_center_mm', ...
    'modal_capture_ratio', 'final_center_mm', 'peak_center_mm', ...
    'peak_abs_center_mm', 'peak_time_s', 'overshoot_ratio', ...
    'theta_span_min_K', 'theta_span_max_K', 'eigen_status'});
for i = 1:numel(freqHz)
    summary.(sprintf('freq_%02d_Hz', i)) = freqHz(i);
end
writetable(summary, outSummary);

save(outMat, 'summary', 'modes', 'T', 'thetaLayerTime', 'thetaStaticLayers', ...
    'freqHz', 'omega', 'modalForce', 'etaStatic', 'centerShape', ...
    'centerReducedDof', 'centerNodeId', 'centerCoord', '-v7.3');

fprintf('\nWrote %s\n', outCsv);
fprintf('Wrote %s\n', outModes);
fprintf('Wrote %s\n', outSummary);
fprintf('Wrote %s\n', outMat);
disp(summary(:, {'tag', 'n_modes', 'coupled_static_center_mm', ...
    'mechanical_static_center_mm', 'modal_static_center_mm', ...
    'modal_capture_ratio', 'peak_center_mm', 'peak_time_s', ...
    'overshoot_ratio', 'theta_span_max_K'}));

function value = env_number(name, defaultValue)
    raw = getenv(name);
    if isempty(raw)
        value = defaultValue;
        return;
    end
    value = str2double(raw);
    if isnan(value)
        error('run_dynamic_modal_30x30:BadEnv', ...
            '%s must be numeric, got: %s', name, raw);
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

function write_text(path, text)
    fid = fopen(path, 'w');
    if fid < 0
        error('run_dynamic_modal_30x30:WriteFailed', 'Cannot write %s', path);
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
                    error('run_dynamic_modal_30x30:ConstrainedCenter', ...
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
            eta(i, :) = statEta * (1 - cos(omega(i) * timeS')) ;
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

function values = average_by_layer(vec, nLayer)
    values = nan(nLayer, 1);
    for i = 1:nLayer
        values(i) = mean(vec(i:nLayer:end));
    end
end
