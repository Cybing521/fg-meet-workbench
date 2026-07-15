clear;
root = fileparts(mfilename('fullpath'));
src = fullfile(root, 'outputs', 'manual-20260611-fgmeet', ...
    'electro-magneto-validation', 'qian_point3_cfff_plate_direct.mat');
out = fullfile(root, 'outputs', 'paper-20260715-fgmee', 'experiments', ...
    'inverse_sensing', 'qian_inverse_layer_means.csv');
data = load(src, 'SensM_T', 'SensM_E_zero_delta', 'SensM_M_zero_delta', ...
    'SensM_E_thermal_response', 'SensM_M_thermal_response');
nLayer = 10;
names = fieldnames(data);
values = zeros(nLayer, numel(names));
for j = 1:numel(names)
    vector = data.(names{j});
    for i = 1:nLayer
        values(i, j) = mean(vector(i:nLayer:end));
    end
end
T = array2table([(1:nLayer)', values], ...
    'VariableNames', [{'layer'}; names]);
writetable(T, out);
fprintf('EXPORTED_QIAN_INVERSE_LAYERS,%s\n', out);
