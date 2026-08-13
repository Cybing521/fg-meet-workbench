param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$output = Join-Path $RepositoryRoot 'outputs\code_closure\comsol_four_field'
$source = Join-Path $RepositoryRoot 'tools\comsol\RunBlockTriangularInverseSensorCfffValidation.java'
$manifestPath = Join-Path $output 'comsol_four_field_physics_manifest.csv'
$summaryPath = Join-Path $output 'comsol_four_field_summary.csv'
$layersPath = Join-Path $output 'comsol_four_field_layers.csv'
$modelPath = Join-Path $output 'comsol_four_field_Model.mph'
$statusPath = "$modelPath.status"

foreach ($path in @($source, $manifestPath, $summaryPath, $layersPath, $modelPath, $statusPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing four-field evidence artifact: $path"
    }
}

$manifest = Import-Csv -LiteralPath $manifestPath | Select-Object -First 1
$summary = @(Import-Csv -LiteralPath $summaryPath)
$layers = @(Import-Csv -LiteralPath $layersPath)
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()

if ($manifest.status -ne 'completed_full_field' -or
    $manifest.evidence_tier -ne 'A_independent_block_triangular_fields' -or
    $manifest.method -ne 'sequential_equivalent_four_field_solution') {
    throw 'Four-field manifest is not completed A-tier block-triangular evidence.'
}
if ($manifest.source_sha256 -ne $sourceHash) {
    throw "Manifest source hash does not match current source: $($manifest.source_sha256) != $sourceHash"
}
if ($manifest.isomorphic_to_matlab_10layer -ne 'false' -or
    $manifest.comparison_scope -ne 'same_geometry_material_boundary_observable_nonisomorphic_mechanics' -or
    $manifest.mechanical_discretization -ne 'COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell') {
    throw 'Four-field comparison-scope metadata is not scientifically aligned.'
}
if ($manifest.convergence_termination -ne 'fixed_25_segregated_iterations_with_final_residual_gate' -or
    $manifest.segregated_termination -ne 'iter' -or
    [int]$manifest.fixed_segregated_iterations -ne 25 -or
    $manifest.direct_error_check -ne 'auto_enabled') {
    throw 'Four-field solver-convergence metadata is inconsistent with the formal run.'
}

$physicsLimit = [double]$manifest.physics_residual_limit
$solverLimit = [double]$manifest.solver_convergence_limit
foreach ($name in @(
    'mechanical_force_balance_residual',
    'electric_weak_moment_residual',
    'magnetic_weak_moment_residual',
    'thermal_weak_moment_residual'
)) {
    if ([double]$manifest.$name -gt $physicsLimit) {
        throw "Physics residual exceeds limit: $name=$($manifest.$name) > $physicsLimit"
    }
}
foreach ($name in @(
    'solid_discrete_segregated_group_relative_error',
    'electric_discrete_segregated_group_relative_error',
    'magnetic_discrete_segregated_group_relative_error',
    'thermal_discrete_segregated_group_relative_error',
    'solid_solver_linear_residual',
    'electric_solver_linear_residual',
    'magnetic_solver_linear_residual',
    'thermal_solver_linear_residual'
)) {
    if ([double]$manifest.$name -gt $solverLimit) {
        throw "Solver convergence metric exceeds limit: $name=$($manifest.$name) > $solverLimit"
    }
}

if ($summary.Count -ne 3 -or @($summary | Where-Object status -ne 'completed_full_field').Count -ne 0) {
    throw 'Four-field summary must contain three completed target rows.'
}
if ($layers.Count -ne 10) {
    throw "Four-field layer evidence must contain ten rows, found $($layers.Count)."
}
if (@($summary | Where-Object source_sha256 -ne $sourceHash).Count -ne 0 -or
    @($layers | Where-Object source_sha256 -ne $sourceHash).Count -ne 0) {
    throw 'Four-field CSV evidence contains a stale source hash.'
}
if ((Get-Content -LiteralPath $statusPath -Raw) -notmatch '(?m)^Done\s*$') {
    throw 'COMSOL model status is not Done.'
}

Write-Output "PASS,four_field_evidence_contract,$manifestPath"
