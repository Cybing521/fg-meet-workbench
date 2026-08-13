%% Recompute the formal displacement-to-potential mesh matrix.
clear; clc;
paths = setup_paths();
outDir = fullfile(paths.package_root, 'results', 'recomputed', 'inverse');
if ~isfolder(outDir)
    mkdir(outDir);
end
outCsv = fullfile(outDir, 'matlab_inverse_structural_pyro_mesh.csv');
expectedRevision = "layer_local_pyro_v3";
targetsMm = [0.5, 1.0, 2.0];

fieldOrder = {'mesh_divisions','target_w_mm','base_w_center_mm', ...
    'electric_span_V','magnetic_span_A','solver_revision','coupling_sequence', ...
    'solve_status','sensor_status','mechanical_thermal_relative_residual', ...
    'sensor_relative_residual','mechanical_thermal_rcond_estimate', ...
    'sensor_rcond_estimate','center_probe_method','case_sha256'};
rows = table();
if isfile(outCsv)
    checkpoint = readtable(outCsv, 'TextType', 'string');
    if all(ismember(fieldOrder, checkpoint.Properties.VariableNames)) && ...
            all(checkpoint.solver_revision == expectedRevision) && ...
            all(checkpoint.solve_status == "ok") && all(checkpoint.sensor_status == "ok")
        rows = checkpoint(:, fieldOrder);
        fprintf('INVERSE_RESUME,rows,%d,solver_revision,%s\n', height(rows), expectedRevision);
    else
        fprintf('INVERSE_CHECKPOINT_REJECTED,reason,contract_or_revision_mismatch\n');
    end
end

for mesh = [10, 15, 20, 30]
    caseFile = fullfile(paths.cases, 'inverse', ...
        sprintf('Thermal_CFFF_U_Vf0.6-%dx%d-10layer.txt', mesh, mesh));
    if ~isfile(caseFile)
        error('run_inverse_validation:MissingCase', 'Missing %s', caseFile);
    end
    caseSha256 = sha256_file(caseFile);
    completed = false;
    if ~isempty(rows)
        completedRows = rows.mesh_divisions == mesh & ...
            rows.solver_revision == expectedRevision & rows.case_sha256 == caseSha256;
        completedTargets = sort(rows.target_w_mm(completedRows));
        completed = numel(completedTargets) == numel(targetsMm) && ...
            all(abs(completedTargets(:) - targetsMm(:)) <= 1e-12);
    end
    if completed
        fprintf('INVERSE_SKIP,mesh,%d,case_sha256,%s\n', mesh, caseSha256);
        continue;
    end

    fprintf('INVERSE_START,mesh,%d,case_sha256,%s\n', mesh, caseSha256);
    tag = sprintf('inverse_structural_pyro_%dx%d', mesh, mesh);
    result = run_meet_static(caseFile, 'elastic', 'LoadScale', -15000, ...
        'OutTag', tag, 'SolveSensors', true, 'UseCache', true, 'Quiet', true);
    assert_formal_result(result, expectedRevision);
    baseW = abs(result.wCenter_mm);
    if baseW <= eps
        error('run_inverse_validation:ZeroDisplacement', ...
            'Mesh %d produced zero center displacement.', mesh);
    end

    if ~isempty(rows)
        rows(rows.mesh_divisions == mesh, :) = [];
    end
    newRows = table();
    for target = targetsMm
        scale = target / baseW;
        next = table(mesh, target, result.wCenter_mm, ...
            abs(result.electric_span) * scale, abs(result.magnetic_span) * scale, ...
            string(result.solver_revision), string(result.coupling_sequence), ...
            string(result.solve_status), string(result.sensor_status), ...
            result.mechanical_thermal_relative_residual, result.sensor_relative_residual, ...
            result.mechanical_thermal_rcond_estimate, result.sensor_rcond_estimate, ...
            string(result.centerProbeMethod), caseSha256, ...
            'VariableNames', fieldOrder);
        newRows = [newRows; next]; %#ok<AGROW>
    end
    rows = [rows; newRows]; %#ok<AGROW>
    rows = sortrows(rows, {'mesh_divisions','target_w_mm'});
    writetable(rows, outCsv);
end

fprintf('INVERSE_COMPLETED,%s\n', outCsv);

function assert_formal_result(result, expectedRevision)
    if string(result.solver_revision) ~= expectedRevision
        error('run_inverse_validation:SolverRevision', ...
            'Expected %s, received %s.', expectedRevision, string(result.solver_revision));
    end
    if string(result.solve_status) ~= "ok" || string(result.sensor_status) ~= "ok"
        error('run_inverse_validation:SolveStatus', ...
            'Formal solve did not return solve_status=ok and sensor_status=ok.');
    end
    values = [result.wCenter_mm, result.electric_span, result.magnetic_span, ...
        result.mechanical_thermal_relative_residual, result.sensor_relative_residual, ...
        result.mechanical_thermal_rcond_estimate, result.sensor_rcond_estimate];
    if any(~isfinite(values))
        error('run_inverse_validation:NonFinite', 'Formal inverse result contains NaN or Inf.');
    end
    if result.mechanical_thermal_relative_residual > 1e-8 || ...
            result.sensor_relative_residual > 1e-8
        error('run_inverse_validation:Residual', ...
            'Formal inverse result exceeds the 1e-8 MATLAB residual gate.');
    end
end

function digest = sha256_file(path)
    engine = java.security.MessageDigest.getInstance('SHA-256');
    fileId = fopen(path, 'rb');
    if fileId < 0
        error('run_inverse_validation:HashOpen', 'Cannot open %s for hashing.', path);
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
