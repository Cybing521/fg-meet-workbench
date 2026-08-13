[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $Root 'report\phase4_reporting'
$Tex = Join-Path $ReportDir 'fgmee_latest_feasible_results_report_20260715.tex'
$OutputDir = Join-Path $Root 'results\recomputed\report'
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$Candidates = @(
    @(
        $env:FGMEE_TECTONIC,
        (Get-Command tectonic -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
)
if (-not $Candidates) {
    throw 'Tectonic was not found. Set FGMEE_TECTONIC to tectonic.exe.'
}

Push-Location $ReportDir
try {
    & $Candidates[0] --outdir $OutputDir $Tex
    if ($LASTEXITCODE -ne 0) { throw 'Report compilation failed.' }
} finally {
    Pop-Location
}
