param(
  [switch]$AllowOpenSurface,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

$ChecklistPath = "docs/checklists/Needs_Offers_Readiness_Checklist.md"
$RegistryPath = "docs/atlas/registry.json"
$StatusPath = "docs/data/status.json"
$ClosedSurfacePaths = @(
  ".github/ISSUE_TEMPLATE/need_offer.yml",
  "docs/needs-offers.html",
  "docs/data/needs-offers.json"
)

$RequiredRegistryEntries = [ordered]@{
  "CHECKLIST-NEEDS-OFFERS-READINESS" = $ChecklistPath
  "SCRIPT-NEEDS-OFFERS-READINESS-GUARD" = "scripts/needs-offers-readiness-guard.ps1"
}

$RequiredChecklistMarkers = @(
  "not an emergency service",
  "not a confidential intake channel",
  "data-processing record",
  "No autonomous allocation",
  "No person-worth",
  "No public ranking",
  "rollback",
  "human steward sign-off",
  "Stop Conditions"
)

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

$errors = New-Object System.Collections.Generic.List[string]

$checklistAbs = Join-Path $RepoRoot $ChecklistPath
if (-not (Test-Path -LiteralPath $checklistAbs -PathType Leaf)) {
  $errors.Add("Missing needs/offers checklist: $ChecklistPath")
}
else {
  $checklistText = Get-Content -LiteralPath $checklistAbs -Raw
  foreach ($marker in $RequiredChecklistMarkers) {
    if ($checklistText.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("Needs/offers checklist is missing marker: $marker")
    }
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

$statusAbs = Join-Path $RepoRoot $StatusPath
$status = Get-SafeJson $statusAbs
if ($null -eq $status) {
  $errors.Add("Public status JSON is missing or invalid.")
}
else {
  $components = Get-JsonProperty $status "components"
  $needsOffers = Get-JsonProperty $components "needs_offers_public_intake"
  if ($null -eq $needsOffers) {
    $errors.Add("docs/data/status.json must include needs_offers_public_intake.")
  }
  else {
    $needsOffersStatus = Get-JsonProperty $needsOffers "status" ""
    $needsOffersNote = Get-JsonProperty $needsOffers "note" ""
    if ($needsOffersStatus -ne "yellow") {
      $errors.Add("needs_offers_public_intake status must remain yellow until a real release gate is passed.")
    }
    if ($needsOffersNote.IndexOf("not open", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("needs_offers_public_intake note must say the public intake is not open.")
    }
  }
}

if (-not $AllowOpenSurface) {
  foreach ($relPath in $ClosedSurfacePaths) {
    $abs = Join-Path $RepoRoot $relPath
    if (Test-Path -LiteralPath $abs) {
      $errors.Add("Public needs/offers surface is present while gate is closed: $relPath")
    }
  }
}

if ($errors.Count -gt 0) {
  throw (($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine)
}

if (-not $Quiet) {
  Write-Host "Needs/offers readiness guard OK"
}
