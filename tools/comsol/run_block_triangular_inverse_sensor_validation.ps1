param(
    [int]$InplaneDivisions = 10,
    [int]$ThicknessDivisions = 1,
    [double]$ProbePressurePa = 15000.0,
    [string]$OutputDir = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $OutputDir) {
    $OutputDir = Join-Path $root 'outputs\code_closure\comsol_four_field'
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path

$candidates = @(
    $env:COMSOLBATCH,
    'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe',
    'C:\Program Files\COMSOL\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe',
    'C:\Program Files\COMSOL\COMSOL61\Multiphysics\bin\win64\comsolbatch.exe',
    'C:\Program Files\COMSOL\COMSOL62\Multiphysics\bin\win64\comsolbatch.exe'
)
$comsolBatch = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $comsolBatch) {
    throw 'comsolbatch.exe not found; set COMSOLBATCH to its full path.'
}
$comsolCompile = Join-Path (Split-Path -Parent $comsolBatch) 'comsolcompile.exe'
$java = Join-Path $PSScriptRoot 'RunBlockTriangularInverseSensorCfffValidation.java'
$class = Join-Path $PSScriptRoot 'RunBlockTriangularInverseSensorCfffValidation.class'
if ((-not (Test-Path -LiteralPath $class)) -or
    ((Get-Item -LiteralPath $java).LastWriteTimeUtc -gt (Get-Item -LiteralPath $class).LastWriteTimeUtc)) {
    & $comsolCompile $java
    if ($LASTEXITCODE -ne 0) {
        throw "COMSOL Java compilation failed: $java"
    }
}

$env:FG_FOUR_FIELD_OUTPUT_DIR = $OutputDir
$env:FG_FOUR_FIELD_RUN_TAG = 'comsol_four_field'
$env:FG_FOUR_FIELD_RUN_ID = [DateTime]::UtcNow.ToString(
    'yyyyMMddTHHmmssfffZ', [System.Globalization.CultureInfo]::InvariantCulture
)
$env:FG_FOUR_FIELD_SOURCE_SHA256 = (Get-FileHash -LiteralPath $java -Algorithm SHA256).Hash.ToLowerInvariant()
$env:FG_FOUR_FIELD_INPLANE_DIVISIONS = [string]$InplaneDivisions
$env:FG_FOUR_FIELD_THICKNESS_DIVISIONS = [string]$ThicknessDivisions
$env:FG_FOUR_FIELD_PROBE_PRESSURE_PA = $ProbePressurePa.ToString(
    'G17', [System.Globalization.CultureInfo]::InvariantCulture
)

$mph = Join-Path $OutputDir 'comsol_four_field_Model.mph'
$log = Join-Path $OutputDir 'comsol_four_field.log'
$staleEvidence = @(
    $mph,
    "$mph.status",
    (Join-Path $OutputDir 'comsol_four_field_Model_FourFieldModel.mph'),
    (Join-Path $OutputDir 'comsol_four_field_summary.csv'),
    (Join-Path $OutputDir 'comsol_four_field_layers.csv'),
    (Join-Path $OutputDir 'comsol_four_field_physics_manifest.csv'),
    (Join-Path $OutputDir 'comsol_four_field_channel_isolation.csv'),
    (Join-Path $OutputDir 'comsol_four_field_java_error.log'),
    (Join-Path $OutputDir 'comsol_four_field_solver_progress.log')
)
foreach ($path in $staleEvidence) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
    }
}
& $comsolBatch -classpathadd $PSScriptRoot -inputfile $class -outputfile $mph -batchlog $log
if ($LASTEXITCODE -ne 0) {
    throw "Four-field COMSOL validation failed; inspect $log and the physics manifest."
}
$statusFile = "$mph.status"
if (Test-Path -LiteralPath $statusFile) {
    $statusText = Get-Content -LiteralPath $statusFile -Raw
    if ($statusText -match '(?im)^Error\s*$') {
        throw "COMSOL class execution failed despite process exit code 0; inspect $statusFile and $OutputDir\comsol_four_field_solver_progress.log."
    }
}

$manifest = Join-Path $OutputDir 'comsol_four_field_physics_manifest.csv'
$summary = Join-Path $OutputDir 'comsol_four_field_summary.csv'
if (-not (Test-Path -LiteralPath $manifest) -or -not (Test-Path -LiteralPath $summary)) {
    throw 'COMSOL returned success without the required four-field evidence files.'
}
$row = Import-Csv -LiteralPath $manifest | Select-Object -First 1
if ($row.status -ne 'completed_full_field') {
    throw "Four-field evidence gate failed with status=$($row.status)."
}

Write-Output "PASS,four_field_comsol,$manifest"
