%% Verify the run_meet_static pyro-assembly correction on a fresh 10x10 solve.
clear; clc;
paths = setup_paths();
caseFile = fullfile(paths.cases, 'validation_mesh', ...
    'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt');

corrected = run_meet_static(caseFile, 'elastic', ...
    'LoadScale', -15000, 'OutTag', 'inverse_pyrofix_10x10_corrected', ...
    'SolveSensors', true, 'CorrectPyroAssembly', true, 'UseCache', true);
legacy = run_meet_static(caseFile, 'elastic', ...
    'LoadScale', -15000, 'OutTag', 'inverse_pyrofix_10x10_legacy', ...
    'SolveSensors', true, 'CorrectPyroAssembly', false, 'UseCache', true);

targets = [0.5; 1.0; 2.0];
rows = table();
for mode = ["corrected"; "legacy"]'
    if mode == "corrected"
        result = corrected;
    else
        result = legacy;
    end
    for i = 1:numel(targets)
        scale = targets(i) / abs(result.wCenter_mm);
        row = table(mode, targets(i), result.wCenter_mm, scale, ...
            result.electric_span * scale, result.magnetic_span * scale, ...
            result.correct_pyro_assembly, ...
            'VariableNames', {'mode','target_w_mm','probe_w_center_mm','scale', ...
            'electric_span','magnetic_span','correct_pyro_assembly'});
        rows = [rows; row]; %#ok<AGROW>
    end
end

outDir = fullfile(paths.workbench, 'outputs', 'paper-20260715-fgmee', ...
    'experiments', 'inverse_sensing');
if ~isfolder(outDir), mkdir(outDir); end
outCsv = fullfile(outDir, 'matlab_inverse_pyro_fix_10x10.csv');
writetable(rows, outCsv);
fprintf('MATLAB_INVERSE_PYRO_FIX_VERIFIED,%s\n', outCsv);
disp(rows);
