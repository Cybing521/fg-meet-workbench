[CmdletBinding()]
param(
    [ValidateSet('isomorphic-electric', 'isomorphic-magnetic', 'curved', 'inverse')]
    [string]$Target = 'curved',
    [switch]$CompileOnly
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Join-Path $Root 'code\comsol'
$OutputDir = Join-Path $Root 'results\recomputed\comsol'
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$BinCandidates = @(
    @(
        $env:FGMEE_COMSOL_BIN,
        'D:\comsol\COMSOL60\Multiphysics\bin\win64',
        'C:\Program Files\COMSOL\COMSOL60\Multiphysics\bin\win64',
        'C:\Program Files\COMSOL\COMSOL61\Multiphysics\bin\win64',
        'C:\Program Files\COMSOL\COMSOL62\Multiphysics\bin\win64'
    ) | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'comsolcompile.exe')) }
)
if (-not $BinCandidates) {
    throw 'COMSOL was not found. Set FGMEE_COMSOL_BIN to its bin\win64 directory.'
}
$ComsolBin = $BinCandidates[0]
$Compiler = Join-Path $ComsolBin 'comsolcompile.exe'
$Batch = Join-Path $ComsolBin 'comsolbatch.exe'

$Config = switch ($Target) {
    'isomorphic-electric' {
        @{
            Class = 'RunIsomorphicSolidCfffValidation'
            Env = @{
                FG_ISO_OUTPUT_DIR = $OutputDir; FG_ISO_INPLANE_DIVISIONS = '20'
                FG_ISO_THICKNESS_PER_LAYER = '1'; FG_ISO_LOAD_CASE = 'electric_equivalent_stress'
                FG_ISO_BOTTOM_STRESS_PA = '4934000'; FG_ISO_TOP_STRESS_PA = '-4934000'
                FG_ISO_RUN_TAG = 'electric_equivalent_stress_20x'
            }
            Output = 'isomorphic_electric_20x.mph'
        }
    }
    'isomorphic-magnetic' {
        @{
            Class = 'RunIsomorphicSolidCfffValidation'
            Env = @{
                FG_ISO_OUTPUT_DIR = $OutputDir; FG_ISO_INPLANE_DIVISIONS = '20'
                FG_ISO_THICKNESS_PER_LAYER = '1'; FG_ISO_LOAD_CASE = 'magnetic_external_stress'
                FG_ISO_BOTTOM_STRESS_PA = '-16490000'; FG_ISO_TOP_STRESS_PA = '16490000'
                FG_ISO_RUN_TAG = 'magnetic_external_stress_20x'
            }
            Output = 'isomorphic_magnetic_20x.mph'
        }
    }
    'curved' {
        @{
            Class = 'RunCurvedSolidCfffValidation'
            Env = @{
                FG_CURVED_OUTPUT_DIR = $OutputDir; FG_CURVED_RADIUS_M = '0.4'
                FG_CURVED_PRESSURE_PA = '15000'; FG_CURVED_AXIAL_DIVISIONS = '20'
                FG_CURVED_CIRC_DIVISIONS = '20'; FG_CURVED_THICKNESS_DIVISIONS = '10'
                FG_CURVED_RUN_TAG = 'U_R0p4_20x20x10'
            }
            Output = 'curved_U_R0p4_20x20x10.mph'
        }
    }
    'inverse' {
        @{
            Class = 'RunBlockTriangularInverseSensorCfffValidation'
            Env = @{
                FG_FOUR_FIELD_OUTPUT_DIR = $OutputDir; FG_FOUR_FIELD_PROBE_PRESSURE_PA = '15000'
                FG_FOUR_FIELD_INPLANE_DIVISIONS = '10'; FG_FOUR_FIELD_THICKNESS_DIVISIONS = '1'
                FG_FOUR_FIELD_RUN_TAG = 'comsol_four_field'
            }
            Output = 'comsol_four_field.mph'
        }
    }
}

