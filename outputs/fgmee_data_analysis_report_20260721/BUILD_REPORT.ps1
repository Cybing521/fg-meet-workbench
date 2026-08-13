[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ReportRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ReportRoot '..\..')).Path
$TexPath = Join-Path $ReportRoot 'fgmee_data_analysis_report_20260721.tex'
$StyleCheck = Join-Path $RepoRoot 'tools\reporting\check_data_report.ps1'
$StyleOutput = Join-Path $ReportRoot 'STYLE_CHECK.txt'
$BuildRoot = Join-Path $ReportRoot 'build'

if (-not (Test-Path -LiteralPath $TexPath)) {
    throw "LaTeX source is missing: $TexPath"
}
if (-not (Test-Path -LiteralPath $StyleCheck)) {
    throw "Report style checker is missing: $StyleCheck"
}

& $StyleCheck -TexPath $TexPath -OutputPath $StyleOutput
if ($LASTEXITCODE -ne 0) {
    throw 'Report style check failed.'
}

$XeLaTeX = @(
    (Get-Command xelatex -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Source -First 1),
    'D:\MiKTeX\miktex\bin\x64\xelatex.exe'
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
    Select-Object -First 1
if (-not $XeLaTeX) {
    throw 'XeLaTeX was not found.'
}

New-Item -ItemType Directory -Path $BuildRoot -Force | Out-Null
Push-Location $ReportRoot
try {
    1..2 | ForEach-Object {
        & $XeLaTeX -interaction=nonstopmode -halt-on-error `
            -output-directory=$BuildRoot $TexPath
        if ($LASTEXITCODE -ne 0) {
            throw "XeLaTeX pass $_ failed with exit code $LASTEXITCODE."
        }
    }
} finally {
    Pop-Location
}

$BuiltPdf = Join-Path $BuildRoot 'fgmee_data_analysis_report_20260721.pdf'
$FinalPdf = Join-Path $ReportRoot 'fgmee_data_analysis_report_20260721.pdf'
Copy-Item -LiteralPath $BuiltPdf -Destination $FinalPdf -Force
Write-Host "Built $FinalPdf"

