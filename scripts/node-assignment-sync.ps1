param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$PublicInboxPath = "docs/data/public-node-inbox.json",
  [string]$OutPath = "",
  [switch]$WriteFile
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

function Has-ConsentForJobClass {
  param(
    [hashtable]$Manifest,
    [string]$JobClass
  )

  switch ($JobClass) {
    "public_state_sync" { return [bool]$Manifest.consent.public_state_sync }
    "public_cache_refresh" { return [bool]$Manifest.consent.public_cache }
    "public_health_probe" { return [bool]$Manifest.consent.public_health_probe }
    "local_tsl_assessment" { return [bool]$Manifest.consent.non_sensitive_compute }
    "non_sensitive_batch" { return [bool]$Manifest.consent.non_sensitive_compute }
    default { return $false }
  }
}

$root = Resolve-RepoRoot
$absManifest = Join-Path $root $ManifestPath
if (-not (Test-Path $absManifest)) {
  throw "Manifest not found at $absManifest. Run .\\scripts\\node-agent-init.ps1 first."
}

$manifest = Get-Content -Raw -Path $absManifest | ConvertFrom-Json -AsHashtable
$absPublicInbox = Join-Path $root $PublicInboxPath
if (-not (Test-Path $absPublicInbox)) {
  throw "Public inbox feed not found at $absPublicInbox."
}

$feed = Get-Content -Raw -Path $absPublicInbox | ConvertFrom-Json -AsHashtable
$nowUtc = [DateTime]::UtcNow
$eligible = @()

foreach ($assignment in @($feed.assignments)) {
  $target = $assignment.target
  $matchesAudience = $false
  switch ($target.audience) {
    "all-light-nodes" {
      $matchesAudience = ($target.node_class -eq $manifest.node_class)
    }
    "node_id" {
      $matchesAudience = ($target.node_class -eq $manifest.node_class -and $target.node_id -eq $manifest.node_id)
    }
    "node_list" {
      $matchesAudience = ($target.node_class -eq $manifest.node_class -and @($target.node_ids) -contains $manifest.node_id)
    }
  }

  if (-not $matchesAudience) { continue }
  if (-not (Has-ConsentForJobClass -Manifest $manifest -JobClass $assignment.job_class)) { continue }

  if ($assignment.expires_at -is [DateTime]) {
    $expiresAt = $assignment.expires_at.ToUniversalTime()
  } elseif ($assignment.expires_at -is [DateTimeOffset]) {
    $expiresAt = $assignment.expires_at.UtcDateTime
  } else {
    $expiresAt = [DateTimeOffset]::Parse(
      [string]$assignment.expires_at,
      [System.Globalization.CultureInfo]::InvariantCulture,
      [System.Globalization.DateTimeStyles]::RoundtripKind
    ).UtcDateTime
  }
  if ($expiresAt -le $nowUtc) { continue }

  $eligible += $assignment
}

$localInbox = [ordered]@{
  protocol_version = "gm.node.v1"
  updated_utc = $nowUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
  issued_by = $feed.issued_by
  node_id = $manifest.node_id
  source_path = $PublicInboxPath
  assignments = $eligible
}

$targetPath = if ($OutPath) { $OutPath } else { $manifest.paths.inbox_path }
$absTarget = Join-Path $root $targetPath
$targetDir = Split-Path $absTarget -Parent
if (-not (Test-Path $targetDir)) {
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
}

$json = $localInbox | ConvertTo-Json -Depth 8
if ($WriteFile -or -not $OutPath) {
  Write-Utf8NoBom -Path $absTarget -Content $json
}
Write-Output $json
