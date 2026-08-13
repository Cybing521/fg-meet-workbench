[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TexPath,

    [string]$OutputPath,

    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$ResolvedTex = (Resolve-Path -LiteralPath $TexPath).Path
$Raw = Get-Content -Raw -LiteralPath $ResolvedTex -Encoding utf8

# Ignore ordinary LaTeX comments while preserving escaped percent signs.
$Body = (($Raw -split "`r?`n") | ForEach-Object {
    $_ -replace '(?<!\\)%.*$', ''
}) -join "`n"

$BlockedPatterns = @(
    @{ Name = 'colored conclusion box'; Pattern = '\\(?:fcolorbox|colorbox|textcolor)\b' },
    @{ Name = 'workflow slogan'; Pattern = '结论先行|一页状态表|最终交付措辞' },
    @{ Name = 'internal evidence label'; Pattern = '证据等级|[AB]_independent_[A-Za-z_]+' },
    @{ Name = 'internal status code'; Pattern = 'completed_[A-Za-z_]+' },
    @{ Name = 'run instructions in body'; Pattern = 'PowerShell|\.ps1\b|实际运行顺序|脚本路径' },
    @{ Name = 'assistant or production trace'; Pattern = '由\s*(?:AI|Codex|Claude)\s*生成|根据用户提供|后续可补充' }
)

$SoftPatterns = @(
    @{ Name = 'formulaic transition'; Pattern = '此外|值得注意的是|至关重要' },
    @{ Name = 'formulaic contrast'; Pattern = '不仅.{0,30}而且|这不仅仅是.{0,30}而是' },
    @{ Name = 'delivery wording'; Pattern = '可以写[：:]|不能写[：:]' },
    @{ Name = 'inflated claim'; Pattern = '充分证明|有力证明|形成闭环|全面验证' }
)

$Errors = [System.Collections.Generic.List[string]]::new()
$Warnings = [System.Collections.Generic.List[string]]::new()

foreach ($Rule in $BlockedPatterns) {
    $Matches = [regex]::Matches($Body, $Rule.Pattern)
    if ($Matches.Count -gt 0) {
        $Errors.Add("$($Rule.Name): $($Matches.Count) match(es)")
    }
}

foreach ($Rule in $SoftPatterns) {
    $Matches = [regex]::Matches($Body, $Rule.Pattern)
    if ($Matches.Count -gt 0) {
        $Warnings.Add("$($Rule.Name): $($Matches.Count) match(es)")
    }
}

$Counts = [ordered]@{
    sections = [regex]::Matches($Body, '\\section\{').Count
    tables = [regex]::Matches($Body, '\\begin\{table\}').Count
    figures = [regex]::Matches($Body, '\\begin\{figure\}').Count
    bold_phrases = [regex]::Matches($Body, '\\textbf\{').Count
    list_blocks = [regex]::Matches($Body, '\\begin\{(?:itemize|enumerate)\}').Count
}

if ($Counts.sections -gt 5) {
    $Warnings.Add("section count is $($Counts.sections); target is at most 5")
}
if ($Counts.tables -gt 3) {
    $Warnings.Add("table count is $($Counts.tables); target is at most 3")
}
if ($Counts.figures -gt 2) {
    $Warnings.Add("figure count is $($Counts.figures); target is at most 2")
}
if ($Counts.bold_phrases -gt 8) {
    $Warnings.Add("bold phrase count is $($Counts.bold_phrases); reduce emphasis")
}
if ($Counts.list_blocks -gt 2) {
    $Warnings.Add("list block count is $($Counts.list_blocks); prefer prose in report bodies")
}
if ($Body -notmatch '\\begin\{abstract\}|\\section\{[^}]*摘要') {
    $Warnings.Add('no visible abstract or summary section')
}
if ($Body -notmatch '\\section\{[^}]*结论') {
    $Warnings.Add('no conclusion section')
}

$Status = if ($Errors.Count -gt 0 -or ($Strict -and $Warnings.Count -gt 0)) {
    'FAIL'
} else {
    'PASS'
}

$Lines = [System.Collections.Generic.List[string]]::new()
$Lines.Add("status=$Status")
$Lines.Add("file=$ResolvedTex")
$Lines.Add("errors=$($Errors.Count)")
$Lines.Add("warnings=$($Warnings.Count)")
foreach ($Entry in $Counts.GetEnumerator()) {
    $Lines.Add("$($Entry.Key)=$($Entry.Value)")
}
foreach ($ErrorMessage in $Errors) {
    $Lines.Add("ERROR: $ErrorMessage")
}
foreach ($WarningMessage in $Warnings) {
    $Lines.Add("WARNING: $WarningMessage")
}

$Lines | ForEach-Object { Write-Host $_ }
if ($OutputPath) {
    $Parent = Split-Path -Parent $OutputPath
    if ($Parent -and -not (Test-Path -LiteralPath $Parent)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }
    $Lines | Set-Content -LiteralPath $OutputPath -Encoding utf8
}

if ($Status -eq 'FAIL') {
    exit 1
}

