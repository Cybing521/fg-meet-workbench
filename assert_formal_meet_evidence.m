function assert_formal_meet_evidence(value, context)
%ASSERT_FORMAL_MEET_EVIDENCE Reject stale or numerically invalid formal results.

    expectedRevision = "layer_local_pyro_v3";
    residualGate = 1e-8;
    required = {'solver_revision', 'solve_status', 'sensor_status', ...
        'mechanical_thermal_relative_residual', 'sensor_relative_residual'};

    if nargin < 2 || strlength(string(context)) == 0
        context = "formal MATLAB result";
    else
        context = string(context);
    end

    if istable(value)
        missing = setdiff(required, value.Properties.VariableNames, 'stable');
        if ~isempty(missing)
            error('assert_formal_meet_evidence:MissingField', ...
                '%s is missing formal evidence field(s): %s.', ...
                context, strjoin(missing, ', '));
        end
        revisions = string(value.solver_revision);
        solveStatus = string(value.solve_status);
        sensorStatus = string(value.sensor_status);
        mechanicalResidual = value.mechanical_thermal_relative_residual;
        sensorResidual = value.sensor_relative_residual;
    elseif isstruct(value)
        missing = required(~isfield(value, required));
        if ~isempty(missing)
            error('assert_formal_meet_evidence:MissingField', ...
                '%s is missing formal evidence field(s): %s.', ...
                context, strjoin(missing, ', '));
        end
        revisions = string({value.solver_revision}).';
        solveStatus = string({value.solve_status}).';
        sensorStatus = string({value.sensor_status}).';
        mechanicalResidual = [value.mechanical_thermal_relative_residual].';
        sensorResidual = [value.sensor_relative_residual].';
    else
        error('assert_formal_meet_evidence:UnsupportedType', ...
            '%s must be a result struct or table.', context);
    end

    if isempty(revisions)
        error('assert_formal_meet_evidence:EmptyEvidence', ...
            '%s contains no result rows.', context);
    end
    if any(revisions ~= expectedRevision)
        error('assert_formal_meet_evidence:SolverRevisionMismatch', ...
            '%s must use solver_revision=%s.', context, expectedRevision);
    end
    if any(solveStatus ~= "ok") || any(sensorStatus ~= "ok")
        error('assert_formal_meet_evidence:IncompleteSolve', ...
            '%s must have solve_status=ok and sensor_status=ok.', context);
    end

    residuals = [mechanicalResidual(:); sensorResidual(:)];
    if any(~isfinite(residuals)) || any(residuals < 0) || any(residuals > residualGate)
        error('assert_formal_meet_evidence:ResidualGateFailed', ...
            '%s has a nonfinite, negative, or > %.1e relative residual.', ...
            context, residualGate);
    end
end
