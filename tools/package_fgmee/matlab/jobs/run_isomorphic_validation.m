%% Recompute the matched MATLAB H20 solid at 10/15/20 in-plane meshes.
clear; clc;
paths = setup_paths();
outDir = fullfile(paths.package_root, 'results', 'recomputed', 'isomorphic');
if ~isfolder(outDir)
    mkdir(outDir);
end

loadCases = struct( ...
    'name', {'electric_equivalent_stress','magnetic_external_stress'}, ...
    'bottom_stress_Pa', {+4.934e6, -16.49e6}, ...
    'top_stress_Pa', {-4.934e6, +16.49e6});

allRows = table();
for mesh = [10, 15, 20]
    fprintf('ISOMORPHIC_START,mesh,%d\n', mesh);
    started = tic;
    rows = run_isomorphic_solid_cfff(mesh, mesh, 10, loadCases);
    if any(rows.status ~= "completed") || ...
            any(~isfinite(rows.w_center_mm)) || any(~isfinite(rows.w_free_mid_mm)) || ...
            any(~isfinite(rows.relative_equilibrium_residual)) || ...
            any(rows.relative_equilibrium_residual > 1e-8)
        error('run_isomorphic_validation:FormalContract', ...
            'Isomorphic solve is incomplete, nonfinite, or exceeds the 1e-8 residual gate.');
    end
    rows.solver_revision = repmat("h20_isomorphic_v1", height(rows), 1);
    rows.solve_status = rows.status;
    rows.elapsed_s = repmat(toc(started), height(rows), 1);
    allRows = [allRows; rows]; %#ok<AGROW>
end

allRows.w_change_from_previous_pct = nan(height(allRows), 1);
for loadCase = unique(allRows.load_case).'
    idx = find(allRows.load_case == loadCase);
    [~, order] = sort(allRows.nx(idx));
    idx = idx(order);
    for j = 2:numel(idx)
        current = idx(j);
        previous = idx(j - 1);
        allRows.w_change_from_previous_pct(current) = 100 * ...
            abs(allRows.w_center_mm(current) - allRows.w_center_mm(previous)) / ...
            max(abs(allRows.w_center_mm(current)), eps);
    end
end

outCsv = fullfile(outDir, 'matlab_isomorphic_solid_results.csv');
writetable(allRows, outCsv);
disp(allRows);
fprintf('ISOMORPHIC_COMPLETED,%s\n', outCsv);
