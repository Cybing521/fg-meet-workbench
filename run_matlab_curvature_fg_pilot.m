%% Curvature-by-gradient pilot: flat/R={1,0.4,0.3,0.2}, U/X, three loads.
clear; clc;
paths = setup_paths();

specs = struct('mode', {}, 'geometry', {}, 'radius_m', {}, 'case_file', {});
for mode = ["U", "X"]
    if mode == "U"
        flatFile = fullfile(paths.cases, 'validation_mesh', ...
            'Thermal_CFFF_U_Vf0.6-10x10-10layer.txt');
    else
        flatFile = fullfile(paths.cases, 'dynamic_10x10', ...
            'Thermal_CFFF_X_Vf0.6-10x10-10layer.txt');
    end
    specs(end+1) = make_spec(mode, "flat", Inf, flatFile); %#ok<SAGROW>
    for radius = [1.0, 0.4, 0.3, 0.2]
        filename = sprintf('Thermal_CFFF_%s_Vf0.6_R%gm-10x10-10layer.txt', mode, radius);
        caseFile = fullfile(paths.cases, 'curvature_fg', '10x10', filename);
        specs(end+1) = make_spec(mode, "cylinder", radius, caseFile); %#ok<SAGROW>
    end
end

rows = struct('mesh', {}, 'mode', {}, 'geometry', {}, 'radius_m', {}, ...
    'curvature_1pm', {}, 'load_case', {}, 'load_value', {}, 'load_unit', {}, ...
    'w_center_mm', {}, 'electric_span', {}, 'magnetic_span', {}, ...
    'theta_span_K', {}, 'center_node_id', {}, 'center_coord_1', {}, ...
    'center_coord_2', {}, 'center_coord_3', {}, 'case_file', {}, ...
    'solver_revision', {}, 'solve_status', {}, 'sensor_status', {}, ...
    'mechanical_thermal_relative_residual', {}, 'sensor_relative_residual', {}, ...
    'status', {});

for i = 1:numel(specs)
    spec = specs(i);
    if ~isfile(spec.case_file)
        error('run_matlab_curvature_fg_pilot:MissingCase', ...
            'Missing case: %s', spec.case_file);
    end
    baseTag = sprintf('curv10_%s_R%s', spec.mode, radius_tag(spec.radius_m));
    elastic = run_meet_static(spec.case_file, 'elastic', ...
        'LoadScale', -15000, 'OutTag', [baseTag '_elastic'], ...
        'SolveSensors', true, 'UseCache', true);
    electro = run_meet_static(spec.case_file, 'electro', ...
        'Volt', 300, 'OutTag', [baseTag '_electro'], ...
        'SolveSensors', true, 'UseCache', true);
    magneto = run_meet_static(spec.case_file, 'magneto', ...
        'Magnetic', 200, 'OutTag', [baseTag '_magneto'], ...
        'SolveSensors', true, 'UseCache', true);

    assert_formal_meet_evidence(elastic, [baseTag '_elastic']);
    assert_formal_meet_evidence(electro, [baseTag '_electro']);
    assert_formal_meet_evidence(magneto, [baseTag '_magneto']);

    rows(end+1) = make_row(spec, "elastic", -15000, "Pa", elastic); %#ok<SAGROW>
    rows(end+1) = make_row(spec, "electro", 300, "V", electro); %#ok<SAGROW>
    rows(end+1) = make_row(spec, "magneto", 200, "A", magneto); %#ok<SAGROW>
end

results = struct2table(rows);
results = add_flat_normalized(results);
interaction = build_interaction_table(results);

outDir = fullfile(paths.workbench, 'outputs', 'paper-20260715-fgmee', ...
    'experiments', 'curvature_fg');
if ~isfolder(outDir), mkdir(outDir); end
outCsv = fullfile(outDir, 'curvature_fg_pilot_10x10.csv');
outInteraction = fullfile(outDir, 'curvature_fg_interaction_10x10.csv');
outMat = fullfile(outDir, 'curvature_fg_pilot_10x10.mat');
writetable(results, outCsv);
writetable(interaction, outInteraction);
save(outMat, 'results', 'interaction');
fprintf('CURVATURE_FG_PILOT_COMPLETED,%s\n', outCsv);
disp(results(:, {'mode','radius_m','load_case','w_center_mm', ...
    'electric_span','magnetic_span','abs_w_ratio_to_flat'}));

