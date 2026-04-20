param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$InboxPath = "",
  [string]$ClaimsFeedPath = "docs/data/public-node-claims.json",
  [string]$AssignmentId = "",
  [int]$ClaimTtlMinutes = 15,
  [switch]$MirrorToPublicFeed
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

$absClaimsFeed = Join-Path $root $ClaimsFeedPath
if (-not (Test-Path $absClaimsFeed)) {
  throw "Claims feed not found at $absClaimsFeed."
}

$claimFeed = Get-Content -Raw -Path $absClaimsFeed | ConvertFrom-Json -AsHashtable
$nowUtc = [DateTime]::UtcNow
$activeOtherClaim = $false
foreach ($claim in @($claimFeed.claims)) {
  if ($claim.assignment_id -ne $assignment.assignment_id) { continue }
  if ($claim.status -ne "claimed") { continue }

  $claimedAt = if ($claim.claimed_at_utc -is [DateTime]) {
    $claim.claimed_at_utc.ToUniversalTime()
  } else {
    [DateTimeOffset]::Parse([string]$claim.claimed_at_utc, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind).UtcDateTime
  }

  if ($claimedAt.AddMinutes([double]$claim.claim_ttl_minutes) -gt $nowUtc -and $claim.node_id -ne $manifest.node_id) {
    $activeOtherClaim = $true
    break
  }
}

if ($activeOtherClaim) {
  throw "Assignment '$($assignment.assignment_id)' already has an active public claim from another node."
}

$claim = [ordered]@{
  protocol_version = "gm.node.v1"
  claim_id = "clm-" + ([guid]::NewGuid().ToString("N").Substring(0, 12))
  assignment_id = $assignment.assignment_id
  node_id = $manifest.node_id
  claimed_at_utc = $nowUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
  claim_ttl_minutes = $ClaimTtlMinutes
  status = "claimed"
  note = "Local light node claimed the assignment for bounded execution."
}

$localPath = Join-Path $root $manifest.paths.claims_path
$localFeed = if (Test-Path $localPath) {
  Get-Content -Raw -Path $localPath | ConvertFrom-Json -AsHashtable
} else {
  [ordered]@{
    protocol_version = "gm.node.v1"
    updated_utc = $claim.claimed_at_utc
    node_id = $manifest.node_id
    source_path = $ClaimsFeedPath
    claims = @()
  }
}

$localClaims = @($localFeed.claims)
$localClaims += $claim
$localFeed.updated_utc = $claim.claimed_at_utc
$localFeed.node_id = $manifest.node_id
$localFeed.source_path = $ClaimsFeedPath
$localFeed.claims = $localClaims
Write-Utf8NoBom -Path $localPath -Content ($localFeed | ConvertTo-Json -Depth 8)

if ($MirrorToPublicFeed) {
  $publicClaims = @($claimFeed.claims)
  $publicClaims += $claim
  $claimFeed.updated_utc = $claim.claimed_at_utc
  $claimFeed.claims = $publicClaims
  Write-Utf8NoBom -Path $absClaimsFeed -Content ($claimFeed | ConvertTo-Json -Depth 8)
}

Write-Output ($localFeed | ConvertTo-Json -Depth 8)
