param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$InboxPath = "",
  [string]$AssignmentId = "",
  [ValidateSet("accepted","completed","refused","expired","error")]
  [string]$Disposition = "completed",
  [ValidateSet("ok","warn","error")]
  [string]$Status = "ok",
  [string]$Summary = "Processed a bounded public GroundMesh assignment.",
  [string[]]$Notes = @(),
  [string]$OutPath = ""
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

$artifactBase = if ($assignment.payload.workspace_root) { $assignment.payload.workspace_root } else { $manifest.paths.workspace_root }
$result = [ordered]@{
  protocol_version = "gm.node.v1"
  result_id = "res-" + ([guid]::NewGuid().ToString("N").Substring(0, 12))
  assignment_id = $assignment.assignment_id
  contract_id = $assignment.contract_id
  node_id = $manifest.node_id
  recorded_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  disposition = $Disposition
  status = $Status
  summary = $Summary
  artifacts = @(
    [ordered]@{
      kind = "local_report"
      path = (Join-Path $artifactBase ("assignment-{0}.json" -f $assignment.assignment_id))
    }
  )
  notes = [string[]]($(if ($Notes.Count -gt 0) { $Notes } else { "Recorded from local light-node outbox." }))
}

$targetPath = if ($OutPath) { $OutPath } else { $manifest.paths.outbox_path }
$absTarget = Join-Path $root $targetPath
$targetDir = Split-Path $absTarget -Parent
if (-not (Test-Path $targetDir)) {
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
}

$feed = if (Test-Path $absTarget) {
  try {
    Get-Content -Raw -Path $absTarget | ConvertFrom-Json -AsHashtable
  } catch {
    $null
  }
} else {
  $null
}

if (-not $feed) {
  $feed = [ordered]@{
    protocol_version = "gm.node.v1"
    updated_utc = $result.recorded_at_utc
    node_id = $manifest.node_id
    source_path = $effectiveInbox
    results = @()
  }
}

$feed.updated_utc = $result.recorded_at_utc
$feed.node_id = $manifest.node_id
if (-not $feed.source_path) {
  $feed.source_path = $effectiveInbox
}
$results = @()
foreach ($existing in @($feed.results)) {
  if ($null -eq $existing.notes) {
    $existing.notes = @()
  } elseif ($existing.notes -is [string]) {
    $existing.notes = @([string]$existing.notes)
  } else {
    $existing.notes = [string[]]@($existing.notes)
  }
  $results += $existing
}
$results += $result
$feed.results = $results

$json = $feed | ConvertTo-Json -Depth 8
Write-Utf8NoBom -Path $absTarget -Content $json
Write-Output $json
