param(
  [string]$ManifestPath = "docs/behavior-atlas/releases/m4-public-alpha-v0.1.json"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$manifestAbs = if ([System.IO.Path]::IsPathRooted($ManifestPath)) { $ManifestPath } else { Join-Path $RepoRoot $ManifestPath }

if (-not (Test-Path $manifestAbs)) { throw "Release manifest not found: $manifestAbs" }
$manifest = Get-Content $manifestAbs -Raw | ConvertFrom-Json
$rollbackRef = [string]$manifest.rollback_ref
if ($rollbackRef -notmatch '^[a-f0-9]{40}$') { throw "rollback_ref must be a full 40-character Git commit SHA." }
if (@($manifest.cases).Count -lt 3) { throw "M4 restore drill requires at least three public-alpha cases." }

Push-Location $RepoRoot
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("groundmesh-behavior-atlas-restore-" + [Guid]::NewGuid().ToString('N'))
try {
  & git cat-file -e "${rollbackRef}^{commit}" 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw "Rollback ref $rollbackRef is not available in this checkout. CI must fetch repository history before running the drill."
  }

  $baselinePaths = @(& git ls-tree -r --name-only $rollbackRef -- docs/behavior-atlas)
  if ($LASTEXITCODE -ne 0 -or $baselinePaths.Count -lt 1) { throw "Could not enumerate Behavior Atlas at rollback ref $rollbackRef." }

  $baselineRoot = Join-Path $tempRoot "baseline"
  New-Item -ItemType Directory -Force -Path $baselineRoot | Out-Null
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

  foreach ($path in $baselinePaths) {
    $prefix = 'docs/behavior-atlas/'
    if (-not $path.StartsWith($prefix)) { continue }
    $relative = $path.Substring($prefix.Length)
    $dest = Join-Path $baselineRoot $relative
    $destDir = Split-Path -Parent $dest
    if ($destDir -and -not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    $content = (& git show "${rollbackRef}:$path") -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Failed to reconstruct $path from $rollbackRef." }
    [System.IO.File]::WriteAllText($dest, $content + "`n", $utf8NoBom)
  }

  $expectedPreviews = @(
    'preview/smokovac-matesevo.html',
    'preview/elizabeth-line-crossrail.html',
    'preview/room-for-river-waal.html'
  )
  foreach ($relative in $expectedPreviews) {
    if (-not (Test-Path (Join-Path $baselineRoot $relative))) {
      throw "Rollback baseline is missing expected guarded preview: $relative"
    }
  }

  $mustBeAbsent = @(
    'index.html',
    'cases/smokovac-matesevo.html',
    'cases/elizabeth-line-crossrail.html',
    'cases/room-for-river-waal.html',
    'releases/m4-public-alpha-v0.1.json'
  )
  foreach ($relative in $mustBeAbsent) {
    if (Test-Path (Join-Path $baselineRoot $relative)) {
      throw "Rollback baseline unexpectedly contains M4 public-alpha path: $relative"
    }
  }

  # Simulate withdrawal in an isolated workspace: replace the current public-alpha tree
  # with the reconstructed last-known-good pre-alpha Behavior Atlas tree.
  $candidateRoot = Join-Path $tempRoot "candidate"
  Copy-Item -Path (Join-Path $RepoRoot 'docs/behavior-atlas') -Destination $candidateRoot -Recurse
  if (-not (Test-Path (Join-Path $candidateRoot 'index.html'))) {
    throw "Candidate public-alpha front door is missing before simulated withdrawal."
  }
  Remove-Item -Path $candidateRoot -Recurse -Force
  Copy-Item -Path $baselineRoot -Destination $candidateRoot -Recurse

  if (Test-Path (Join-Path $candidateRoot 'index.html')) {
    throw "Simulated restore failed: public-alpha front door still exists."
  }
  foreach ($relative in $expectedPreviews) {
    if (-not (Test-Path (Join-Path $candidateRoot $relative))) {
      throw "Simulated restore failed: prior preview missing after restore: $relative"
    }
  }

  Write-Host "Behavior Atlas restore drill OK"
  Write-Host "Reconstructed rollback ref: $rollbackRef"
  Write-Host "Verified public-alpha front door/case routes withdraw while prior guarded previews remain."
}
finally {
  Pop-Location
  if (Test-Path $tempRoot) { Remove-Item -Path $tempRoot -Recurse -Force }
}
