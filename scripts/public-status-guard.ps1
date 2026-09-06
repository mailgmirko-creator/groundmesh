param(
  [switch]$AllowIPFSMirrorEnabled,
  [switch]$AllowHumanMeshH3Green,
  [switch]$AllowNeedsOffersOpen,
  [switch]$AllowMoneyValueOpen,
  [switch]$AllowBalanceEnginePublicAuthority,
  [switch]$AllowBroadRegistration,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StatusPath = "docs/data/status.json"
$RegistryPath = "docs/atlas/registry.json"
$AllowedStatuses = @("green", "yellow", "red")

$RequiredComponents = @(
  "deployment_source",
  "active_lane_certification",
  "public_status_guard",
  "release_artifact",
  "ipfs_mirror",
  "home_page",
  "world_page",
  "pwa_shell",
  "node_queue",
  "node_claims",
  "node_acks",
  "contributors_page",
  "registration_page",
  "registration_checklist",
  "human_mesh_h0",
  "human_mesh_h1",
  "human_mesh_h2_limited_invitation",
  "human_mesh_h3_multi_steward",
  "get_started_page",
  "map_page",
  "contact_page",
  "privacy_page",
  "landscape_page",
  "compute_page",
  "atlas_page",
  "coordination_stage_b",
  "needs_offers_public_intake",
  "money_value_exchange_gate",
  "balance_engine_boundary",
  "behavior_atlas_m2",
  "behavior_atlas_m3",
  "behavior_atlas_m4_public_alpha"
)

$RequiredRegistryEntries = [ordered]@{
  "STATUS-PUBLIC" = $StatusPath
  "SCRIPT-PUBLIC-STATUS-GUARD" = "scripts/public-status-guard.ps1"
}

function Get-SafeJson {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  try {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100
  }
  catch {
    return $null
  }
}

function Get-JsonProperty {
  param(
    [object]$Object,
    [string]$Name,
    [object]$Default = $null
  )

  if ($null -eq $Object) { return $Default }
  $prop = $Object.PSObject.Properties[$Name]
  if ($null -eq $prop) { return $Default }
  if ($null -eq $prop.Value) { return $Default }
  return $prop.Value
}

function Assert-NoteContains {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [string]$ComponentName,
    [object]$Component,
    [string[]]$Markers
  )

  $note = [string](Get-JsonProperty $Component "note" "")
  foreach ($marker in $Markers) {
    if ($note.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $Errors.Add("$ComponentName note must mention: $marker")
    }
  }
}

function Assert-Status {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [string]$ComponentName,
    [object]$Component,
    [string]$ExpectedStatus,
    [bool]$AllowedToDiffer
  )

  $actualStatus = [string](Get-JsonProperty $Component "status" "")
  if ($actualStatus -ne $ExpectedStatus -and -not $AllowedToDiffer) {
    $Errors.Add("$ComponentName status must remain $ExpectedStatus until its explicit release gate changes.")
  }
}

$errors = New-Object System.Collections.Generic.List[string]

$statusAbs = Join-Path $RepoRoot $StatusPath
$statusText = if (Test-Path -LiteralPath $statusAbs -PathType Leaf) {
  Get-Content -LiteralPath $statusAbs -Raw
}
else {
  ""
}
$status = Get-SafeJson $statusAbs
if ($null -eq $status) {
  throw "Public status JSON is missing or invalid: $StatusPath"
}

$updatedMatch = [regex]::Match($statusText, '"updated_utc"\s*:\s*"([^"]+)"')
$updatedUtc = if ($updatedMatch.Success) { $updatedMatch.Groups[1].Value } else { "" }
if ($updatedUtc -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') {
  $errors.Add("updated_utc must use exact UTC form yyyy-MM-ddTHH:mm:ssZ.")
}
else {
  try {
    [void][System.DateTimeOffset]::Parse(
      $updatedUtc,
      [System.Globalization.CultureInfo]::InvariantCulture,
      [System.Globalization.DateTimeStyles]::AssumeUniversal
    )
  }
  catch {
    $errors.Add("updated_utc is not parseable as a UTC timestamp: $updatedUtc")
  }
}

