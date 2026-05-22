%% run_coupling_validation_2mm
% Validate electric/magnetic actuation and Shen-style inverse sensing at a
% 2 mm reference center deflection using the bundled linear MEET solver.
%
% Optional environment overrides:
%   FG_VALIDATE_CASE          input case file, default U/Vf0=0.6
%   FG_VALIDATE_TARGET_MM     reference absolute deflection, default 2
%   FG_VALIDATE_PROBE_VOLT    probe electric potential, default 300
%   FG_VALIDATE_PROBE_MAGNETIC probe magnetic potential, default 200
%   FG_VALIDATE_PROBE_LOAD    probe mechanical load scale, default -15000
%   FG_VALIDATE_REL_TOL       relative tolerance for reference checks, default 0.05

clear; clc;
paths = setup_paths();

targetAbsMm = env_number('FG_VALIDATE_TARGET_MM', 2);
probeVolt = env_number('FG_VALIDATE_PROBE_VOLT', 300);
probeMagnetic = env_number('FG_VALIDATE_PROBE_MAGNETIC', 200);
probeLoad = env_number('FG_VALIDATE_PROBE_LOAD', -15000);
relTol = env_number('FG_VALIDATE_REL_TOL', 0.05);
absTolMm = env_number('FG_VALIDATE_ABS_TOL_MM', 1e-6);

caseFile = getenv('FG_VALIDATE_CASE');
if isempty(caseFile)
    caseFile = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
else
    caseFile = resolve_case_path(caseFile, paths.workbench);
end
if ~isfile(caseFile)
    error('run_coupling_validation_2mm:NoInput', 'Input file not found: %s', caseFile);
end

[~, caseTag, ~] = fileparts(caseFile);
tagPrefix = sprintf('coupling_2mm_%s', sanitize_tag(caseTag));

fprintf('Coupling validation case: %s\n', caseFile);
fprintf('Reference center deflection: %.6g mm\n', targetAbsMm);

elasticProbe = run_meet_static(caseFile, 'elastic', ...
    'LoadScale', probeLoad, 'OutTag', [tagPrefix '_probe_elastic'], ...
    'SolveSensors', true);
electroProbe = run_meet_static(caseFile, 'electro', ...
    'Volt', probeVolt, 'OutTag', [tagPrefix '_probe_electro'], ...
    'SolveSensors', true);
magnetoProbe = run_meet_static(caseFile, 'magneto', ...
    'Magnetic', probeMagnetic, 'OutTag', [tagPrefix '_probe_magneto'], ...
    'SolveSensors', true);

targetLoad = scale_to_target(probeLoad, elasticProbe.wCenter_mm, targetAbsMm, 'mechanical load');
targetVolt = scale_to_target(probeVolt, electroProbe.wCenter_mm, targetAbsMm, 'electric potential');
targetMagnetic = scale_to_target(probeMagnetic, magnetoProbe.wCenter_mm, targetAbsMm, 'magnetic potential');

elasticTarget = run_meet_static(caseFile, 'elastic', ...
    'LoadScale', targetLoad, 'OutTag', [tagPrefix '_target_elastic'], ...
    'SolveSensors', true);
electroTarget = run_meet_static(caseFile, 'electro', ...
    'Volt', targetVolt, 'OutTag', [tagPrefix '_target_electro'], ...
    'SolveSensors', true);
magnetoTarget = run_meet_static(caseFile, 'magneto', ...
    'Magnetic', targetMagnetic, 'OutTag', [tagPrefix '_target_magneto'], ...
    'SolveSensors', true);

rows(1) = make_row('E_to_w', ...
    'electric potential to 2 mm deflection', 'forward_2mm', ...
    'electric_potential', targetVolt, 'V', electroTarget, NaN, NaN, ...
    NaN, '', targetAbsMm, absTolMm, relTol, false, ...
    'forward actuation check');
rows(end+1) = make_row('M_to_w', ...
    'magnetic potential to 2 mm deflection', 'forward_2mm', ...
    'magnetic_potential', targetMagnetic, 'A', magnetoTarget, NaN, NaN, ...
    NaN, '', targetAbsMm, absTolMm, relTol, false, ...
    'forward actuation check');
rows(end+1) = make_row('w_to_E', ...
    '2 mm deflection to electric potential', 'shen_sensor_mechanical_2mm', ...
    'mechanical_load', targetLoad, 'load_scale', elasticTarget, ...
    elasticTarget.electric_span, NaN, elasticTarget.electric_span / targetAbsMm, ...
    'electric_span/mm', targetAbsMm, absTolMm, relTol, true, ...
    'Shen sensor equation: [Kff,Kfz;Kzf,Kzz]\\[-Kfu*u-Kft*T;-Kzu*u-Kzt*T]');
rows(end+1) = make_row('w_to_M', ...
    '2 mm deflection to magnetic potential', 'shen_sensor_mechanical_2mm', ...
    'mechanical_load', targetLoad, 'load_scale', elasticTarget, ...
    elasticTarget.magnetic_span, NaN, elasticTarget.magnetic_span / targetAbsMm, ...
    'magnetic_span/mm', targetAbsMm, absTolMm, relTol, true, ...
    'Shen sensor equation: [Kff,Kfz;Kzf,Kzz]\\[-Kfu*u-Kft*T;-Kzu*u-Kzt*T]');
