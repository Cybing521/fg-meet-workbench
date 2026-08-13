param(
    [int]$InplaneDivisions = 10,
    [int]$ThicknessDivisions = 1,
    [double]$ProbePressurePa = 15000.0,
    [string]$OutputDir = ''
)

$ErrorActionPreference = 'Stop'
Write-Warning 'Deprecated entry point: the model is block triangular, not fully coupled. Forwarding to run_block_triangular_inverse_sensor_validation.ps1.'

& (Join-Path $PSScriptRoot 'run_block_triangular_inverse_sensor_validation.ps1') `
    -InplaneDivisions $InplaneDivisions `
    -ThicknessDivisions $ThicknessDivisions `
    -ProbePressurePa $ProbePressurePa `
    -OutputDir $OutputDir
