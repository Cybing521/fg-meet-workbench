%% Recompute the final 20x20/30x30 curvature-gradient matrix (48 solves).
clear; clc;
paths = setup_paths();
outDir = fullfile(paths.package_root, 'results', 'recomputed', 'curvature');
if ~isfolder(outDir)
    mkdir(outDir);
end
outRaw = fullfile(outDir, 'curvature_20_30_raw.csv');
outConv = fullfile(outDir, 'curvature_20_30_convergence.csv');
expectedRevision = "layer_local_pyro_v3";

rows = struct('mesh', {}, 'mode', {}, 'radius_m', {}, 'curvature_1pm', {}, ...
    'load_case', {}, 'w_center_mm', {}, 'electric_span', {}, 'magnetic_span', {}, ...
    'theta_span_K', {}, 'center_node_id', {}, 'center_coord_1', {}, ...
    'center_coord_2', {}, 'center_coord_3', {}, 'case_file', {}, ...
    'solver_revision', {}, 'coupling_sequence', {}, 'solve_status', {}, ...
    'sensor_status', {}, 'mechanical_thermal_relative_residual', {}, ...
    'sensor_relative_residual', {}, 'case_sha256', {}, 'status', {});

if isfile(outRaw)
    checkpoint = readtable(outRaw, 'TextType', 'string');
    expected = fieldnames(rows);
    if all(ismember(expected, checkpoint.Properties.VariableNames)) && ...
            all(checkpoint.solver_revision == expectedRevision) && ...
            all(checkpoint.solve_status == "ok") && all(checkpoint.sensor_status == "ok")
        rows = table2struct(checkpoint(:, expected)).';
        fprintf('CURVATURE_RESUME,rows,%d,solver_revision,%s\n', ...
            numel(rows), expectedRevision);
    else
        fprintf('CURVATURE_CHECKPOINT_REJECTED,reason,contract_or_revision_mismatch\n');
    end
end

radii = [1.0, 0.4, 0.3, 0.2];
for mesh = [20, 30]
    for radius = radii
        radiusTag = strrep(sprintf('%.1f', radius), '.', 'p');
        radiusFile = sprintf('%g', radius);
        for mode = ["U", "X"]
            filename = sprintf('Thermal_CFFF_%s_Vf0.6_R%sm-%dx%d-10layer.txt', ...
                mode, radiusFile, mesh, mesh);
            caseFile = fullfile(paths.cases, 'curvature', ...
                sprintf('%dx%d', mesh, mesh), filename);
            if ~isfile(caseFile)
                error('run_curvature_validation:MissingCase', 'Missing %s', caseFile);
            end
            caseSha256 = sha256_file(caseFile);

            completed = arrayfun(@(r) r.mesh == mesh && r.mode == mode && ...
                abs(r.radius_m - radius) < 1e-12 && ...
                string(r.solver_revision) == expectedRevision && ...
                string(r.solve_status) == "ok" && string(r.sensor_status) == "ok" && ...
                string(r.case_sha256) == caseSha256, rows);
            completedLoads = string({rows(completed).load_case});
            if all(ismember(["elastic", "electro", "magneto"], completedLoads))
                fprintf('CURVATURE_SKIP,mesh,%d,mode,%s,radius_m,%.6g\n', ...
                    mesh, mode, radius);
                continue
            end

            tag = sprintf('curvature_%d_%s_R%s', mesh, mode, radiusTag);
            fprintf('CURVATURE_START,mesh,%d,mode,%s,radius_m,%.6g\n', ...
                mesh, mode, radius);
            elastic = run_meet_static(caseFile, 'elastic', ...
                'LoadScale', -15000, 'OutTag', [tag '_elastic'], ...
                'SolveSensors', true, ...
                'UseCache', true, 'Quiet', true);
            electro = run_meet_static(caseFile, 'electro', ...
                'Volt', 300, 'OutTag', [tag '_electro'], ...
                'SolveSensors', true, ...
                'UseCache', true, 'Quiet', true);
            magneto = run_meet_static(caseFile, 'magneto', ...
                'Magnetic', 200, 'OutTag', [tag '_magneto'], ...
                'SolveSensors', true, ...
                'UseCache', true, 'Quiet', true);
            assert_formal_result(elastic, expectedRevision);
            assert_formal_result(electro, expectedRevision);
            assert_formal_result(magneto, expectedRevision);
            rows(end + 1) = make_row(mesh, mode, radius, caseFile, caseSha256, "elastic", elastic); %#ok<SAGROW>
            rows(end + 1) = make_row(mesh, mode, radius, caseFile, caseSha256, "electro", electro); %#ok<SAGROW>
            rows(end + 1) = make_row(mesh, mode, radius, caseFile, caseSha256, "magneto", magneto); %#ok<SAGROW>
            writetable(struct2table(rows), outRaw);
        end
    end
