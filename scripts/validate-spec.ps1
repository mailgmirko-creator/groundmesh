param(
  [string]$Root = "proposals"
)

$requiredSections = @(
  "^#\s+.+",                 # Title line exists
  "^##\s+Purpose \(why\)",
  "^##\s+User Story",
  "^##\s+Inputs",
  "^##\s+Outputs",
  "^##\s+Acceptance Criteria \(checkable\)"
)

$files = Get-ChildItem -Path $Root -Filter *.md -Recurse -ErrorAction SilentlyContinue
if (-not $files) {
  Write-Host "No proposal files found — nothing to validate."
  exit 0
}

$fail = $false
foreach ($f in $files) {
  $c = Get-Content $f.FullName -Raw
  $missing = @()
  foreach ($pat in $requiredSections) {
    if ($c -notmatch $pat) { $missing += $pat }
  }
  if ($missing.Count -gt 0) {
    Write-Output "::warning file=$($f.FullName)::Missing sections:`n - " + ($missing -join "`n - ")
    $fail = $true
  } else {
    Write-Host "OK: $($f.FullName)"
  }
}

# Soft fail (warnings only) for hospitality; change to exit 1 to enforce.
exit 0
