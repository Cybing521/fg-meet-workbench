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
dt = env_number('FG_POROUS_DYN_DT', 1e-4);
tTotal = env_number('FG_POROUS_DYN_TTOTAL', 4e-2);
loadScale = -15000;

poroNames = {'Even', 'Uneven', 'LogUneven'};
poroName = poroNames{poroMode};
vfTag = sprintf('Vf%02d', round(vf0 * 100));
e0Tag = sprintf('e%02d', round(e0 * 100));
tag = sprintf('dynamic_porous_%s_%s_%s_%s', fgMode, vfTag, e0Tag, poroName);

%% Locate input file
caseName = sprintf('Porous_CFFF_%s_Vf%.1f_%s_%s-30x30-10layer.txt', ...
    fgMode, vf0, e0Tag, poroName);
caseFile = fullfile(paths.workbench, 'cases', 'porous', caseName);

% If 30x30 porous file doesn't exist, try 10x10
if ~isfile(caseFile)
    caseName10 = sprintf('Porous_CFFF_%s_Vf%.1f_%s_%s-10x10-10layer.txt', ...
        fgMode, vf0, e0Tag, poroName);
    caseFile10 = fullfile(paths.workbench, 'cases', 'porous', caseName10);
    if isfile(caseFile10)
        caseFile = caseFile10;
        tag = [tag '_10x10'];
    else
        error('run_dynamic_porous:NoInput', ...
            'Input file not found: %s\nRun generate_porous_cases.py first.', caseFile);
    end
end

fprintf('=== Porous Dynamic Representative ===\n');
fprintf('FG=%s, Vf0=%.1f, e0=%.1f, Porosity=%s\n', fgMode, vf0, e0, poroName);
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
