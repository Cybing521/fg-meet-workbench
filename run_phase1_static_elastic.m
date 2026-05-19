%% run_phase1_static_elastic  Single CFFF static run (mechanical load, thermal coupling)
clear; clc;
paths = setup_paths();

% --- pick case (change as needed) ---
caseFile = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
if ~isfile(caseFile)
    run(fullfile(paths.workbench, 'run_phase1_generate_cases.m'));
end

meetDir = paths.meet_elastic;
addpath(genpath(fullfile(meetDir, '..', 'SubFunMFC')));

InputFile = caseFile;
OutputFile = [];
UsedDataFile = fullfile(paths.output, 'LINEAR_DataUsed_phase1.txt');
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL = 0;
DampRatio = 0.8/100;
IntegSchem = 'G2';

fprintf('Running Main_FOSDLIN851T5MEET_V4 ...\n');
fprintf('  Input: %s\n', InputFile);

[GlobMatr, FinitElemInfo, ~] = Main_FOSDLIN851T5MEET_V4( ...
    InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);

KuuT = GlobMatr.KuuT;
KutT = GlobMatr.KutT;
KtuT = GlobMatr.KtuT;
KttT = GlobMatr.KttT;
FusT = GlobMatr.FusT;
FinalDofM = size(KuuT, 1);
FinalDofMEE = size(KttT, 1);

% 30x30 mesh, 10 MEE layers per element -> 900 elements, 9000 MEE DOFs
nMeePerElem = 10;
Loadmax = -15000;   % Pa, uniform pressure (see MEET_CFFF_thermal_dynamic comments)
Voltmax = 0;
Magnetic = 0;

PhiaMT = zeros(FinalDofMEE, 1);
MgaT = zeros(FinalDofMEE, 1);
DelT = zeros(FinalDofMEE, 1);
PhiaMT(nMeePerElem:nMeePerElem:FinalDofMEE) = -Voltmax;
PhiaMT(1:nMeePerElem:FinalDofMEE) = Voltmax;
MgaT(nMeePerElem:nMeePerElem:FinalDofMEE) = -Magnetic;
MgaT(1:nMeePerElem:FinalDofMEE) = Magnetic;

FueT = FusT * Loadmax;
FutT = zeros(FinalDofMEE, 1);

AA = [KuuT, KutT; KtuT, KttT];
BB = [FueT; FutT];
CC = AA \ BB;
Qd = CC(1:FinalDofM);
SensM_T = CC(FinalDofM+1:end);

% Center point DOF (30x30 plate): node at (0.15, 0.15) approx index 4601 for w
% See MEET_CFFF_thermal_dynamic: PositionM=2998 for 20x20; for 30x30 center ~ 15*61+31
centerIdx = 31 + 30 * 15;  % rough center node index on 31x31 grid
wCenter = Qd(5 * (centerIdx - 1) + 3);  % 3rd DOF is w

thetaLayers = SensM_T(1:nMeePerElem:min(nMeePerElem*100, numel(SensM_T)));
thetaLayers = thetaLayers(1:min(10, numel(thetaLayers)));

result = struct();
result.inputFile = InputFile;
result.wCenter_m = wCenter;
result.wCenter_mm = wCenter * 1000;
result.theta_layers = thetaLayers;
result.load_Pa = Loadmax;
result.timestamp = datestr(now);

outMat = fullfile(paths.output, 'phase1_static_U_Vf06.mat');
save(outMat, 'result', 'Qd', 'SensM_T');
fprintf('\n--- Phase 1 result ---\n');
fprintf('Center w = %.6f mm\n', result.wCenter_mm);
fprintf('theta (first layers): ');
fprintf(' %.4e', thetaLayers);
fprintf('\nSaved: %s\n', outMat);
