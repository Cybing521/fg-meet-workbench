# One-command COMSOL validation entrypoint.
# Run from this repository/package root:
#   powershell -ExecutionPolicy Bypass -File .\RUN_COMSOL_MAIN.ps1

param(
    [string]$RunTag = 'package_U_Vf06_layered_csv_sweep7_mesh4',
    [int]$MeshSize = 4,
    [int]$SweepLayers = 7,
    [int]$InplaneDivisions = 0,
    [double]$StiffnessScale = 1.0,
    [ValidateSet('isotropic', 'orthotropic', 'qian_mee', 'qian_thermal_piezo')]
    [string]$SolidModel = 'isotropic',
    [ValidateSet('1', '2', '2s', '3', '3s')]
    [string]$DisplacementOrder = '2s',
    [ValidateSet('pressure', 'forcearea')]
    [string]$LoadMode = 'pressure',
    [switch]$GeometricNonlinear,
    [switch]$SkipCompare
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Find-ExistingPath {
    param([string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }
    return $null
}

function Find-Python {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command py -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $bundled = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (Test-Path $bundled) { return $bundled }
    return $null
}

$ComsolBatch = Find-ExistingPath @(
    $env:COMSOLBATCH,
    'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe',
    'C:\Program Files\COMSOL\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe',
    'C:\Program Files\COMSOL\COMSOL61\Multiphysics\bin\win64\comsolbatch.exe',
    'C:\Program Files\COMSOL\COMSOL62\Multiphysics\bin\win64\comsolbatch.exe'
)

if (-not $ComsolBatch) {
    throw 'comsolbatch.exe was not found. Set COMSOLBATCH to the full comsolbatch.exe path and rerun.'
}

$ComsolCompile = Join-Path (Split-Path -Parent $ComsolBatch) 'comsolcompile.exe'
$OutputDir = Join-Path $Root 'output'
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$classFile = Join-Path $Root 'tools\comsol\RunElasticCfffValidation.class'
$javaFile = Join-Path $Root 'tools\comsol\RunElasticCfffValidation.java'
$needsCompile = (-not (Test-Path $classFile))
if ((Test-Path $classFile) -and (Test-Path $javaFile)) {
    $needsCompile = (Get-Item $javaFile).LastWriteTimeUtc -gt (Get-Item $classFile).LastWriteTimeUtc
}
if ($needsCompile -and (Test-Path $ComsolCompile)) {
    & $ComsolCompile $javaFile
    if ($LASTEXITCODE -ne 0) {
        throw "COMSOL Java compilation failed: $javaFile"
    }
}

if (-not (Test-Path $classFile)) {
    throw "COMSOL class file not found: $classFile"
}

$env:FG_COMSOL_OUTPUT_DIR = $OutputDir
$env:FG_COMSOL_RUN_TAG = $RunTag
$env:FG_COMSOL_LAYERED = 'true'
$env:FG_COMSOL_SOLID_MODEL = $SolidModel
$env:FG_COMSOL_MESH_MODE = 'sweep'
$env:FG_COMSOL_MESH_SIZE = [string]$MeshSize
$env:FG_COMSOL_SWEEP_LAYERS = [string]$SweepLayers
$env:FG_COMSOL_INPLANE_DIVISIONS = [string]$InplaneDivisions
$env:FG_COMSOL_STIFFNESS_SCALE = $StiffnessScale.ToString([System.Globalization.CultureInfo]::InvariantCulture)
$env:FG_COMSOL_DISPLACEMENT_ORDER = $DisplacementOrder
$env:FG_COMSOL_GEOMETRIC_NONLINEAR = if ($GeometricNonlinear) { 'true' } else { 'false' }
$env:FG_COMSOL_LOAD_MODE = $LoadMode
$env:FG_COMSOL_CASE_ID = 'U_Vf06_elastic'
$env:FG_COMSOL_FG_MODE = 'U'
$env:FG_COMSOL_VF0 = '0.6'
$env:FG_COMSOL_BC = 'CFFF'
$env:FG_COMSOL_LAYER_CSV = Join-Path $Root 'comsol\export\Thermal_CFFF_U_Vf0.6-30x30-10layer_layers.csv'

$baseName = "comsol_elastic_validation_$RunTag"
$mphOut = Join-Path $OutputDir "$baseName.mph"
$logOut = Join-Path $OutputDir "$baseName.log"
$pointsCsv = Join-Path $OutputDir "$baseName`_points.csv"

Write-Host "[FG-MEET] COMSOL batch: $ComsolBatch"
Write-Host "[FG-MEET] Running COMSOL validation: $RunTag"

& $ComsolBatch `
    -inputfile $classFile `
    -outputfile $mphOut `
    -batchlog $logOut

if ($LASTEXITCODE -ne 0) {
    throw "COMSOL validation failed. See log: $logOut"
}

$taggedMphOut = Join-Path $OutputDir "$baseName`_Model.mph"
if (Test-Path $taggedMphOut) {
    $mphOut = $taggedMphOut
}

Write-Host "[FG-MEET] COMSOL model: $mphOut"
Write-Host "[FG-MEET] COMSOL log: $logOut"
Write-Host "[FG-MEET] COMSOL point CSV: $pointsCsv"

if ($SkipCompare) {
    Write-Host '[FG-MEET] MATLAB comparison skipped by -SkipCompare.'
    exit 0
}

$meetMat = Join-Path $OutputDir 'static_elastic_phase1_U_Vf06.mat'
$caseFile = Join-Path $Root 'cases\Thermal_CFFF_U_Vf0.6-30x30-10layer.txt'
$compareScript = Join-Path $Root 'tools\compare_comsol_validation_general.py'

if ((Test-Path $pointsCsv) -and (Test-Path $meetMat) -and (Test-Path $caseFile) -and (Test-Path $compareScript)) {
    $python = Find-Python
    if ($python) {
        $pointOut = Join-Path $Root "comsol\results\validation_points_$RunTag.csv"
        $compareLog = Join-Path $Root "comsol\results\validation_log_$RunTag.csv"
        $summaryOut = Join-Path $Root "comsol\results\validation_summary_$RunTag.csv"

        & $python $compareScript `
            --comsol-csv $pointsCsv `
            --meet-mat $meetMat `
            --case-file $caseFile `
            --point-out $pointOut `
            --log-out $compareLog `
            --summary-out $summaryOut `
            --run-tag $RunTag `
            --case-id 'U_Vf06_elastic' `
            --fg-mode 'U' `
            --vf0 '0.6' `
            --bc 'CFFF' `
            --comsol-mesh '3D solid 10-domain CSV materials, swept quad/hex mesh, hauto size 4, 7 elements per material layer, force area' `
            --notes-extra 'single main program run'

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[FG-MEET] Comparison points: $pointOut"
            Write-Host "[FG-MEET] Comparison summary: $summaryOut"
        } else {
            Write-Warning 'COMSOL finished, but MATLAB comparison failed. Check Python/scipy and rerun comparison if needed.'
        }
    } else {
        Write-Warning 'COMSOL finished, but Python was not found. Comparison skipped.'
    }
} else {
    Write-Warning 'COMSOL finished, but comparison was skipped because the MATLAB reference .mat or comparison inputs were not found.'
    Write-Warning "Expected MATLAB reference: $meetMat"
}

Write-Host '[FG-MEET] COMSOL main finished.'
