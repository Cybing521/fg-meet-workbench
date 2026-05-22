%% Phase-1 smoke test: CFFF plate, uniform FG (U), Vf0=0.6, mechanical load
clear; clc;
paths = setup_paths();

caseFile = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
if ~isfile(caseFile)
    system(sprintf('python3 "%s"', fullfile(paths.tools, 'generate_cases.py')));
end

result = run_meet_static(caseFile, 'elastic', 'OutTag', 'phase1_U_Vf06');

thetaNames = arrayfun(@(k) sprintf('theta_layer_%02d_K', k), ...
    1:numel(result.theta_layers), 'UniformOutput', false);
summary = table(string(result.inputFile), result.wCenter_mm, ...
    result.theta_mean_K, result.theta_span_K, ...
    'VariableNames', {'input_file', 'w_center_mm', 'theta_mean_K', 'theta_span_K'});
for k = 1:numel(thetaNames)
    summary.(thetaNames{k}) = result.theta_layers(k);
end

summaryPath = fullfile(paths.output, 'phase1_static_elastic_summary.csv');
writetable(summary, summaryPath);
fprintf('Wrote %s\n', summaryPath);
