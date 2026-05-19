%% Phase-1 smoke test: CFFF plate, uniform FG (U), Vf0=0.6, mechanical load
clear; clc;
paths = setup_paths();

caseFile = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
if ~isfile(caseFile)
    system(sprintf('python3 "%s"', fullfile(paths.tools, 'generate_cases.py')));
end

result = run_meet_static(caseFile, 'elastic', 'OutTag', 'phase1_U_Vf06');
