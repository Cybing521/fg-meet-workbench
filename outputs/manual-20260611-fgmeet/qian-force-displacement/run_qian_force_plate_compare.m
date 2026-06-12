function run_qian_force_plate_compare()
%RUN_QIAN_FORCE_PLATE_COMPARE Re-run Qian's CFFF 0.6Vf force-displacement case.

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fullfile(scriptDir, '..', '..', '..');
qianRoot = fullfile(repoRoot, 'reference', 'predecessor-code', 'qian-shenyun', ...
    '双向耦合程序-new', '双向耦合程序-new');
qianElastic = fullfile(qianRoot, 'MEET-elastic-thermal');
qianSubfun = fullfile(qianRoot, 'SubFunMFC');
outDir = scriptDir;

addpath(scriptDir, '-begin');
addpath(genpath(qianSubfun), '-begin');

oldDir = pwd;
cleanup = onCleanup(@() cd(oldDir)); %#ok<NASGU>
cd(qianElastic);

inputFile = fullfile(qianElastic, 'InputFile', 'Thermal_CFFFplate_0.6Vf-30x30-10layer.txt');
usedDataFile = fullfile(outDir, 'qian_LINEAR_DataUsed_runtime.txt');
loadmax = -15000;

[GlobMatr, FinitElemInfo, MateProp] = Main_FOSDLIN851T5MEEP_V4(inputFile, ...
    [], usedDataFile, 0, 0.8/100, 'G2', 0); %#ok<ASGLU>

KuuT = GlobMatr.KuuT;
KutT = GlobMatr.KutT;
KtuT = GlobMatr.KtuT;
KttT = GlobMatr.KttT;
FusT = GlobMatr.FusT;

finalDofM = size(KuuT, 1);
finalDofT = size(KttT, 1);
fueT = FusT * loadmax;

qDirect = KuuT \ fueT;

aa = [KuuT, KutT; KtuT, KttT];
bb = [fueT; zeros(finalDofT, 1)];
cc = aa \ bb;
qCoupled = cc(1:finalDofM);
sensT = cc(finalDofM + 1:end);

tDirect = restore_mechanical_dof(FinitElemInfo.Node, qDirect);
tCoupled = restore_mechanical_dof(FinitElemInfo.Node, qCoupled);

pointIds = string({'p1'; 'p2'; 'p3'; 'p4'; 'p5'; ...
    'p6'; 'p7'; 'p8'; 'p9'; 'p10'; ...
    'p11'; 'p12'; 'p13'; 'p14'; 'p15'});
x = [0.05; 0.10; 0.15; 0.20; 0.25; ...
     0.05; 0.10; 0.15; 0.20; 0.25; ...
     0.05; 0.10; 0.15; 0.20; 0.25];
y = [0.05; 0.05; 0.05; 0.05; 0.05; ...
     0.15; 0.15; 0.15; 0.15; 0.15; ...
     0.25; 0.25; 0.25; 0.25; 0.25];

nodeId = zeros(numel(x), 1);
nodeX = zeros(numel(x), 1);
nodeY = zeros(numel(x), 1);
qianCoupledMm = zeros(numel(x), 1);
qianDirectMm = zeros(numel(x), 1);
for i = 1:numel(x)
    idx = find_nearest_node(FinitElemInfo.Node, [x(i), y(i), 0]);
    nodeId(i) = FinitElemInfo.Node(idx, 1);
    nodeX(i) = FinitElemInfo.Node(idx, 2);
    nodeY(i) = FinitElemInfo.Node(idx, 3);
    fullDof = 5 * (idx - 1) + 3;
    qianCoupledMm(i) = 1000 * tCoupled(fullDof);
    qianDirectMm(i) = 1000 * tDirect(fullDof);
end

centerIdx = find_nearest_node(FinitElemInfo.Node, [0.15, 0.15, 0]);
centerDof = 5 * (centerIdx - 1) + 3;
centerCoupledMm = 1000 * tCoupled(centerDof);
centerDirectMm = 1000 * tDirect(centerDof);

pointTable = table(pointIds, x, y, nodeId, nodeX, nodeY, ...
    qianCoupledMm, qianDirectMm);
writetable(pointTable, fullfile(outDir, 'qian_force_points_CFFF_0p6_30x30_10layer.csv'));

summary = table(string("qian_CFFF_0p6_30x30_10layer"), loadmax, ...
    centerCoupledMm, centerDirectMm, finalDofM, finalDofT, ...
    string(inputFile), string(datestr(now)), ...
    'VariableNames', {'case_id', 'loadmax', 'center_coupled_mm', ...
    'center_direct_mm', 'final_dof_m', 'final_dof_t', 'input_file', 'timestamp'});
writetable(summary, fullfile(outDir, 'qian_force_summary_CFFF_0p6_30x30_10layer.csv'));

save(fullfile(outDir, 'qian_force_plate_CFFF_0p6_30x30_10layer.mat'), ...
    'GlobMatr', 'FinitElemInfo', 'qCoupled', 'qDirect', 'tCoupled', ...
    'tDirect', 'sensT', 'pointTable', 'summary');

fprintf('Qian coupled center = %.12f mm\n', centerCoupledMm);
fprintf('Qian direct center = %.12f mm\n', centerDirectMm);
fprintf('Wrote %s\n', outDir);
end

function tQd = restore_mechanical_dof(node, qd)
dofPerNode = 5;
dofFlagStart = 5;
numNode = size(node, 1);
tQd = zeros(numNode * dofPerNode, 1);
qIndex = 1;
for nodeIndex = 1:numNode
    for dofIndex = 1:dofPerNode
        fullIndex = (nodeIndex - 1) * dofPerNode + dofIndex;
        if node(nodeIndex, dofFlagStart + dofIndex - 1) == 0
            tQd(fullIndex) = qd(qIndex);
            qIndex = qIndex + 1;
        end
    end
end
if qIndex - 1 ~= numel(qd)
    error('restore:dofMismatch', 'Restored %d DOFs, qd has %d.', qIndex - 1, numel(qd));
end
end

function nodeIndex = find_nearest_node(node, targetCoord)
diff = node(:, 2:4) - targetCoord;
[~, nodeIndex] = min(sum(diff .^ 2, 2));
end