$Source = Join-Path $SourceDir ($Config.Class + '.java')
if ($Target -eq 'inverse') {
    $Config.Env['FG_FOUR_FIELD_RUN_ID'] = [DateTime]::UtcNow.ToString(
        'yyyyMMddTHHmmssfffZ', [System.Globalization.CultureInfo]::InvariantCulture
    )
    $Config.Env['FG_FOUR_FIELD_SOURCE_SHA256'] = (
        Get-FileHash -LiteralPath $Source -Algorithm SHA256
    ).Hash.ToLowerInvariant()
}
Push-Location $SourceDir
try {
    & $Compiler $Source
    if ($LASTEXITCODE -ne 0) { throw 'COMSOL Java compilation failed.' }
    if ($CompileOnly) {
        Write-Host "Compiled $($Config.Class) successfully."
        return
    }
    foreach ($Item in $Config.Env.GetEnumerator()) {
        Set-Item -Path "Env:$($Item.Key)" -Value $Item.Value
    }
    $ClassFile = Join-Path $SourceDir ($Config.Class + '.class')
    $ModelPath = Join-Path $OutputDir $Config.Output
    $BatchLog = Join-Path $OutputDir ($Target + '.log')
    & $Batch -inputfile $ClassFile -classpathadd $SourceDir -outputfile $ModelPath -batchlog $BatchLog
    if ($LASTEXITCODE -ne 0) { throw "COMSOL $Target run failed." }
    if ($Target -eq 'inverse') {
        $PhysicsManifest = Join-Path $OutputDir 'comsol_four_field_physics_manifest.csv'
        $Summary = Join-Path $OutputDir 'comsol_four_field_summary.csv'
        $ChannelIsolation = Join-Path $OutputDir 'comsol_four_field_channel_isolation.csv'
        if (-not (Test-Path -LiteralPath $PhysicsManifest) -or
            -not (Test-Path -LiteralPath $Summary) -or
            -not (Test-Path -LiteralPath $ChannelIsolation)) {
            throw 'Four-field COMSOL run did not produce its manifest, summary, and isolation evidence.'
        }
        $Rows = @(Import-Csv -LiteralPath $PhysicsManifest)
        if ($Rows.Count -ne 1) { throw 'Four-field COMSOL physics manifest must contain one formal case.' }
        foreach ($Row in $Rows) {
            $AllFields = @($Row.solve_u, $Row.solve_phi, $Row.solve_psi, $Row.solve_T,
                $Row.same_stationary, $Row.open_circuit_electric, $Row.open_circuit_magnetic,
                $Row.insulated_thermal, $Row.independent_dof_fields,
                $Row.geometry_material_boundary_layer_observable_aligned) |
                ForEach-Object { $_.ToString().ToLowerInvariant() -eq 'true' }
            if ($AllFields -contains $false -or
                $Row.method -ne 'sequential_equivalent_four_field_solution' -or
                $Row.evidence_tier -ne 'A_independent_block_triangular_fields' -or
                $Row.solver_strategy -ne 'segregated_same_stationary' -or
                $Row.convergence_termination -ne 'fixed_25_segregated_iterations_with_final_residual_gate' -or
                $Row.direct_error_check -ne 'auto_enabled' -or
                $Row.segregated_termination -ne 'iter' -or
                $Row.coupling_equivalent_to_matlab -ne 'true' -or
                $Row.layer_field_layout -ne 'independent_per_physical_layer' -or
                $Row.observable_definition -ne 'max_minus_min_of_layer_top_bottom_area_average_potential_difference' -or
                $Row.layer_drop_definition -ne 'layer_thickness_times_volume_average_potential_gradient_equivalent_to_face_average_difference' -or
                $Row.status -ne 'completed_full_field' -or
                $Row.physical_layer_count -ne '10' -or
                $Row.fg_mode -ne 'U' -or
                [math]::Abs([double]$Row.vf0 - 0.6) -gt 1e-12 -or
                $Row.isomorphic_to_matlab_10layer -ne 'false' -or
                $Row.comparison_scope -ne 'same_geometry_material_boundary_observable_nonisomorphic_mechanics' -or
                $Row.mechanical_discretization -ne 'COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell' -or
                $Row.field_residual_evaluation_status -ne 'pass' -or
                $Row.api_channel_isolation_status -ne 'pass' -or
                $Row.solver_has_problems -ne 'false' -or
                $Row.residual_definition -ne 'mechanical=global_force_balance;weak_moment=max_layer_normalized_constitutive_flux_moment;discrete_group_error=max_final_outer_iteration_error_by_field;solver_linear_residual=max_final_inner_LinRes_by_field') {
                throw 'Four-field COMSOL physics manifest does not satisfy the formal A-tier contract.'
            }
            $FixedSegregatedIterations = [double]$Row.fixed_segregated_iterations
            if ([double]::IsNaN($FixedSegregatedIterations) -or
                [double]::IsInfinity($FixedSegregatedIterations) -or
                $FixedSegregatedIterations -ne 25.0) {
                throw 'Four-field COMSOL fixed_segregated_iterations must equal 25.'
            }
            $PhysicsResidualLimit = [double]$Row.physics_residual_limit
            $SolverConvergenceLimit = [double]$Row.solver_convergence_limit
            $SolverTolerance = [double]$Row.solver_relative_tolerance
            if ([double]::IsNaN($PhysicsResidualLimit) -or
                [double]::IsInfinity($PhysicsResidualLimit) -or
                [math]::Abs($PhysicsResidualLimit - 1e-6) -gt 1e-15 -or
                [double]::IsNaN($SolverConvergenceLimit) -or
                [double]::IsInfinity($SolverConvergenceLimit) -or
                [math]::Abs($SolverConvergenceLimit - 1e-5) -gt 1e-15 -or
                [double]::IsNaN($SolverTolerance) -or
                [double]::IsInfinity($SolverTolerance) -or
                [math]::Abs($SolverTolerance - 1e-4) -gt 1e-15) {
                throw 'Four-field COMSOL residual limits or solver tolerance are invalid.'
            }
            $SourceDigest = (Get-FileHash -Algorithm SHA256 -LiteralPath $Source).Hash.ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($Row.run_id) -or
                [string]::IsNullOrWhiteSpace($Row.source_sha256) -or
                $Row.source_sha256.ToLowerInvariant() -ne $SourceDigest) {
                throw 'Four-field evidence is not linked to the compiled formal producer source.'
            }
            $LegacyResidualFields = @('mechanical_residual', 'electric_charge_residual',
                'magnetic_flux_residual', 'thermal_residual', 'solver_linres')
            if (@($LegacyResidualFields | Where-Object { $Row.PSObject.Properties.Name -contains $_ }).Count -ne 0) {
                throw 'Four-field COMSOL manifest contains a legacy or ambiguous residual field.'
            }
            $PhysicalResidualFields = @(
                'mechanical_force_balance_residual',
                'electric_weak_moment_residual', 'magnetic_weak_moment_residual',
                'thermal_weak_moment_residual')
            $SolverConvergenceFields = @(
                'solid_discrete_segregated_group_relative_error',
                'electric_discrete_segregated_group_relative_error',
                'magnetic_discrete_segregated_group_relative_error',
                'thermal_discrete_segregated_group_relative_error',
                'solid_solver_linear_residual', 'electric_solver_linear_residual',
                'magnetic_solver_linear_residual', 'thermal_solver_linear_residual',
                'solver_linear_residual')
            $ResidualValues = @{}
            foreach ($Field in $PhysicalResidualFields) {
                if ($Row.PSObject.Properties.Name -notcontains $Field) {
                    throw "Four-field COMSOL residual $Field is missing."
                }
                $Value = [double]$Row.$Field
                if ([double]::IsNaN($Value) -or [double]::IsInfinity($Value) -or
                    $Value -lt 0.0 -or $Value -gt 1e-6) {
                    throw "Four-field COMSOL physical residual $Field is invalid or above 1e-6."
                }
                $ResidualValues[$Field] = $Value
            }
            foreach ($Field in $SolverConvergenceFields) {
                if ($Row.PSObject.Properties.Name -notcontains $Field) {
                    throw "Four-field COMSOL residual $Field is missing."
                }
                $Value = [double]$Row.$Field
                if ([double]::IsNaN($Value) -or [double]::IsInfinity($Value) -or
                    $Value -lt 0.0 -or $Value -gt 1e-5) {
                    throw "Four-field COMSOL solver convergence residual $Field is invalid or above 1e-5."
                }
                $ResidualValues[$Field] = $Value
            }
            $FieldSolverMax = @('solid_solver_linear_residual', 'electric_solver_linear_residual',
                'magnetic_solver_linear_residual', 'thermal_solver_linear_residual') |
                ForEach-Object { $ResidualValues[$_] } | Measure-Object -Maximum |
                Select-Object -ExpandProperty Maximum
            if ([math]::Abs($ResidualValues['solver_linear_residual'] - $FieldSolverMax) -gt 1e-15) {
                throw 'Global solver_linear_residual is not the maximum field solver residual.'
            }
            $CopiedPseudoResiduals = @('mechanical_force_balance_residual',
                'electric_weak_moment_residual', 'magnetic_weak_moment_residual',
                'thermal_weak_moment_residual') |
                Where-Object {
                    [math]::Abs($ResidualValues[$_] - $ResidualValues['solver_linear_residual']) -le 1e-15
                }
            if ($ResidualValues['solver_linear_residual'] -gt 0.0 -and
                @($CopiedPseudoResiduals).Count -eq 4) {
                throw 'Physical residuals are copied LinRes pseudo-residuals.'
            }
        }
        $FormalRow = $Rows[0]
        $SummaryRows = @(Import-Csv -LiteralPath $Summary)
        if ($SummaryRows.Count -ne 3 -or
            @($SummaryRows | Where-Object {
                $_.run_id -ne $FormalRow.run_id -or
                [string]::IsNullOrWhiteSpace($_.source_sha256) -or
                $_.source_sha256.ToLowerInvariant() -ne $FormalRow.source_sha256.ToLowerInvariant() -or
                $_.status -ne 'completed_full_field' -or
                $_.evidence_tier -ne 'A_independent_block_triangular_fields'
            }).Count -ne 0) {
            throw 'Four-field summary is not linked to the same successful producer run.'
        }
        $IsolationRows = @(Import-Csv -LiteralPath $ChannelIsolation)
        if ($IsolationRows.Count -ne 3 -or
            @($IsolationRows | Where-Object { $_.isolation_status -ne 'pass' }).Count -ne 0) {
            throw 'Four-field COMSOL channel-isolation evidence did not pass all three channels.'
        }
    }
} finally {
    Get-ChildItem -LiteralPath $SourceDir -Filter '*.class' -File -ErrorAction SilentlyContinue |
        Remove-Item -Force
    Pop-Location
}
