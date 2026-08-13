[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Validator = Join-Path $Root 'code\python\validate_package.py'

$Candidates = @(
    @(
        $env:FGMEE_PYTHON,
        'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe',
        (Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
)

if (-not $Candidates) {
    throw 'Python was not found. Set FGMEE_PYTHON to a Python 3 executable.'
}

& $Candidates[0] $Validator --package-root $Root
if ($LASTEXITCODE -ne 0) {
    throw "Package validation failed with exit code $LASTEXITCODE."
}
