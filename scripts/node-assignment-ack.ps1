param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$ClaimsPath = "",
  [string]$OutboxPath = "",
  [string]$AckFeedPath = "docs/data/public-node-acks.json",
  [string]$AssignmentId = "",
  [string]$ClaimId = "",
  [ValidateSet("completed","released","refused","expired","error")]
  [string]$Disposition = "completed",
  [ValidateSet("ok","warn","error")]
  [string]$Status = "ok",
  [string]$Note = "",
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

function ConvertTo-UtcDateTime {
  param([object]$Value)
  if ($Value -is [DateTime]) { return $Value.ToUniversalTime() }
  if ($Value -is [DateTimeOffset]) { return $Value.UtcDateTime }
  return [DateTimeOffset]::Parse(
    [string]$Value,
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Globalization.DateTimeStyles]::RoundtripKind
  ).UtcDateTime
}

$root = Resolve-RepoRoot
$absManifest = Join-Path $root $ManifestPath
if (-not (Test-Path $absManifest)) {
  throw "Manifest not found at $absManifest. Run .\scripts\node-agent-init.ps1 first."
}

$manifest = Get-Content -Raw -Path $absManifest | ConvertFrom-Json -AsHashtable
$effectiveClaims = if ($ClaimsPath) { $ClaimsPath } else { $manifest.paths.claims_path }
$effectiveOutbox = if ($OutboxPath) { $OutboxPath } else { $manifest.paths.outbox_path }
$absClaims = Join-Path $root $effectiveClaims
$absOutbox = Join-Path $root $effectiveOutbox

if (-not (Test-Path $absClaims)) {
  throw "Claims feed not found at $absClaims. Run .\scripts\node-assignment-claim.ps1 first."
}

$claimFeed = Get-Content -Raw -Path $absClaims | ConvertFrom-Json -AsHashtable
$candidateClaims = @($claimFeed.claims | Where-Object { $_.node_id -eq $manifest.node_id })
if ($AssignmentId) {
  $candidateClaims = @($candidateClaims | Where-Object { $_.assignment_id -eq $AssignmentId })
}
if ($ClaimId) {
  $candidateClaims = @($candidateClaims | Where-Object { $_.claim_id -eq $ClaimId })
}
if ($candidateClaims.Count -eq 0) {
  throw "No matching local claims were found for acknowledgement."
}

$claim = $candidateClaims |
  Sort-Object { ConvertTo-UtcDateTime $_.claimed_at_utc } -Descending |
  Select-Object -First 1

if ($claim.status -ne "claimed") {
  throw "Claim '$($claim.claim_id)' is already in status '$($claim.status)'. Acknowledgements should resolve active claims."
}

$result = $null
if (Test-Path $absOutbox) {
  $outbox = Get-Content -Raw -Path $absOutbox | ConvertFrom-Json -AsHashtable
  $candidateResults = @($outbox.results | Where-Object { $_.assignment_id -eq $claim.assignment_id -and $_.node_id -eq $manifest.node_id })
  if ($candidateResults.Count -gt 0) {
    $result = $candidateResults |
      Sort-Object { ConvertTo-UtcDateTime $_.recorded_at_utc } -Descending |
      Select-Object -First 1
  }
}

if ($Disposition -eq "completed" -and -not $result) {
  throw "Completed acknowledgement requires a local result entry for assignment '$($claim.assignment_id)'."
}

$acknowledgedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$ack = [ordered]@{
  protocol_version = "gm.node.v1"
  ack_id = "ack-" + ([guid]::NewGuid().ToString("N").Substring(0, 12))
  claim_id = $claim.claim_id
  assignment_id = $claim.assignment_id
  node_id = $manifest.node_id
  acknowledged_at_utc = $acknowledgedAt
  disposition = $Disposition
  status = $Status
}
if ($result) {
  $ack.result_id = $result.result_id
}
if ($Note) {
  $ack.note = $Note
} else {
  $ack.note = "Local light node acknowledged the claim after recording the bounded assignment outcome."
}

$localPath = Join-Path $root $manifest.paths.acks_path
$feed = if (Test-Path $localPath) {
  Get-Content -Raw -Path $localPath | ConvertFrom-Json -AsHashtable
} else {
  [ordered]@{
    protocol_version = "gm.node.v1"
    updated_utc = $acknowledgedAt
    node_id = $manifest.node_id
    source_path = $AckFeedPath
    acknowledgements = @()
  }
}

$acks = @($feed.acknowledgements)
$acks += $ack
$feed.updated_utc = $acknowledgedAt
$feed.node_id = $manifest.node_id
$feed.source_path = $AckFeedPath
$feed.acknowledgements = $acks
Write-Utf8NoBom -Path $localPath -Content ($feed | ConvertTo-Json -Depth 8)

if ($MirrorToPublicFeed) {
  $absPublicFeed = Join-Path $root $AckFeedPath
  if (-not (Test-Path $absPublicFeed)) {
    throw "Public acknowledgement feed not found at $absPublicFeed."
  }
  $publicFeed = Get-Content -Raw -Path $absPublicFeed | ConvertFrom-Json -AsHashtable
  $publicAcks = @($publicFeed.acknowledgements)
  $publicAcks += $ack
  $publicFeed.updated_utc = $acknowledgedAt
  $publicFeed.acknowledgements = $publicAcks
  Write-Utf8NoBom -Path $absPublicFeed -Content ($publicFeed | ConvertTo-Json -Depth 8)
}

Write-Output ($feed | ConvertTo-Json -Depth 8)
