%% Batch pilot: all cases in pilot_cases.csv (Case A only)
clear; clc;
paths = setup_paths();

manifest = fullfile(paths.cases, 'pilot_cases.csv');
if ~isfile(manifest)
    run(fullfile(paths.workbench, 'run_phase1_generate_cases.m'));
end

T = readtable(manifest);
results = table();

for i = 1:height(T)
    rel = char(T.input_file{i});
    caseFile = fullfile(paths.workbench, rel);
    tag = sprintf('%s_Vf%.2f', T.fg_mode{i}, T.vf0(i));
    fprintf('\n=== %s ===\n', tag);
    try
        r = run_meet_static(caseFile, 'elastic', 'OutTag', tag);
        results = [results; table(string(T.fg_mode(i)), T.vf0(i), r.wCenter_mm, ...
            'VariableNames', {'fg_mode','vf0','w_center_mm'})]; %#ok<AGROW>
    catch ME
        warning('Failed %s: %s', tag, ME.message);
    end
end

outCsv = fullfile(paths.output, 'pilot_static_elastic.csv');
writetable(results, outCsv);
fprintf('\nWrote %s\n', outCsv);
