%% run_batch_static  Full 5x9 FG-MEE static sweep for Case A/B/C.
clear; clc;
paths = setup_paths();

manifest = fullfile(paths.cases, 'manifest_full.csv');
if ~isfile(manifest)
    generator = fullfile(paths.tools, 'generate_cases.py');
    status = system(sprintf('python3 "%s"', generator));
    if status ~= 0
        status = system(sprintf('python "%s"', generator));
    end
    if status ~= 0
        error('run_batch_static:GenerateCasesFailed', ...
            'Cannot generate %s. Run tools/generate_cases.py first.', manifest);
    end
end

T = readtable(manifest);
rowSpec = getenv('FG_BATCH_ROWS');
if ~isempty(rowSpec)
    rowIdx = parse_row_spec(rowSpec, height(T));
    T = T(rowIdx, :);
    fprintf('Restricting batch to manifest rows: %s (%d cases)\n', rowSpec, height(T));
end
loadCases = {'elastic', 'electro', 'magneto'};
varNames = {'case_id', 'fg_mode', 'vf0', 'load_case', 'input_file', ...
    'w_center_mm', 'theta_mean_K', 'theta_min_K', 'theta_max_K', ...
    'theta_span_K', 'magnetoelectric_efficiency', 'load_scale', ...
    'volt', 'magnetic', 'status', 'message', 'output_mat'};
rows = {};

outName = getenv('FG_BATCH_OUT');
if isempty(outName)
    outName = 'results_static.csv';
end
outCsv = fullfile(paths.output, outName);
completed = containers.Map('KeyType', 'char', 'ValueType', 'logical');
if isfile(outCsv)
    existing = readtable(outCsv, 'TextType', 'string');
    rows = table2cell(existing);
    rows = normalize_existing_rows(rows, paths.output);
    for ii = 1:height(existing)
        if strcmp(char(existing.status(ii)), 'ok')
            completed(char(existing.case_id(ii))) = true;
        end
    end
    fprintf('Loaded %d existing rows from %s\n', height(existing), outCsv);
end

for i = 1:height(T)
    fgMode = table_string(T, 'fg_mode', i);
    vf0 = T.vf0(i);
    inputFile = table_string(T, 'input_file', i);
    caseFile = resolve_case_path(inputFile, paths.workbench);

    for j = 1:numel(loadCases)
        loadCase = loadCases{j};
        vfTag = sprintf('Vf%02d', round(vf0 * 100));
        caseId = sprintf('%s_%s_%s', fgMode, vfTag, loadCase);
        if isKey(completed, caseId)
            fprintf('\n=== %s (skip existing ok) ===\n', caseId);
            continue;
        end
        rows = drop_case_rows(rows, caseId);
        fprintf('\n=== %s ===\n', caseId);

        try
            solveSensors = strcmp(loadCase, 'magneto');
            r = run_meet_static(caseFile, loadCase, ...
                'OutTag', caseId, 'SolveSensors', solveSensors);
            rows(end+1, :) = {caseId, fgMode, vf0, loadCase, inputFile, ...
                r.wCenter_mm, r.theta_mean_K, r.theta_min_K, r.theta_max_K, ...
                r.theta_span_K, r.magnetoelectric_efficiency, r.loadScale, ...
                r.volt, r.magnetic, 'ok', '', r.output_mat}; %#ok<AGROW>
        catch ME
            warning('run_batch_static:CaseFailed', '%s failed: %s', caseId, ME.message);
            rows(end+1, :) = {caseId, fgMode, vf0, loadCase, inputFile, ...
                NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
                'failed', ME.message, ''}; %#ok<AGROW>
        end

        write_results(outCsv, rows, varNames);
    end
end

write_results(outCsv, rows, varNames);
fprintf('\nWrote %s (%d rows)\n', outCsv, size(rows, 1));

function value = table_string(T, fieldName, rowIdx)
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

function rows = normalize_existing_rows(rows, outputDir)
    if isempty(rows)
        return;
    end
    for i = 1:size(rows, 1)
        status = cell_text(rows{i, 15});
        outputMat = cell_text(rows{i, 17});
        if ~strcmp(status, 'ok') || (~isempty(outputMat) && ~strcmpi(outputMat, 'NaN'))
            continue;
        end
        loadCase = lower(cell_text(rows{i, 4}));
        caseId = cell_text(rows{i, 1});
        candidate = fullfile(outputDir, sprintf('static_%s_%s.mat', loadCase, caseId));
        if isfile(candidate)
            rows{i, 17} = candidate;
        end
    end
end

function text = cell_text(value)
    if isstring(value)
        if ismissing(value)
            text = '';
        else
            text = char(value);
        end
    elseif ischar(value)
        text = value;
    elseif isnumeric(value) && isscalar(value) && isnan(value)
        text = 'NaN';
    else
        text = char(string(value));
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
        if numel(parts) ~= 2
            error('run_batch_static:BadRowSpec', 'Bad FG_BATCH_ROWS: %s', rowSpec);
        end
        first = str2double(parts{1});
        last = str2double(parts{2});
        rowIdx = first:last;
    else
        parts = strsplit(rowSpec, ',');
        rowIdx = str2double(parts);
    end
    if any(isnan(rowIdx)) || any(rowIdx < 1) || any(rowIdx > nRows)
        error('run_batch_static:BadRowSpec', 'Bad FG_BATCH_ROWS: %s', rowSpec);
    end
    rowIdx = unique(round(rowIdx), 'stable');
end
