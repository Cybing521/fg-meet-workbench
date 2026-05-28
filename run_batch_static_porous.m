%% run_batch_static_porous  Porous FG-MEE static sweep (Phase 6).
%
%  Design space: 2 FG (U,X) × 5 e0 × 3 porosity modes × 5 Vf0 = 150 cases
%  Each case runs Case A/B/C → 450 rows total.
%
%  Usage:
%    cd('path/to/fg-meet-workbench');
%    setup_paths;
%    run('run_batch_static_porous.m');
%
%  Environment variables:
%    FG_POROUS_ROWS  - restrict to specific manifest rows (e.g. '1:10')
%    FG_POROUS_OUT   - output CSV name (default: results_static_porous.csv)

clear; clc;
paths = setup_paths();

%% Generate porous input files if manifest doesn't exist
manifest = fullfile(paths.cases, 'porous', 'manifest_porous.csv');
if ~isfile(manifest)
    generator = fullfile(paths.tools, 'generate_porous_cases.py');
    status = system(sprintf('python3 "%s"', generator));
    if status ~= 0
        status = system(sprintf('python "%s"', generator));
    end
    if status ~= 0
        error('run_batch_static_porous:GenerateFailed', ...
            'Cannot generate porous cases. Run tools/generate_porous_cases.py first.');
    end
end

%% Read manifest
T = readtable(manifest, 'TextType', 'string');
rowSpec = getenv('FG_POROUS_ROWS');
if ~isempty(rowSpec)
    rowIdx = parse_row_spec(rowSpec, height(T));
    T = T(rowIdx, :);
    fprintf('Restricting batch to manifest rows: %s (%d cases)\n', rowSpec, height(T));
end

%% Setup output
loadCases = {'elastic', 'electro', 'magneto'};
varNames = {'case_id', 'fg_mode', 'vf0', 'e0', 'porosity_name', 'porosity_mode', ...
    'load_case', 'input_file', ...
    'w_center_mm', 'theta_mean_K', 'theta_min_K', 'theta_max_K', ...
    'theta_span_K', 'magnetoelectric_efficiency', 'load_scale', ...
    'volt', 'magnetic', 'status', 'message', 'output_mat'};
rows = {};

outName = getenv('FG_POROUS_OUT');
if isempty(outName)
    outName = 'results_static_porous.csv';
end
outCsv = fullfile(paths.output, outName);

%% Resume from existing results
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
    e0 = T.e0(i);
    poroName = char(T.porosity_name(i));
    poroMode = T.porosity_mode(i);
    inputFile = char(T.input_file(i));
    caseFile = resolve_case_path(inputFile, paths.workbench);

    for j = 1:numel(loadCases)
        loadCase = loadCases{j};
        vfTag = sprintf('Vf%02d', round(vf0 * 100));
        e0Tag = sprintf('e%02d', round(e0 * 100));
        caseId = sprintf('%s_%s_%s_%s_%s', fgMode, vfTag, e0Tag, poroName, loadCase);
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
            rows(end+1, :) = {caseId, fgMode, vf0, e0, poroName, poroMode, ...
                loadCase, inputFile, ...
                r.wCenter_mm, r.theta_mean_K, r.theta_min_K, r.theta_max_K, ...
                r.theta_span_K, r.magnetoelectric_efficiency, r.loadScale, ...
                r.volt, r.magnetic, 'ok', '', r.output_mat}; %#ok<AGROW>
        catch ME
            warning('run_batch_static_porous:CaseFailed', '%s failed: %s', caseId, ME.message);
            rows(end+1, :) = {caseId, fgMode, vf0, e0, poroName, poroMode, ...
                loadCase, inputFile, ...
                NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
                'failed', ME.message, ''}; %#ok<AGROW>
        end

        write_results(outCsv, rows, varNames);
    end
end

write_results(outCsv, rows, varNames);
fprintf('\nDone. Wrote %s (%d rows)\n', outCsv, size(rows, 1));

%% --- Helper functions ---

function value = table_string(T, fieldName, rowIdx) %#ok<DEFNU>
    raw = T.(fieldName);
    if iscell(raw)
        value = char(raw{rowIdx});
    elseif isstring(raw)
        value = char(raw(rowIdx));
    else
        value = char(raw(rowIdx));
    end
end

function caseFile = resolve_case_path(inputFile, workbench)
    inputFile = char(inputFile);
    if ~isempty(regexp(inputFile, '^[A-Za-z]:[\\/]|^[/\\]', 'once'))
        caseFile = inputFile;
    else
        caseFile = fullfile(workbench, inputFile);
    end
    if ~isfile(caseFile) && isfile(inputFile)
        caseFile = inputFile;
    end
end

function write_results(outCsv, rows, varNames)
    if isempty(rows)
        return;
    end
    results = cell2table(rows, 'VariableNames', varNames);
    writetable(results, outCsv);
end

function rows = drop_case_rows(rows, caseId)
    if isempty(rows)
        return;
    end
    keep = true(size(rows, 1), 1);
    for i = 1:size(rows, 1)
        keep(i) = ~strcmp(char(rows{i, 1}), caseId);
    end
    rows = rows(keep, :);
end

function rowIdx = parse_row_spec(rowSpec, nRows)
    rowSpec = strtrim(char(rowSpec));
    if contains(rowSpec, ':')
        parts = strsplit(rowSpec, ':');
        first = str2double(parts{1});
        last = str2double(parts{2});
        rowIdx = first:last;
    else
        parts = strsplit(rowSpec, ',');
        rowIdx = str2double(parts);
    end
    if any(isnan(rowIdx)) || any(rowIdx < 1) || any(rowIdx > nRows)
        error('parse_row_spec:Bad', 'Bad FG_POROUS_ROWS: %s', rowSpec);
    end
    rowIdx = unique(round(rowIdx), 'stable');
end
