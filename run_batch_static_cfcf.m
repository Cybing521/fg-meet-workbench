%% run_batch_static_cfcf  CFCF boundary condition static sweep.
%
%  Design space: 2 FG (U,X) × 5 Vf0 = 10 cases × 3 loads = 30 rows.
%
%  Usage:
%    cd('path/to/fg-meet-workbench');
%    setup_paths;
%    run('run_batch_static_cfcf.m');

clear; clc;
paths = setup_paths();

%% Generate CFCF input files if manifest doesn't exist
manifest = fullfile(paths.workbench, 'cases', 'cfcf', 'manifest_cfcf.csv');
if ~isfile(manifest)
    generator = fullfile(paths.tools, 'generate_cfcf_cases.py');
    status = system(sprintf('python3 "%s"', generator));
    if status ~= 0
        status = system(sprintf('python "%s"', generator));
    end
    if status ~= 0
        error('run_batch_static_cfcf:GenerateFailed', ...
            'Cannot generate CFCF cases. Run tools/generate_cfcf_cases.py first.');
    end
end

%% Read manifest
T = readtable(manifest, 'TextType', 'string');
fprintf('CFCF batch: %d cases\n', height(T));

%% Setup output
loadCases = {'elastic', 'electro', 'magneto'};
varNames = {'case_id', 'fg_mode', 'vf0', 'load_case', 'input_file', ...
    'w_center_mm', 'theta_mean_K', 'theta_min_K', 'theta_max_K', ...
    'theta_span_K', 'magnetoelectric_efficiency', 'load_scale', ...
    'volt', 'magnetic', 'status', 'message', 'output_mat'};
rows = {};

outCsv = fullfile(paths.output, 'results_static_cfcf.csv');
completed = containers.Map('KeyType', 'char', 'ValueType', 'logical');
if isfile(outCsv)
    existing = readtable(outCsv, 'TextType', 'string');
    rows = table2cell(existing);
    for ii = 1:height(existing)
        if strcmp(char(existing.status(ii)), 'ok')
            completed(char(existing.case_id(ii))) = true;
        end
    end
    fprintf('Loaded %d existing rows from %s\n', height(existing), outCsv);
end

%% Main loop
for i = 1:height(T)
    fgMode = char(T.fg_mode(i));
    vf0 = T.vf0(i);
    inputFile = char(T.input_file(i));
    caseFile = fullfile(paths.workbench, inputFile);
    if ~isfile(caseFile)
        caseFile = inputFile;
    end

    for j = 1:numel(loadCases)
        loadCase = loadCases{j};
        vfTag = sprintf('Vf%02d', round(vf0 * 100));
        caseId = sprintf('CFCF_%s_%s_%s', fgMode, vfTag, loadCase);
        if isKey(completed, caseId)
            fprintf('\n=== %s (skip existing ok) ===\n', caseId);
            continue;
        end
        rows = drop_case_rows(rows, caseId);
        fprintf('\n=== [%d/%d] %s ===\n', i, height(T), caseId);

        try
            solveSensors = strcmp(loadCase, 'magneto');
            r = run_meet_static(caseFile, loadCase, ...
                'OutTag', caseId, 'SolveSensors', solveSensors);
            rows(end+1, :) = {caseId, fgMode, vf0, loadCase, inputFile, ...
                r.wCenter_mm, r.theta_mean_K, r.theta_min_K, r.theta_max_K, ...
                r.theta_span_K, r.magnetoelectric_efficiency, r.loadScale, ...
                r.volt, r.magnetic, 'ok', '', r.output_mat}; %#ok<AGROW>
        catch ME
            warning('run_batch_static_cfcf:CaseFailed', '%s failed: %s', caseId, ME.message);
            rows(end+1, :) = {caseId, fgMode, vf0, loadCase, inputFile, ...
                NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
                'failed', ME.message, ''}; %#ok<AGROW>
        end

        write_results(outCsv, rows, varNames);
    end
end

write_results(outCsv, rows, varNames);
fprintf('\nDone. Wrote %s (%d rows)\n', outCsv, size(rows, 1));

%% --- Helper functions ---

function write_results(outCsv, rows, varNames)
    if isempty(rows), return; end
    results = cell2table(rows, 'VariableNames', varNames);
    writetable(results, outCsv);
end

function rows = drop_case_rows(rows, caseId)
    if isempty(rows), return; end
    keep = true(size(rows, 1), 1);
    for i = 1:size(rows, 1)
        keep(i) = ~strcmp(char(rows{i, 1}), caseId);
    end
    rows = rows(keep, :);
end
