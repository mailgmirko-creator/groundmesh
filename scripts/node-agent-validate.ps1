param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$HeartbeatPath = "private/node_agent/node-heartbeat.latest.json"
)
$ErrorActionPreference = "Stop"

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
$checks = @(
  @{
    Label = "sample_manifest"
    JsonPath = "agents/light-node/manifest.sample.json"
    SchemaPath = "balance_engine/schemas/node_manifest.schema.json"
    Required = $true
  },
  @{
    Label = "sample_heartbeat"
    JsonPath = "agents/light-node/heartbeat.sample.json"
    SchemaPath = "balance_engine/schemas/node_heartbeat.schema.json"
    Required = $true
  },
  @{
    Label = "sample_assignment"
    JsonPath = "agents/light-node/assignment.sample.json"
    SchemaPath = "balance_engine/schemas/node_assignment_envelope.schema.json"
    Required = $true
  },
  @{
    Label = "sample_claim"
    JsonPath = "agents/light-node/claim.sample.json"
    SchemaPath = "balance_engine/schemas/node_assignment_claim.schema.json"
    Required = $true
  },
  @{
    Label = "sample_ack"
    JsonPath = "agents/light-node/ack.sample.json"
    SchemaPath = "balance_engine/schemas/node_assignment_ack.schema.json"
    Required = $true
  },
  @{
    Label = "sample_result"
    JsonPath = "agents/light-node/result.sample.json"
    SchemaPath = "balance_engine/schemas/node_assignment_result.schema.json"
    Required = $true
  },
  @{
    Label = "public_inbox"
    JsonPath = "docs/data/public-node-inbox.json"
    SchemaPath = "balance_engine/schemas/node_assignment_feed.schema.json"
    Required = $true
  },
  @{
    Label = "public_outbox"
    JsonPath = "docs/data/public-node-outbox.json"
    SchemaPath = "balance_engine/schemas/node_result_feed.schema.json"
    Required = $true
  },
  @{
    Label = "public_claims"
    JsonPath = "docs/data/public-node-claims.json"
    SchemaPath = "balance_engine/schemas/node_claim_feed.schema.json"
    Required = $true
  },
  @{
    Label = "public_acks"
    JsonPath = "docs/data/public-node-acks.json"
    SchemaPath = "balance_engine/schemas/node_ack_feed.schema.json"
    Required = $true
  },
  @{
    Label = "local_manifest"
    JsonPath = $ManifestPath
    SchemaPath = "balance_engine/schemas/node_manifest.schema.json"
    Required = $false
  },
  @{
    Label = "local_heartbeat"
    JsonPath = $HeartbeatPath
    SchemaPath = "balance_engine/schemas/node_heartbeat.schema.json"
    Required = $false
  },
  @{
    Label = "local_inbox"
    JsonPath = "private/node_agent/public-node-inbox.latest.json"
    SchemaPath = "balance_engine/schemas/node_assignment_feed.schema.json"
    Required = $false
  },
  @{
    Label = "local_outbox"
    JsonPath = "private/node_agent/public-node-outbox.latest.json"
    SchemaPath = "balance_engine/schemas/node_result_feed.schema.json"
    Required = $false
  },
  @{
    Label = "local_claims"
    JsonPath = "private/node_agent/public-node-claims.latest.json"
    SchemaPath = "balance_engine/schemas/node_claim_feed.schema.json"
    Required = $false
  },
  @{
    Label = "local_acks"
    JsonPath = "private/node_agent/public-node-acks.latest.json"
    SchemaPath = "balance_engine/schemas/node_ack_feed.schema.json"
    Required = $false
  }
)

$rows = @()
$hadFailure = $false

foreach ($check in $checks) {
  $absJson = Join-Path $root $check.JsonPath
  $absSchema = Join-Path $root $check.SchemaPath

  if (-not (Test-Path $absJson)) {
    $note = if ($check.Required) { "missing required file" } else { "skipped (file not present yet)" }
    $valid = -not $check.Required
    if (-not $valid) { $hadFailure = $true }
    $rows += [pscustomobject]@{
      Label = $check.Label
      File = $check.JsonPath
      Valid = $valid
      Note = $note
    }
    continue
  }

  try {
    $json = Get-Content -Raw -Path $absJson
    $valid = $json | Test-Json -SchemaFile $absSchema -ErrorAction Stop
    $note = if ($valid) { "OK" } else { "schema validation failed" }
    if (-not $valid) { $hadFailure = $true }
  } catch {
    $valid = $false
    $note = $_.Exception.Message
    $hadFailure = $true
  }

  $rows += [pscustomobject]@{
    Label = $check.Label
    File = $check.JsonPath
    Valid = $valid
    Note = $note
  }
}

$rows | Format-Table -AutoSize
if ($hadFailure) { exit 1 }