function spec = make_spec(mode, geometry, radius, caseFile)
spec = struct('mode', string(mode), 'geometry', string(geometry), ...
    'radius_m', radius, 'case_file', string(caseFile));
end

function tag = radius_tag(radius)
if isinf(radius), tag = 'flat'; else, tag = strrep(sprintf('%.1f', radius), '.', 'p'); end
end

function row = make_row(spec, loadCase, loadValue, loadUnit, result)
if isinf(spec.radius_m), curvature = 0; else, curvature = 1/spec.radius_m; end
coord = result.centerCoord;
row = struct('mesh', 10, 'mode', spec.mode, 'geometry', spec.geometry, ...
    'radius_m', spec.radius_m, 'curvature_1pm', curvature, ...
    'load_case', string(loadCase), 'load_value', loadValue, ...
    'load_unit', string(loadUnit), 'w_center_mm', result.wCenter_mm, ...
    'electric_span', result.electric_span, 'magnetic_span', result.magnetic_span, ...
    'theta_span_K', result.theta_span_K, 'center_node_id', result.centerNodeId, ...
    'center_coord_1', coord(1), 'center_coord_2', coord(2), ...
    'center_coord_3', coord(3), 'case_file', string(spec.case_file), ...
    'solver_revision', string(result.solver_revision), ...
    'solve_status', string(result.solve_status), ...
    'sensor_status', string(result.sensor_status), ...
    'mechanical_thermal_relative_residual', ...
    result.mechanical_thermal_relative_residual, ...
    'sensor_relative_residual', result.sensor_relative_residual, ...
    'status', "completed_layer_local_pyro_v3");
end

function tbl = add_flat_normalized(tbl)
tbl.abs_w_ratio_to_flat = nan(height(tbl),1);
tbl.electric_ratio_to_flat = nan(height(tbl),1);
tbl.magnetic_ratio_to_flat = nan(height(tbl),1);
for mode = ["U", "X"]
    for loadCase = ["elastic", "electro", "magneto"]
        mask = tbl.mode == mode & tbl.load_case == loadCase;
        flat = mask & isinf(tbl.radius_m);
        w0 = abs(tbl.w_center_mm(flat));
        e0 = abs(tbl.electric_span(flat));
        m0 = abs(tbl.magnetic_span(flat));
        tbl.abs_w_ratio_to_flat(mask) = abs(tbl.w_center_mm(mask)) / max(w0, eps);
        tbl.electric_ratio_to_flat(mask) = abs(tbl.electric_span(mask)) / max(e0, eps);
        tbl.magnetic_ratio_to_flat(mask) = abs(tbl.magnetic_span(mask)) / max(m0, eps);
    end
end
end

function out = build_interaction_table(tbl)
out = table();
metrics = ["abs_w_ratio_to_flat", "electric_ratio_to_flat", "magnetic_ratio_to_flat"];
for loadCase = ["elastic", "electro", "magneto"]
    for radius = [1.0, 0.4, 0.3, 0.2]
        for metric = metrics
            u = tbl(tbl.mode == "U" & tbl.load_case == loadCase & tbl.radius_m == radius, :);
            x = tbl(tbl.mode == "X" & tbl.load_case == loadCase & tbl.radius_m == radius, :);
            uValue = u.(metric);
            xValue = x.(metric);
            interactionPctPoint = 100 * (xValue - uValue);
            row = table(loadCase, radius, 1/radius, metric, uValue, xValue, ...
                interactionPctPoint, "completed_pilot", ...
                'VariableNames', {'load_case','radius_m','curvature_1pm','metric', ...
                'U_ratio_to_flat','X_ratio_to_flat','gradient_curvature_interaction_pct_point', ...
                'status'});
            out = [out; row]; %#ok<AGROW>
        end
    end
end
end
