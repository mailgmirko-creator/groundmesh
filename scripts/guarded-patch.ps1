param(
  [Parameter(Mandatory)][string]$Path,
  [Parameter(Mandatory)][string]$FindRegex,
  [Parameter(Mandatory)][string]$ReplaceWith,
  [string[]]$MustContain = @(),
  [string[]]$MustNotContain = @(),
  [switch]$Apply
)

if (-not (Test-Path $Path)) { throw "File not found: $Path" }
$content = Get-Content $Path -Raw

foreach ($pat in $MustContain) {
  if ($content -notmatch $pat) { throw "Guard failed: expected to find pattern: $pat" }
}
foreach ($pat in $MustNotContain) {
  if ($content -match $pat) { throw "Guard failed: must NOT find pattern: $pat" }
}

$opts = [System.Text.RegularExpressions.RegexOptions]::Singleline
$changed = [System.Text.RegularExpressions.Regex]::Replace($content, $FindRegex, $ReplaceWith, $opts)

if ($changed -eq $content) {
  Write-Host "No change (pattern not found or already applied)."
  exit 0
}

# Show a diff using git's diff engine without staging
$tmp = New-Item -ItemType File -Path ([System.IO.Path]::GetTempFileName()) -Force
Set-Content $tmp $changed -Encoding UTF8
git --no-pager diff --no-index -- $Path $tmp
Remove-Item $tmp -Force

if ($Apply) {
  Set-Content $Path $changed -Encoding UTF8
  Write-Host "Applied changes to $Path"
}
