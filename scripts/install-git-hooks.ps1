param(
  [switch]$CheckOnly,
  [switch]$AllowSharedWorktreeConfig
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$RepoRoot = (& git rev-parse --show-toplevel).Trim()
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  throw "Could not resolve repository root."
}

$hookFile = Join-Path $RepoRoot ".githooks/pre-push"
if (-not (Test-Path $hookFile)) {
  throw "Tracked pre-push hook not found: $hookFile"
}

$hookText = Get-Content $hookFile -Raw
$requiredMarkers = @(
  "refs/heads/main",
  "Blocked: direct push to main"
)

foreach ($marker in $requiredMarkers) {
  if ($hookText -notmatch [regex]::Escape($marker)) {
    throw "Tracked pre-push hook is missing marker: $marker"
  }
}

$currentHooksPath = (& git -C $RepoRoot config --get core.hooksPath 2>$null)
if ($null -eq $currentHooksPath) { $currentHooksPath = "" }
$currentHooksPath = ([string]$currentHooksPath).Trim()

if ($CheckOnly) {
  Write-Host "Tracked pre-push hook OK" -ForegroundColor Green
  if ($currentHooksPath -eq ".githooks") {
    Write-Host "core.hooksPath already points to .githooks"
  } elseif ([string]::IsNullOrWhiteSpace($currentHooksPath)) {
    Write-Host "core.hooksPath is not set; run this script without -CheckOnly in the primary checkout to activate local hooks."
  } else {
    Write-Host ("core.hooksPath is currently '{0}'; review before changing it." -f $currentHooksPath)
  }
  exit 0
}

$gitDir = (& git -C $RepoRoot rev-parse --git-dir).Trim()
$gitCommonDir = (& git -C $RepoRoot rev-parse --git-common-dir).Trim()
$isLinkedWorktree = $gitDir -ne $gitCommonDir

if ($isLinkedWorktree -and -not $AllowSharedWorktreeConfig) {
  throw "This is a linked worktree. Run from the primary checkout, or pass -AllowSharedWorktreeConfig after reviewing that the repo-local hook path may affect sibling worktrees."
}

& git -C $RepoRoot config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
  throw "Failed to set core.hooksPath."
}

$afterHooksPath = (& git -C $RepoRoot config --get core.hooksPath).Trim()
if ($afterHooksPath -ne ".githooks") {
  throw "core.hooksPath verification failed; expected .githooks but found '$afterHooksPath'."
}

Write-Host "GroundMesh git hooks installed: core.hooksPath=.githooks" -ForegroundColor Green
exit 0
