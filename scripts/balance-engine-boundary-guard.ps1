param(
  [switch]$AllowPublicSurface,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

$SpecPath = "docs/tsl/balance-engine-core-spec.md"
$RegistryPath = "docs/atlas/registry.json"
$StatusPath = "docs/data/status.json"
$AssistantBriefPath = "docs/assistant-brief.md"
$PublicationGatePath = "docs/legal/PUBLICATION_GATE.md"
$ValidatorPath = "scripts/balance-engine-validate.py"

$RequiredFiles = @(
  $SpecPath,
  $ValidatorPath,
  "balance_engine/lib/engine.py",
  "balance_engine/schemas/event.schema.json",
  "balance_engine/schemas/decision.schema.json",
  "balance_engine/event.sample.json"
)

$RequiredSpecMarkers = @(
  "experimental local runtime",
  "not a runtime launch",
  "human review",
  "no public authority",
  "person-worth scores",
  "public rankings",
  "motive inference",
  "enemy labels",
  "autonomous allocation",
  "no automatic publication",
  "money/value gate",
  "remote shell authority",
  "private data",
  "Stop Conditions"
)

$RequiredRegistryEntries = [ordered]@{
  "SPEC-BALANCE-ENGINE-CORE-V0-1" = $SpecPath
  "SCRIPT-BALANCE-ENGINE-VALIDATE" = $ValidatorPath
  "SCRIPT-BALANCE-ENGINE-BOUNDARY-GUARD" = "scripts/balance-engine-boundary-guard.ps1"
}

$ClosedPublicPaths = @(
  "docs/balance-engine.html",
  "docs/data/balance-engine.json",
  "docs/data/tsl.json",
  "docs/tsl/index.html"
)

$RepoRelativeRuntimeRefs = @(
  "balance_engine/test-balance.ps1",
  "balance_engine/start-balance-api.ps1",
  "scripts/tsl-run.ps1",
  "docs/tsl/triad-loop.md"
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

foreach ($relPath in $RequiredFiles) {
  $abs = Join-Path $RepoRoot $relPath
  if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
    $errors.Add("Missing Balance Engine boundary file: $relPath")
  }
}

$specAbs = Join-Path $RepoRoot $SpecPath
if (Test-Path -LiteralPath $specAbs -PathType Leaf) {
  $specText = Get-Content -LiteralPath $specAbs -Raw
  foreach ($marker in $RequiredSpecMarkers) {
    if ($specText.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("Balance Engine spec is missing marker: $marker")
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
  $boundary = Get-JsonProperty $components "balance_engine_boundary"
  if ($null -eq $boundary) {
    $errors.Add("docs/data/status.json must include balance_engine_boundary.")
  }
  else {
    $boundaryStatus = Get-JsonProperty $boundary "status" ""
    $boundaryNote = Get-JsonProperty $boundary "note" ""
    if ($boundaryStatus -ne "yellow") {
      $errors.Add("balance_engine_boundary status must remain yellow until public authority and runtime gates are passed.")
    }
    foreach ($marker in @("experimental local runtime", "not a public authority", "no autonomous allocation")) {
      if ($boundaryNote.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $errors.Add("balance_engine_boundary note must mention: $marker")
      }
    }
  }
}

$assistantAbs = Join-Path $RepoRoot $AssistantBriefPath
if (-not (Test-Path -LiteralPath $assistantAbs -PathType Leaf)) {
  $errors.Add("Missing assistant brief: $AssistantBriefPath")
}
else {
  $assistantText = Get-Content -LiteralPath $assistantAbs -Raw
  foreach ($marker in @("Balance-Engine boundary first", $SpecPath)) {
    if ($assistantText.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("Assistant brief is missing Balance Engine boundary marker: $marker")
    }
  }
}

$publicationAbs = Join-Path $RepoRoot $PublicationGatePath
if (-not (Test-Path -LiteralPath $publicationAbs -PathType Leaf)) {
  $errors.Add("Missing publication gate: $PublicationGatePath")
}
else {
  $publicationText = Get-Content -LiteralPath $publicationAbs -Raw
  foreach ($marker in @("Balance Engine", "autonomous allocation", "person-worth", "money/value gate")) {
    if ($publicationText.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("Publication gate is missing Balance Engine marker: $marker")
    }
  }
}

foreach ($relPath in $RepoRelativeRuntimeRefs) {
  $abs = Join-Path $RepoRoot $relPath
  if (Test-Path -LiteralPath $abs -PathType Leaf) {
    $text = Get-Content -LiteralPath $abs -Raw
    if ($text.IndexOf("C:\Projects\GroundMesh-DEV", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
      $errors.Add("Repo runtime reference must not point at stale C:\Projects\GroundMesh-DEV path: $relPath")
    }
  }
}

if (-not $AllowPublicSurface) {
  foreach ($relPath in $ClosedPublicPaths) {
    $abs = Join-Path $RepoRoot $relPath
    if (Test-Path -LiteralPath $abs) {
      $errors.Add("Balance Engine public docs/data surface is present while gate is closed: $relPath")
    }
  }
}

if ($errors.Count -gt 0) {
  throw (($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine)
}

$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) {
  throw "python command not found; cannot run Balance Engine validator."
}

& $python.Source (Join-Path $RepoRoot $ValidatorPath)
if ($LASTEXITCODE -ne 0) {
  throw "Balance Engine validator failed."
}

if (-not $Quiet) {
  Write-Host "Balance Engine boundary guard OK"
}
