param(
    [int]$DurationSec = 900,
    [int]$FrameRate = 30,
    [string]$OutputDir = "reports\2026-06-01-comsol-validation-video\gui-recordings",
    [string]$Name = "comsol_gui_validation"
)

$ErrorActionPreference = "Stop"
$ffmpeg = "D:\ffmpeg-7.0.2-full_build\bin\ffmpeg.exe"
if (-not (Test-Path -LiteralPath $ffmpeg)) {
    throw "ffmpeg not found: $ffmpeg"
}

$root = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$outDir = Join-Path $root $OutputDir
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$out = Join-Path $outDir "${Name}_${stamp}.mp4"

Write-Host "Recording desktop to: $out"
Write-Host "Duration: $DurationSec seconds. Keep COMSOL visible while this runs."

& $ffmpeg `
    -y `
    -f gdigrab `
    -framerate $FrameRate `
    -i desktop `
    -t $DurationSec `
    -c:v libx264 `
    -preset veryfast `
    -crf 23 `
    -pix_fmt yuv420p `
    $out

Write-Host "Saved: $out"
