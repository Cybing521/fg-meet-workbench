param(
    [ValidateSet('all', 'electric', 'magnetic')]
    [string]$Mode = 'all',
    [int]$InplaneDivisions = 20,
    [int]$ThicknessDivisionsPerLayer = 10,
    [ValidateSet('all', '0.5', '1.0', '2.0')]
    [string]$TargetMm = 'all',
    [ValidateSet('comsol', 'matlab')]
    [string]$LoadBasis = 'comsol'
)

$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$OutDir = Join-Path $Root 'outputs\paper-20260715-fgmee\experiments\inverse_actuation'
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$ComsolBin = 'D:\comsol\COMSOL60\Multiphysics\bin\win64'
$ComsolBatch = Join-Path $ComsolBin 'comsolbatch.exe'
$ComsolCompile = Join-Path $ComsolBin 'comsolcompile.exe'
if (-not (Test-Path -LiteralPath $ComsolBatch)) {
    throw "COMSOL batch executable not found: $ComsolBatch"
}

$electricJava = Join-Path $Root 'tools\comsol\RunDirectElectroCfffValidation.java'
$electricClass = Join-Path $Root 'tools\comsol\RunDirectElectroCfffValidation.class'
$magneticJava = Join-Path $Root 'tools\comsol\RunDirectMagneticCfffValidation.java'
$magneticClass = Join-Path $Root 'tools\comsol\RunDirectMagneticCfffValidation.class'

foreach ($pair in @(@($electricJava, $electricClass), @($magneticJava, $magneticClass))) {
    $javaFile = $pair[0]
    $classFile = $pair[1]
    if ((-not (Test-Path -LiteralPath $classFile)) -or
        ((Get-Item -LiteralPath $javaFile).LastWriteTimeUtc -gt (Get-Item -LiteralPath $classFile).LastWriteTimeUtc)) {
        & $ComsolCompile $javaFile
        if ($LASTEXITCODE -ne 0) {
            throw "COMSOL Java compilation failed: $javaFile"
        }
    }
}

$targets = if ($TargetMm -eq 'all') {
    @(0.5, 1.0, 2.0)
} else {
    @([double]::Parse($TargetMm, [System.Globalization.CultureInfo]::InvariantCulture))
}
$matlabElectricDispAt300V = 0.0522570949262148
$comsolElectricDispAt300V = 0.05788658848890287
$matlabMagneticDispAt200A = 0.174585747179692
$comsolMagneticDispAt200A = 0.19076621638710417

function Format-TargetTag([double]$Target) {
    return $Target.ToString('0.0', [System.Globalization.CultureInfo]::InvariantCulture).Replace('.', 'p')
}

function Invoke-ComsolCase {
    param(
        [string]$ClassFile,
        [string]$Tag,
        [string]$PotentialEnvName,
        [double]$PotentialValue
    )

    $env:FG_DIRECT_OUTPUT_DIR = $OutDir
    $env:FG_DIRECT_RUN_TAG = $Tag
    $env:FG_DIRECT_INPLANE_DIVISIONS = [string]$InplaneDivisions
    $env:FG_DIRECT_THICKNESS_DIVISIONS = [string]$ThicknessDivisionsPerLayer
    Set-Item -Path "Env:$PotentialEnvName" -Value $PotentialValue.ToString('G17', [System.Globalization.CultureInfo]::InvariantCulture)

    $baseName = "comsol_$Tag"
    $mphOut = Join-Path $OutDir "$baseName.mph"
    $logOut = Join-Path $OutDir "$baseName.log"
    Write-Host "RUN,$Tag,potential=$PotentialValue"
    & $ComsolBatch -inputfile $ClassFile -outputfile $mphOut -batchlog $logOut
    if ($LASTEXITCODE -ne 0) {
        throw "COMSOL case failed: $Tag. See $logOut"
    }
}

if ($Mode -in @('all', 'electric')) {
    foreach ($target in $targets) {
        $electricReference = if ($LoadBasis -eq 'comsol') {
            $comsolElectricDispAt300V
        } else {
            $matlabElectricDispAt300V
        }
        $requiredVoltage = $target * 300.0 / $electricReference
        $basisSuffix = if ($LoadBasis -eq 'comsol') { '' } else { '_matlab_load_crosscheck' }
        $tag = "inverse_actuation_electric_target_$(Format-TargetTag $target)mm$basisSuffix"
        Invoke-ComsolCase -ClassFile $electricClass -Tag $tag -PotentialEnvName 'FG_DIRECT_VOLTAGE' -PotentialValue $requiredVoltage
    }
}

if ($Mode -in @('all', 'magnetic')) {
    foreach ($target in $targets) {
        $magneticReference = if ($LoadBasis -eq 'comsol') {
            $comsolMagneticDispAt200A
        } else {
            $matlabMagneticDispAt200A
        }
        $requiredMagneticPotential = $target * 200.0 / $magneticReference
        $basisSuffix = if ($LoadBasis -eq 'comsol') { '' } else { '_matlab_load_crosscheck' }
        $tag = "inverse_actuation_magnetic_target_$(Format-TargetTag $target)mm$basisSuffix"
        Invoke-ComsolCase -ClassFile $magneticClass -Tag $tag -PotentialEnvName 'FG_DIRECT_MAGNETIC_POTENTIAL_A' -PotentialValue $requiredMagneticPotential
    }
}

$summary = Join-Path $OutDir 'inverse_actuation_run_summary.txt'
@(
    "status=PASS",
    "mode=$Mode",
    "target_mm=$TargetMm",
    "load_basis=$LoadBasis",
    "inplane_divisions=$InplaneDivisions",
    "thickness_divisions_per_layer=$ThicknessDivisionsPerLayer",
    "matlab_electric_disp_at_300V_mm=$matlabElectricDispAt300V",
    "comsol_electric_disp_at_300V_mm=$comsolElectricDispAt300V",
    "matlab_magnetic_disp_at_200A_mm=$matlabMagneticDispAt200A",
    "comsol_magnetic_disp_at_200A_mm=$comsolMagneticDispAt200A"
) | Set-Content -LiteralPath $summary -Encoding UTF8

Write-Host "INVERSE_ACTUATION_COMSOL_DONE,$summary"
