%% run_phase1_generate_cases  Phase-1 pilot input files (FG + Vf cross terms)
clear; clc;
paths = setup_paths();

template = fullfile(paths.templates, 'Thermal_CFFFplate_30x30_10layer_template.txt');
if ~isfile(template)
    error('Template missing: %s', template);
end

% Pilot: 3 FG modes x 3 volume fractions (expand to full 5x9 in phase 2)
fgModes = {'U', 'X', 'V'};
vfList = [0.3, 0.5, 0.7];
h = 6e-3;
nLayer = 10;

rows = {};
for im = 1:numel(fgModes)
    for iv = 1:numel(vfList)
        vf0 = vfList(iv);
        mode = fgModes{im};
        name = sprintf('Thermal_CFFF_%s_Vf%.1f-30x30-10layer.txt', mode, vf0);
        outPath = fullfile(paths.cases, name);
        generate_fg_thermal_input(struct( ...
            'templatePath', template, ...
            'outPath', outPath, ...
            'vf0', vf0, ...
            'fgMode', mode, ...
            'nLayer', nLayer, ...
            'h', h));
        rows(end+1, :) = {mode, vf0, outPath}; %#ok<AGROW>
        fprintf('Generated: %s\n', outPath);
    end
end

% Baseline: U + Vf0=0.6 should match Qian reference material level
refOut = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
generate_fg_thermal_input(struct( ...
    'templatePath', template, 'outPath', refOut, ...
    'vf0', 0.6, 'fgMode', 'U', 'nLayer', nLayer, 'h', h));
rows(end+1, :) = {'U', 0.6, refOut};

% Save manifest
manifest = fullfile(paths.cases, 'pilot_cases.csv');
fid = fopen(manifest, 'w');
fprintf(fid, 'fg_mode,vf0,input_file\n');
for i = 1:size(rows, 1)
    fprintf(fid, '%s,%.2f,%s\n', rows{i, 1}, rows{i, 2}, rows{i, 3});
end
fclose(fid);
fprintf('\nManifest: %s (%d cases)\n', manifest, size(rows, 1));