rows(end+1) = make_row('M_to_w_to_E', ...
    'magnetic potential to deflection to induced electric potential', ...
    'shen_direct_matrix', 'magnetic_potential', targetMagnetic, 'A', ...
    magnetoTarget, magnetoTarget.electric_span, NaN, ...
    magnetoTarget.electric_span / (2 * abs(targetMagnetic)), ...
    'electric_span/(2*magnetic)', targetAbsMm, absTolMm, relTol, true, ...
    sprintf('Direct Shen M->u->E conversion; mechanical 2 mm E span %.15g is not used as pass/fail reference', elasticTarget.electric_span));
rows(end+1) = make_row('E_to_w_to_M', ...
    'electric potential to deflection to induced magnetic potential', ...
    'shen_direct_matrix', 'electric_potential', targetVolt, 'V', ...
    electroTarget, electroTarget.magnetic_span, NaN, ...
    electroTarget.magnetic_span / (2 * abs(targetVolt)), ...
    'magnetic_span/(2*V)', targetAbsMm, absTolMm, relTol, true, ...
    sprintf('Direct Shen E->u->M conversion; mechanical 2 mm M span %.15g is not used as pass/fail reference', elasticTarget.magnetic_span));

results = struct2table(rows);
outCsv = fullfile(paths.output, 'coupling_validation_2mm.csv');
outMat = fullfile(paths.output, 'coupling_validation_2mm.mat');
writetable(results, outCsv);

summary = struct();
summary.caseFile = caseFile;
summary.targetAbsMm = targetAbsMm;
summary.probeLoad = probeLoad;
summary.probeVolt = probeVolt;
summary.probeMagnetic = probeMagnetic;
summary.targetLoad = targetLoad;
summary.targetVolt = targetVolt;
summary.targetMagnetic = targetMagnetic;
summary.relTol = relTol;
summary.absTolMm = absTolMm;
summary.elasticProbe = elasticProbe;
summary.electroProbe = electroProbe;
summary.magnetoProbe = magnetoProbe;
summary.elasticTarget = elasticTarget;
summary.electroTarget = electroTarget;
summary.magnetoTarget = magnetoTarget;
save(outMat, 'summary', 'results');

fprintf('\nWrote %s\n', outCsv);
fprintf('Wrote %s\n', outMat);
disp(results(:, {'check_id', 'driver_value', 'w_center_mm', ...
    'generated_value', 'transfer_coefficient', 'status'}));

function value = env_number(name, defaultValue)
    raw = getenv(name);
    if isempty(raw)
        value = defaultValue;
        return;
    end
    value = str2double(raw);
    if isnan(value)
        error('run_coupling_validation_2mm:BadEnv', ...
            '%s must be numeric, got: %s', name, raw);
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

function tag = sanitize_tag(raw)
    tag = regexprep(raw, '[^A-Za-z0-9_]+', '_');
end

function driver = scale_to_target(probeDriver, probeWmm, targetAbsMm, label)
    if abs(probeWmm) < eps
        error('run_coupling_validation_2mm:ZeroProbe', ...
            'Cannot scale %s because probe deflection is zero.', label);
    end
    driver = probeDriver * targetAbsMm / abs(probeWmm);
end

function row = make_row(checkId, description, method, driverKind, driverValue, driverUnit, ...
    result, generatedValue, referenceValue, transferCoefficient, transferUnit, ...
    targetAbsMm, absTolMm, relTol, requireGeneratedValue, notes)

    wAbsError = abs(abs(result.wCenter_mm) - targetAbsMm);
    relErr = relative_error(generatedValue, referenceValue);
    if isnan(referenceValue)
        ok = wAbsError <= absTolMm;
        if requireGeneratedValue
            ok = ok && isfinite(generatedValue) && isfinite(transferCoefficient);
        end
        status = pass_fail(ok);
    else
        status = pass_fail((wAbsError <= absTolMm) && (relErr <= relTol));
    end

    row = struct();
    row.check_id = string(checkId);
    row.description = string(description);
    row.method = string(method);
    row.driver_kind = string(driverKind);
    row.driver_value = driverValue;
    row.driver_unit = string(driverUnit);
    row.target_abs_w_mm = targetAbsMm;
    row.w_center_mm = result.wCenter_mm;
    row.w_abs_error_mm = wAbsError;
    row.electric_span = result.electric_span;
    row.magnetic_span = result.magnetic_span;
    row.generated_value = generatedValue;
    row.reference_value = referenceValue;
    row.relative_error = relErr;
    row.transfer_coefficient = transferCoefficient;
    row.transfer_unit = string(transferUnit);
    row.status = status;
    row.output_mat = string(result.output_mat);
    row.notes = string(notes);
end

function err = relative_error(value, reference)
    if isnan(reference)
        err = NaN;
    else
        denom = max(abs(reference), eps);
        err = abs(value - reference) / denom;
    end
end

function status = pass_fail(ok)
    if ok
        status = "pass";
    else
        status = "review";
    end
end
