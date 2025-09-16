param(
  [string]$Root = "proposals"
)

# Require these headings (exact text) somewhere in the file (multiline)
$requiredSections = @(
  "^#\s+.+",                 # Title line exists
  "^##\s+Purpose \(why\)",
  "^##\s+User Story",
  "^##\s+Inputs",
  "^##\s+Outputs",
  "^##\s+Acceptance Criteria \(checkable\)"
)

# Regex options: Multiline so ^ and $ match line boundaries
$opts = [System.Text.RegularExpressions.RegexOptions]::Multiline

# Gather .md files, excluding the template
$files = Get-ChildItem -Path $Root -Filter *.md -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -ne "spec-template.md" }

if (-not $files) {
  Write-Host "No proposal files found — nothing to validate."
  exit 0
}

$hadWarnings = $false

foreach ($f in $files) {
  $c = Get-Content $f.FullName -Raw
  $missing = @()
  foreach ($pat in $requiredSections) {
    if (-not [System.Text.RegularExpressions.Regex]::IsMatch($c, $pat, $opts)) {
      $missing += $pat
    }
  }
  if ($missing.Count -gt 0) {
    Write-Output ("::warning file={0}::Missing sections:`n - {1}" -f $f.FullName, ($missing -join "`n - "))
    $hadWarnings = $true
  } else {
    Write-Host ("OK: {0}" -f $f.FullName)
  }
}

# Hospitality mode: always exit 0 so CI warns but doesn’t fail the build
exit 0
