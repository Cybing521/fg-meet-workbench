[CmdletBinding()]
param(
    [ValidateSet('isomorphic', 'curvature', 'inverse', 'all')]
    [string]$Target = 'isomorphic'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$MatlabDir = Join-Path $Root 'code\matlab'
$Candidates = @(
    @(
        $env:FGMEE_MATLAB,
        'D:\MATLAB\R2026a\bin\matlab.exe',
        (Get-Command matlab -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
)

if (-not $Candidates) {
    throw 'MATLAB was not found. Set FGMEE_MATLAB to matlab.exe.'
}

$Jobs = if ($Target -eq 'all') { @('isomorphic', 'curvature', 'inverse') } else { @($Target) }
foreach ($Job in $Jobs) {
    $Script = Join-Path $MatlabDir "jobs\run_${Job}_validation.m"
    $EscapedMatlabDir = $MatlabDir.Replace("'", "''")
    $EscapedScript = $Script.Replace("'", "''")
    & $Candidates[0] -batch "addpath('$EscapedMatlabDir'); run('$EscapedScript');"
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB $Job validation failed with exit code $LASTEXITCODE."
    }
}