end

results = sortrows(struct2table(rows), ...
    {'radius_m','mode','load_case','mesh'}, {'descend','ascend','ascend','ascend'});
results.w_change_20_to_30_pct = nan(height(results), 1);
results.mesh_gate_0p5pct = strings(height(results), 1);
for radius = radii
    for mode = ["U", "X"]
        for loadCase = ["elastic", "electro", "magneto"]
            idx20 = find(results.mesh == 20 & results.mode == mode & ...
                results.load_case == loadCase & abs(results.radius_m - radius) < 1e-12);
            idx30 = find(results.mesh == 30 & results.mode == mode & ...
                results.load_case == loadCase & abs(results.radius_m - radius) < 1e-12);
            if numel(idx20) == 1 && numel(idx30) == 1
                change = 100 * abs(results.w_center_mm(idx30) - results.w_center_mm(idx20)) / ...
                    max(abs(results.w_center_mm(idx30)), eps);
                results.w_change_20_to_30_pct(idx30) = change;
                if change <= 0.5
                    results.mesh_gate_0p5pct(idx30) = "pass";
                else
                    results.mesh_gate_0p5pct(idx30) = "fail";
                end
            end
        end
    end
end
writetable(results, outConv);
fprintf('CURVATURE_COMPLETED,%s\n', outConv);

function row = make_row(mesh, mode, radius, caseFile, caseSha256, loadCase, result)
coord = result.centerCoord;
row = struct('mesh', mesh, 'mode', string(mode), 'radius_m', radius, ...
    'curvature_1pm', 1 / radius, 'load_case', string(loadCase), ...
    'w_center_mm', result.wCenter_mm, 'electric_span', result.electric_span, ...
    'magnetic_span', result.magnetic_span, 'theta_span_K', result.theta_span_K, ...
    'center_node_id', result.centerNodeId, 'center_coord_1', coord(1), ...
    'center_coord_2', coord(2), 'center_coord_3', coord(3), ...
    'case_file', string(caseFile), 'solver_revision', string(result.solver_revision), ...
    'coupling_sequence', string(result.coupling_sequence), ...
    'solve_status', string(result.solve_status), ...
    'sensor_status', string(result.sensor_status), ...
    'mechanical_thermal_relative_residual', result.mechanical_thermal_relative_residual, ...
    'sensor_relative_residual', result.sensor_relative_residual, ...
    'case_sha256', string(caseSha256), 'status', string(result.solve_status));
end

function assert_formal_result(result, expectedRevision)
if string(result.solver_revision) ~= expectedRevision || ...
        string(result.solve_status) ~= "ok" || string(result.sensor_status) ~= "ok"
    error('run_curvature_validation:FormalContract', ...
        'Result does not satisfy the formal solver revision and status contract.');
end
values = [result.wCenter_mm, result.electric_span, result.magnetic_span, ...
    result.mechanical_thermal_relative_residual, result.sensor_relative_residual];
if any(~isfinite(values)) || result.mechanical_thermal_relative_residual > 1e-8 || ...
        result.sensor_relative_residual > 1e-8
    error('run_curvature_validation:Residual', ...
        'Result is nonfinite or exceeds the 1e-8 residual gate.');
end
end

function digest = sha256_file(path)
engine = java.security.MessageDigest.getInstance('SHA-256');
fileId = fopen(path, 'rb');
if fileId < 0
    error('run_curvature_validation:HashOpen', 'Cannot open %s for hashing.', path);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
while ~feof(fileId)
    bytes = fread(fileId, 1024 * 1024, '*uint8');
    if ~isempty(bytes)
        engine.update(typecast(bytes(:), 'int8'));
    end
end
raw = typecast(engine.digest(), 'uint8');
digest = string(lower(reshape(dec2hex(raw, 2).', 1, [])));
end
