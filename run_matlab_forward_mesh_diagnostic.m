%% run_matlab_forward_mesh_diagnostic
% Three-level in-plane mesh diagnostic for the frozen U/Vf0.6/CFFF plate.
% All three input files share the exact same ten-layer material block.

clear; clc;
paths = setup_paths();

meshDivisions = [10, 20, 30];
caseFiles = {
    fullfile(paths.cases, 'validation_mesh', 'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt')
    fullfile(paths.cases, 'validation_mesh', 'Thermal_CFFF_U_Vf0.6-20x20-10layer.txt')
    fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt')
};

emptyRow = make_row(NaN, '', NaN, NaN, NaN);
rows = repmat(emptyRow, numel(meshDivisions), 1);
for i = 1:numel(meshDivisions)
    caseFile = caseFiles{i};
    if ~isfile(caseFile)
        error('run_matlab_forward_mesh_diagnostic:MissingCase', ...
            'Missing validation case: %s', caseFile);
    end
    tag = sprintf('meshdiag_%dx%d', meshDivisions(i), meshDivisions(i));
    electric = run_meet_static(caseFile, 'electro', ...
        'Volt', 300, 'OutTag', [tag '_electro_300V'], 'SolveSensors', false);
    magnetic = run_meet_static(caseFile, 'magneto', ...
        'Magnetic', 200, 'OutTag', [tag '_magnetic_200A'], 'SolveSensors', false);
    mechanical = run_meet_static(caseFile, 'elastic', ...
        'LoadScale', -15000, 'OutTag', [tag '_elastic_15kPa'], 'SolveSensors', false);

    rows(i) = make_row(meshDivisions(i), caseFile, ...
        electric.wCenter_mm, magnetic.wCenter_mm, mechanical.wCenter_mm);
end

results = struct2table(rows);
results.electric_change_from_previous_pct = previous_change(results.electric_w_center_mm);
results.magnetic_change_from_previous_pct = previous_change(results.magnetic_w_center_mm);
results.mechanical_change_from_previous_pct = previous_change(results.mechanical_w_center_mm);

outDir = fullfile(paths.workbench, 'outputs', 'paper-20260715-fgmee', 'experiments', 'results');
if ~isfolder(outDir)
    mkdir(outDir);
end
outCsv = fullfile(outDir, 'matlab_forward_mesh_diagnostic.csv');
outMat = fullfile(outDir, 'matlab_forward_mesh_diagnostic.mat');
writetable(results, outCsv);
save(outMat, 'results');

fprintf('Wrote %s\n', outCsv);
fprintf('Wrote %s\n', outMat);
disp(results);

function row = make_row(meshDivisions, caseFile, electricW, magneticW, mechanicalW)
    row = struct();
    row.mesh_divisions = meshDivisions;
    row.case_file = string(caseFile);
    row.electric_w_center_mm = electricW;
    row.magnetic_w_center_mm = magneticW;
    row.mechanical_w_center_mm = mechanicalW;
    row.status = "completed";
end

function changes = previous_change(values)
    changes = NaN(size(values));
    for i = 2:numel(values)
        changes(i) = 100 * abs(values(i) - values(i-1)) / max(abs(values(i)), eps);
    end
end
