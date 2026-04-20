param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$InboxPath = "",
  [string]$AssignmentId = ""
)
$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
  param([string]$Path, [string]$Content)
  $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
  [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function Resolve-RepoRoot {
  $root = (git rev-parse --show-toplevel) 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $root) {
    if ($PSScriptRoot) {
      return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    }
    return (Get-Location).Path
  }
  return $root
}

$root = Resolve-RepoRoot
$absManifest = Join-Path $root $ManifestPath
if (-not (Test-Path $absManifest)) {
  throw "Manifest not found at $absManifest. Run .\\scripts\\node-agent-init.ps1 first."
}

$manifest = Get-Content -Raw -Path $absManifest | ConvertFrom-Json -AsHashtable
$effectiveInbox = if ($InboxPath) { $InboxPath } else { $manifest.paths.inbox_path }
$absInbox = Join-Path $root $effectiveInbox
if (-not (Test-Path $absInbox)) {
  throw "Inbox feed not found at $absInbox. Run .\\scripts\\node-assignment-sync.ps1 first."
}

$inbox = Get-Content -Raw -Path $absInbox | ConvertFrom-Json -AsHashtable
$assignments = @($inbox.assignments)
if ($assignments.Count -eq 0) {
  throw "Inbox at $absInbox does not contain any assignments."
}

$assignment = if ($AssignmentId) {
  $assignments | Where-Object { $_.assignment_id -eq $AssignmentId } | Select-Object -First 1
} else {
  $assignments | Select-Object -First 1
}

if (-not $assignment) {
  throw "Could not find assignment '$AssignmentId' in $absInbox."
}

if ($assignment.job_class -ne "public_state_sync") {
  throw "Assignment '$($assignment.assignment_id)' is job_class '$($assignment.job_class)', not public_state_sync."
}

$workspaceAbs = Join-Path $root $manifest.paths.workspace_root
$cacheRootRel = if ($assignment.payload.workspace_root) { $assignment.payload.workspace_root } else { "node_cache/public_state/" }
$cacheRootAbs = Join-Path $workspaceAbs $cacheRootRel
if (-not (Test-Path $cacheRootAbs)) {
  New-Item -ItemType Directory -Force -Path $cacheRootAbs | Out-Null
}

$copied = @()
$totalBytes = 0
foreach ($source in @($assignment.payload.sources)) {
  $absSource = Join-Path $root $source
  if (-not (Test-Path $absSource)) {
    throw "Source not found: $absSource"
  }

  $targetAbs = Join-Path $cacheRootAbs $source
  $targetDir = Split-Path $targetAbs -Parent
  if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
  }

  $bytes = [System.IO.File]::ReadAllBytes($absSource)
  [System.IO.File]::WriteAllBytes($targetAbs, $bytes)
  $totalBytes += $bytes.Length

  $copied += [ordered]@{
    source = $source
    cached_path = $targetAbs.Substring($root.Length + 1).Replace('\', '/')
    bytes = $bytes.Length
  }
}

$reportRel = Join-Path $cacheRootRel ("assignment-{0}.json" -f $assignment.assignment_id)
$reportAbs = Join-Path $workspaceAbs $reportRel
$reportDir = Split-Path $reportAbs -Parent
if (-not (Test-Path $reportDir)) {
  New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}

$report = [ordered]@{
  protocol_version = "gm.node.v1"
  node_id = $manifest.node_id
  assignment_id = $assignment.assignment_id
  job_class = $assignment.job_class
  synced_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  copied_files = $copied
  bytes_copied = $totalBytes
}

$json = $report | ConvertTo-Json -Depth 8
Write-Utf8NoBom -Path $reportAbs -Content $json
Write-Output $json
