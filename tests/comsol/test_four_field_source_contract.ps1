param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $RepositoryRoot 'tools\comsol\RunBlockTriangularInverseSensorCfffValidation.java'
if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing four-field COMSOL source: $source"
}

$text = Get-Content -LiteralPath $source -Raw
$required = @(
    'SolidMechanics',
    'WeakFormPDE',
    'String field = "phiN" + i',
    'String field = "psiN" + i',
    'String field = "tempN" + i',
    'ExternalStress',
    '"gaugeE" + i, "PointwiseConstraint", 0',
    '"gaugeM" + i, "PointwiseConstraint", 0',
    'setSolveFor("/physics/solid", true)',
    'setSolveFor("/physics/we" + i, true)',
    'setSolveFor("/physics/wm" + i, true)',
    'setSolveFor("/physics/wt" + i, true)',
    'sequential_equivalent_four_field_solution',
    'A_independent_block_triangular_fields',
    'computeWeakMomentResiduals',
    'parseFinalSolverConvergence',
    'electric_discrete_segregated_group_relative_error',
    'electric_solver_linear_residual',
    'fixed_25_segregated_iterations_with_final_residual_gate',
    'auto_enabled',
    'same_geometry_material_boundary_observable_nonisomorphic_mechanics',
    'COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell',
    'max_minus_min_of_layer_top_bottom_area_average_potential_difference',
    'comsol_four_field_physics_manifest.csv',
    'comsol_four_field_summary.csv'
)

foreach ($needle in $required) {
    if (-not $text.Contains($needle)) {
        throw "Four-field source contract is missing: $needle"
    }
}

$forbidden = @(
    'constitutive_postprocess',
    'completed_nonisomorphic_3d_constitutive_postprocess',
    'ten_layer_isomorphic_cross_solver',
    'RunFullyCoupledInverseSensorCfffValidation',
    '.set("errorchk", "off")'
)
foreach ($needle in $forbidden) {
    if ($text.Contains($needle)) {
        throw "Four-field source contains forbidden postprocess marker: $needle"
    }
}

Write-Output 'PASS,four_field_source_contract'
