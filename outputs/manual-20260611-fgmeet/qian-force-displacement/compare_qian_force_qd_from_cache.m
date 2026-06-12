clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
repo_root = char(java.io.File(fullfile(script_dir, '..', '..', '..')).getCanonicalPath());

qian_direct_mat = fullfile(repo_root, 'outputs', 'manual-20260611-fgmeet', ...
    'electro-magneto-validation', 'qian_point3_cfff_plate_direct.mat');
qian_matrices_mat = fullfile(repo_root, 'outputs', 'manual-20260611-fgmeet', ...
    'electro-magneto-validation', 'qian_point3_cfff_plate_matrices.mat');
our_mat = fullfile(repo_root, 'output', 'static_elastic_U_Vf60_elastic.mat');
out_points_csv = fullfile(script_dir, 'qian_vs_our_force_15points_from_cache.csv');
out_summary_csv = fullfile(script_dir, 'qian_vs_our_force_qd_summary_from_cache.csv');

Q = load(qian_direct_mat, 'Qd', 'loadmax');
M = load(qian_matrices_mat, 'FinitElemInfo');
O = load(our_mat, 'Qd');

qian_qd = Q.Qd;
our_qd = O.Qd;
if numel(qian_qd) ~= numel(our_qd)
    error('Qd size mismatch: qian=%d our=%d', numel(qian_qd), numel(our_qd));
end

all_abs_diff = abs(qian_qd - our_qd);
max_abs_diff_m = max(all_abs_diff);
max_abs_qian_m = max(abs(qian_qd));
if max_abs_qian_m == 0
    max_rel_diff_pct = NaN;
else
    max_rel_diff_pct = max_abs_diff_m / max_abs_qian_m * 100;
end
mean_abs_diff_m = mean(all_abs_diff);

Tqian = restore_mechanical_dof(M.FinitElemInfo.Node, qian_qd);
Tour = restore_mechanical_dof(M.FinitElemInfo.Node, our_qd);

point_id = string({'p1'; 'p2'; 'p3'; 'p4'; 'p5'; ...
    'p6'; 'p7'; 'p8'; 'p9'; 'p10'; ...
    'p11'; 'p12'; 'p13'; 'p14'; 'p15'});
x_m = [0.05; 0.10; 0.15; 0.20; 0.25; ...
       0.05; 0.10; 0.15; 0.20; 0.25; ...
       0.05; 0.10; 0.15; 0.20; 0.25];
y_m = [0.05; 0.05; 0.05; 0.05; 0.05; ...
       0.15; 0.15; 0.15; 0.15; 0.15; ...
       0.25; 0.25; 0.25; 0.25; 0.25];

node_id = zeros(numel(x_m), 1);
node_x_m = zeros(numel(x_m), 1);
node_y_m = zeros(numel(x_m), 1);
qian_w_mm = zeros(numel(x_m), 1);
our_w_mm = zeros(numel(x_m), 1);
abs_diff_mm = zeros(numel(x_m), 1);
rel_diff_pct = zeros(numel(x_m), 1);

for i = 1:numel(x_m)
    idx = find_nearest_node(M.FinitElemInfo.Node, [x_m(i), y_m(i), 0]);
    full_dof = 5 * (idx - 1) + 3;
    node_id(i) = M.FinitElemInfo.Node(idx, 1);
    node_x_m(i) = M.FinitElemInfo.Node(idx, 2);
    node_y_m(i) = M.FinitElemInfo.Node(idx, 3);
    qian_w_mm(i) = 1000 * Tqian(full_dof);
    our_w_mm(i) = 1000 * Tour(full_dof);
    abs_diff_mm(i) = abs(qian_w_mm(i) - our_w_mm(i));
    if qian_w_mm(i) == 0
        rel_diff_pct(i) = NaN;
    else
        rel_diff_pct(i) = abs_diff_mm(i) / abs(qian_w_mm(i)) * 100;
    end
end

points = table(point_id, x_m, y_m, node_id, node_x_m, node_y_m, ...
    qian_w_mm, our_w_mm, abs_diff_mm, rel_diff_pct);
writetable(points, out_points_csv);

summary = table( ...
    string("qian_code_qd_vs_our_static_elastic_U_Vf60"), ...
    numel(qian_qd), Q.loadmax, max_abs_diff_m, max_rel_diff_pct, ...
    mean_abs_diff_m, max(abs_diff_mm), max(rel_diff_pct), ...
    string(qian_direct_mat), string(our_mat), ...
    'VariableNames', {'comparison', 'num_reduced_dof', 'loadmax', ...
    'max_abs_diff_all_dof_m', 'max_rel_diff_all_dof_pct', ...
    'mean_abs_diff_all_dof_m', 'max_abs_diff_15points_mm', ...
    'max_rel_diff_15points_pct', 'qian_source', 'our_source'});
writetable(summary, out_summary_csv);

fprintf('max_abs_diff_all_dof_m=%.15g\n', max_abs_diff_m);
fprintf('max_rel_diff_all_dof_pct=%.15g\n', max_rel_diff_pct);
fprintf('max_abs_diff_15points_mm=%.15g\n', max(abs_diff_mm));
fprintf('max_rel_diff_15points_pct=%.15g\n', max(rel_diff_pct));
fprintf('wrote_points=%s\n', out_points_csv);
fprintf('wrote_summary=%s\n', out_summary_csv);

function tQd = restore_mechanical_dof(node, qd)
dof_per_node = 5;
dof_flag_start = 5;
num_node = size(node, 1);
tQd = zeros(num_node * dof_per_node, 1);
q_index = 1;
for node_index = 1:num_node
    for dof_index = 1:dof_per_node
        full_index = (node_index - 1) * dof_per_node + dof_index;
        if node(node_index, dof_flag_start + dof_index - 1) == 0
            tQd(full_index) = qd(q_index);
            q_index = q_index + 1;
        end
    end
end
if q_index - 1 ~= numel(qd)
    error('restore:dofMismatch', 'Restored %d DOFs, qd has %d.', q_index - 1, numel(qd));
end
end

function node_index = find_nearest_node(node, target_coord)
diff = node(:, 2:4) - target_coord;
[~, node_index] = min(sum(diff .^ 2, 2));
end
