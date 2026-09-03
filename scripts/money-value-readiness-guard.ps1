param(
  [switch]$AllowOpenSurface,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

$ChecklistPath = "docs/checklists/Money_Value_Exchange_Readiness_Checklist.md"
$RegistryPath = "docs/atlas/registry.json"
$StatusPath = "docs/data/status.json"
$LegalReadinessPath = "docs/legal/LEGAL_READINESS.md"
$ComputeVolunteerPath = "docs/donate-cycles.html"

$ClosedSurfacePaths = @(
  "docs/seed_vault",
  "scripts/seed-vault-validate.ps1",
  "docs/mcr.html",
  "docs/value-flow.html",
  "docs/money-flow.html",
  "docs/data/mcr.json",
  "docs/data/money-flows.json",
  "docs/data/value-flows.json",
  ".github/ISSUE_TEMPLATE/funding.yml",
  ".github/ISSUE_TEMPLATE/donation.yml"
)

$RequiredRegistryEntries = [ordered]@{
  "CHECKLIST-MONEY-VALUE-EXCHANGE-READINESS" = $ChecklistPath
  "SCRIPT-MONEY-VALUE-READINESS-GUARD" = "scripts/money-value-readiness-guard.ps1"
}

$RequiredChecklistMarkers = @(
  "not legal advice",
  "qualified lawyer",
  "no expectation of profit",
  "No token",
  "wallet",
  "fiat bridge",
  "no custody of funds",
  "tax/accounting posture",
  "refund/error handling",
  "anti-fraud",
  "Stop Conditions"
)

$RequiredLegalAnchors = @(
  "sec.gov",
  "fincen.gov",
  "irs.gov",
  "eur-lex.europa.eu/eli/reg/2023/1114"
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
  $errors.Add("Missing money/value checklist: $ChecklistPath")
}
else {
  $checklistText = Get-Content -LiteralPath $checklistAbs -Raw
  foreach ($marker in $RequiredChecklistMarkers) {
    if ($checklistText.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("Money/value checklist is missing marker: $marker")
    }
  }
}

$legalAbs = Join-Path $RepoRoot $LegalReadinessPath
if (-not (Test-Path -LiteralPath $legalAbs -PathType Leaf)) {
  $errors.Add("Missing legal readiness note: $LegalReadinessPath")
}
else {
  $legalText = Get-Content -LiteralPath $legalAbs -Raw
  foreach ($anchor in $RequiredLegalAnchors) {
    if ($legalText.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("Legal readiness note is missing official money/value anchor: $anchor")
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
  $moneyValue = Get-JsonProperty $components "money_value_exchange_gate"
  if ($null -eq $moneyValue) {
    $errors.Add("docs/data/status.json must include money_value_exchange_gate.")
  }
  else {
    $moneyValueStatus = Get-JsonProperty $moneyValue "status" ""
    $moneyValueNote = Get-JsonProperty $moneyValue "note" ""
    if ($moneyValueStatus -ne "yellow") {
      $errors.Add("money_value_exchange_gate status must remain yellow until a real release gate is passed.")
    }
    if ($moneyValueNote.IndexOf("not open", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("money_value_exchange_gate note must say money/value exchange is not open.")
    }
  }
}

$computeAbs = Join-Path $RepoRoot $ComputeVolunteerPath
if (Test-Path -LiteralPath $computeAbs -PathType Leaf) {
  $computeText = Get-Content -LiteralPath $computeAbs -Raw
  foreach ($marker in @("not a payment", "no token", "no credit")) {
    if ($computeText.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("Compute-cycle volunteer page must clarify: $marker")
    }
  }
}

if (-not $AllowOpenSurface) {
  foreach ($relPath in $ClosedSurfacePaths) {
    $abs = Join-Path $RepoRoot $relPath
    if (Test-Path -LiteralPath $abs) {
      $errors.Add("Money/value or seed-vault surface is present while gate is closed: $relPath")
    }
  }
}

if ($errors.Count -gt 0) {
  throw (($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine)
}

if (-not $Quiet) {
  Write-Host "Money/value readiness guard OK"
}
