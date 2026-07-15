%% MATLAB H20 solid validation against the matched COMSOL solid model.
clear; clc;
paths = setup_paths();
outDir = fullfile(paths.workbench, 'outputs', 'paper-20260715-fgmee', ...
    'experiments', 'isomorphic_solid');
if ~isfolder(outDir)
    mkdir(outDir);
end
loadCases = struct( ...
    'name', {'electric_equivalent_stress','magnetic_external_stress'}, ...
    'bottom_stress_Pa', {+4.934e6, -16.49e6}, ...
    'top_stress_Pa', {-4.934e6, +16.49e6});
allRows = table();
for mesh = [10, 15, 20]
    fprintf('ISOMORPHIC_MATLAB_START,mesh,%d\n', mesh);
    tic;
    rows = run_isomorphic_solid_cfff(mesh, mesh, 10, loadCases);
    rows.elapsed_s = repmat(toc, height(rows), 1);
    allRows = [allRows; rows]; %#ok<AGROW>
    writetable(allRows, fullfile(outDir, 'matlab_isomorphic_solid_results.csv'));
    fprintf('ISOMORPHIC_MATLAB_DONE,mesh,%d,w_electric_mm,%.12g,w_magnetic_mm,%.12g\n', ...
        mesh, rows.w_center_mm(1), rows.w_center_mm(2));
end
allRows.w_change_from_previous_pct = nan(height(allRows),1);
for loadCase = unique(allRows.load_case).'
    idx = find(allRows.load_case == loadCase);
    [~, order] = sort(allRows.nx(idx)); idx = idx(order);
    for j = 2:numel(idx)
        current = idx(j); previous = idx(j-1);
        allRows.w_change_from_previous_pct(current) = 100 * ...
            abs(allRows.w_center_mm(current)-allRows.w_center_mm(previous)) / ...
            max(abs(allRows.w_center_mm(current)), eps);
    end
end
writetable(allRows, fullfile(outDir, 'matlab_isomorphic_solid_results.csv'));
save(fullfile(outDir, 'matlab_isomorphic_solid_results.mat'), 'allRows');
disp(allRows);
fprintf('ISOMORPHIC_MATLAB_COMPLETED,%s\n', ...
    fullfile(outDir, 'matlab_isomorphic_solid_results.csv'));