$components = Get-JsonProperty $status "components"
if ($null -eq $components) {
  $errors.Add("docs/data/status.json must contain a components object.")
}
else {
  foreach ($required in $RequiredComponents) {
    if ($null -eq (Get-JsonProperty $components $required)) {
      $errors.Add("docs/data/status.json is missing required component: $required")
    }
  }

  foreach ($componentProp in $components.PSObject.Properties) {
    $name = $componentProp.Name
    $component = $componentProp.Value
    $componentStatus = [string](Get-JsonProperty $component "status" "")
    $componentNote = [string](Get-JsonProperty $component "note" "")

    if ($AllowedStatuses -notcontains $componentStatus) {
      $errors.Add("$name has invalid status '$componentStatus'; expected one of: $($AllowedStatuses -join ', ').")
    }
    if ([string]::IsNullOrWhiteSpace($componentNote)) {
      $errors.Add("$name must include a non-empty note.")
    }
  }

  $deployment = Get-JsonProperty $components "deployment_source"
  if ($null -ne $deployment) {
    Assert-Status $errors "deployment_source" $deployment "green" $false
    Assert-NoteContains $errors "deployment_source" $deployment @("GitHub Pages", "docs-based")
  }

  $activeCert = Get-JsonProperty $components "active_lane_certification"
  if ($null -ne $activeCert) {
    Assert-Status $errors "active_lane_certification" $activeCert "green" $false
    Assert-NoteContains $errors "active_lane_certification" $activeCert @("non-mutating", "pre-push", "core guardrails")
  }

  $statusGuard = Get-JsonProperty $components "public_status_guard"
  if ($null -ne $statusGuard) {
    Assert-Status $errors "public_status_guard" $statusGuard "green" $false
    Assert-NoteContains $errors "public_status_guard" $statusGuard @("public status", "CI", "closed gates")
  }

  $ipfs = Get-JsonProperty $components "ipfs_mirror"
  if ($null -ne $ipfs) {
    Assert-Status $errors "ipfs_mirror" $ipfs "yellow" $AllowIPFSMirrorEnabled
    if (-not $AllowIPFSMirrorEnabled) {
      Assert-NoteContains $errors "ipfs_mirror" $ipfs @("not enabled", "GitHub Pages remains canonical")
    }
  }

  $registration = Get-JsonProperty $components "registration_page"
  if ($null -ne $registration -and -not $AllowBroadRegistration) {
    Assert-NoteContains $errors "registration_page" $registration @("still-closed global invitation")
  }

  $h2 = Get-JsonProperty $components "human_mesh_h2_limited_invitation"
  if ($null -ne $h2 -and -not $AllowBroadRegistration) {
    Assert-NoteContains $errors "human_mesh_h2_limited_invitation" $h2 @("off by default", "global open registration remains closed")
  }

  $h3 = Get-JsonProperty $components "human_mesh_h3_multi_steward"
  if ($null -ne $h3) {
    Assert-Status $errors "human_mesh_h3_multi_steward" $h3 "yellow" $AllowHumanMeshH3Green
    if (-not $AllowHumanMeshH3Green) {
      Assert-NoteContains $errors "human_mesh_h3_multi_steward" $h3 @("Synthetic reviewers", "at least two real human reviewers")
    }
  }

  $needsOffers = Get-JsonProperty $components "needs_offers_public_intake"
  if ($null -ne $needsOffers) {
    Assert-Status $errors "needs_offers_public_intake" $needsOffers "yellow" $AllowNeedsOffersOpen
    if (-not $AllowNeedsOffersOpen) {
      Assert-NoteContains $errors "needs_offers_public_intake" $needsOffers @("not open", "no issue template", "public data feed")
    }
  }

  $moneyValue = Get-JsonProperty $components "money_value_exchange_gate"
  if ($null -ne $moneyValue) {
    Assert-Status $errors "money_value_exchange_gate" $moneyValue "yellow" $AllowMoneyValueOpen
    if (-not $AllowMoneyValueOpen) {
      Assert-NoteContains $errors "money_value_exchange_gate" $moneyValue @("not open", "no Mesh Credit", "payment")
    }
  }

  $balanceEngine = Get-JsonProperty $components "balance_engine_boundary"
  if ($null -ne $balanceEngine) {
    Assert-Status $errors "balance_engine_boundary" $balanceEngine "yellow" $AllowBalanceEnginePublicAuthority
    if (-not $AllowBalanceEnginePublicAuthority) {
      Assert-NoteContains $errors "balance_engine_boundary" $balanceEngine @("experimental local runtime", "not a public authority", "no autonomous allocation")
    }
  }

  $m2 = Get-JsonProperty $components "behavior_atlas_m2"
  if ($null -ne $m2) {
    Assert-NoteContains $errors "behavior_atlas_m2" $m2 @("outside the public Pages tree")
  }

  $m3 = Get-JsonProperty $components "behavior_atlas_m3"
  if ($null -ne $m3) {
    Assert-NoteContains $errors "behavior_atlas_m3" $m3 @("unlisted", "noindex")
  }

  $m4 = Get-JsonProperty $components "behavior_atlas_m4_public_alpha"
  if ($null -ne $m4) {
    Assert-NoteContains $errors "behavior_atlas_m4_public_alpha" $m4 @("correction paths", "restore drill", "no scoring", "autonomous monitoring")
  }
}

$registryAbs = Join-Path $RepoRoot $RegistryPath
$registry = Get-SafeJson $registryAbs
if ($null -eq $registry) {
  $errors.Add("Atlas registry is missing or invalid JSON.")
}
else {
  $entries = @((Get-JsonProperty $registry "entries" @()))
  foreach ($id in $RequiredRegistryEntries.Keys) {
    $expectedPath = $RequiredRegistryEntries[$id]
    $match = @($entries | Where-Object { (Get-JsonProperty $_ "id" "") -eq $id })
    if ($match.Count -ne 1) {
      $errors.Add("Atlas registry must contain exactly one $id entry.")
      continue
    }

    $actualPath = Get-JsonProperty $match[0] "path" ""
    if ($actualPath -ne $expectedPath) {
      $errors.Add("Atlas entry $id must point to $expectedPath, found $actualPath.")
    }
  }
}

if ($errors.Count -gt 0) {
  throw (($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine)
}

if (-not $Quiet) {
  Write-Host "Public status guard OK"
}
