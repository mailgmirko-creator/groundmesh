param(
  [string]$OutDir = "private/steward",
  [int]$TopFiles = 12,
  [switch]$CheckOnly,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$NowUtc = (Get-Date).ToUniversalTime().ToString("o")

$Streams = [ordered]@{
  commons = @("commons", "public", "shared", "contributor", "open", "access")
  balance = @("balance", "tranquility", "care", "dignity", "compassion", "de-escalation")
  structure = @("atlas", "contract", "schema", "checklist", "protocol", "registry")
  stewardship = @("steward", "stewardship", "local-first", "node", "accountability", "reversibility")
  learning = @("learn", "principle", "chat", "export", "TSL", "signal", "model")
  refusal = @("refusal", "capture", "coercion", "privacy", "consent", "boundary")
  legal = @("legal", "publication", "license", "liability", "counsel", "disclosure")
}

$AnchorPaths = @(
  "README.md",
  "docs/assistant-brief.md",
  "docs/decisions/0008-legal-readiness-and-release-gates.md",
  "docs/legal/PUBLICATION_GATE.md",
  "docs/atlas/registry.json",
  "docs/data/status.json",
  "docs/atlas/groundmesh-new-chat-handoff.md",
  "docs/atlas/steward-loop.md",
  "docs/protocols/TP-04.md",
  "docs/ONE_LOOP.md",
  "docs/atlas/light-node-agent-contract.md",
  "docs/coordination/coordination-field.md",
  "docs/human-mesh/foundation-v0.1.md",
  "docs/behavior-atlas/PATTERNS_NOT_ENEMIES.md",
  "apps/tsl/principles/principles.yaml"
)

$RequiredRegistryEntries = [ordered]@{
  "GUIDE-STEWARD-LOOP" = "docs/atlas/steward-loop.md"
  "SCRIPT-GROUNDMESH-STEWARD" = "scripts/groundmesh-steward.ps1"
  "TP-04" = "docs/protocols/TP-04.md"
}

function ConvertTo-RepoRelativePath {
  param([string]$Path)

  $full = [System.IO.Path]::GetFullPath($Path)
  $root = ([System.IO.Path]::GetFullPath($RepoRoot)).TrimEnd([char[]]@("\", "/"))
  if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $full.Substring($root.Length).TrimStart([char[]]@("\", "/")) -replace "\\", "/"
  }
  return $full
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

function Assert-LocalOutDir {
  if ([System.IO.Path]::IsPathRooted($OutDir)) {
    throw "OutDir must be repo-relative and under private/steward."
  }

  $normalized = ($OutDir -replace "\\", "/").Trim("/")
  $normalizedLower = $normalized.ToLowerInvariant()
  if ($normalizedLower -ne "private/steward" -and -not $normalizedLower.StartsWith("private/steward/")) {
    throw "OutDir must stay under private/steward."
  }
}

function Test-StewardGuardrails {
  $errors = New-Object System.Collections.Generic.List[string]

  Assert-LocalOutDir

  foreach ($relPath in $AnchorPaths) {
    $abs = Join-Path $RepoRoot $relPath
    if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
      $errors.Add("Missing steward anchor: $relPath")
    }
  }

  $gitignorePath = Join-Path $RepoRoot ".gitignore"
  if (-not (Test-Path -LiteralPath $gitignorePath -PathType Leaf)) {
    $errors.Add("Missing .gitignore")
  }
  else {
    $gitignoreText = Get-Content -LiteralPath $gitignorePath -Raw
    if ($gitignoreText -notmatch "(?m)^private/steward/$") {
      $errors.Add(".gitignore must ignore private/steward/")
    }
  }

  $registryPath = Join-Path $RepoRoot "docs/atlas/registry.json"
  $registry = Get-SafeJson $registryPath
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

  & git -C $RepoRoot check-ignore -q -- "private/steward/steward-latest.md"
  if ($LASTEXITCODE -ne 0) {
    $errors.Add("private/steward/steward-latest.md must be ignored by git.")
  }

  if ($errors.Count -gt 0) {
    throw (($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine)
  }

  if (-not $Quiet) {
    Write-Host "GroundMesh steward loop guard OK"
  }
}

function Get-TextFileSignal {
  param([string]$RelPath)

  $abs = Join-Path $RepoRoot $RelPath
  if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
    return [pscustomobject]@{
      path = $RelPath
      exists = $false
      bytes = 0
      lines = 0
      updated_utc = $null
      keywords = [ordered]@{}
    }
  }

  $text = Get-Content -LiteralPath $abs -Raw
  $counts = [ordered]@{}
  foreach ($streamName in $Streams.Keys) {
    $count = 0
    foreach ($term in $Streams[$streamName]) {
      $count += [regex]::Matches(
        $text,
        [regex]::Escape($term),
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
      ).Count
    }
    $counts[$streamName] = $count
  }

  $lineCount = if ([string]::IsNullOrEmpty($text)) { 0 } else { @($text -split "`r?`n").Count }
  $item = Get-Item -LiteralPath $abs

  [pscustomobject]@{
    path = $RelPath
    exists = $true
    bytes = $item.Length
    lines = $lineCount
    updated_utc = $item.LastWriteTimeUtc.ToString("o")
    keywords = $counts
  }
}

function Get-ChatExportSignal {
  $exportsRoot = Join-Path $RepoRoot "archives/chatgpt_exports"
  if (-not (Test-Path -LiteralPath $exportsRoot -PathType Container)) { return @() }

  $items = @()
  foreach ($manifestFile in Get-ChildItem -LiteralPath $exportsRoot -Recurse -Filter "manifest.json" -File -ErrorAction SilentlyContinue) {
    $manifest = Get-SafeJson $manifestFile.FullName
    if ($null -eq $manifest) { continue }

    $items += [pscustomobject]@{
      path = ConvertTo-RepoRelativePath $manifestFile.FullName
      imported_at = Get-JsonProperty $manifest "imported_at"
      source = Get-JsonProperty $manifest "source"
      conversation_count = [int](Get-JsonProperty $manifest "conversation_count" 0)
    }
  }

  return @($items | Sort-Object imported_at -Descending)
}

function Get-GitSignal {
  try {
    $lines = @(& git -C $RepoRoot status --short 2>$null)
    return [pscustomobject]@{
      available = $true
      dirty_count = $lines.Count
      entries = @($lines)
    }
  }
  catch {
    return [pscustomobject]@{
      available = $false
      dirty_count = 0
      entries = @()
    }
  }
}

function New-StewardAction {
  param(
    [string]$Id,
    [string]$Title,
    [string]$Why,
    [string]$Command = ""
  )

  [pscustomobject]@{
    id = $Id
    title = $Title
    why = $Why
    command = $Command
  }
}

Assert-LocalOutDir
if ($CheckOnly) {
  Test-StewardGuardrails
  return
}

Test-StewardGuardrails

$OutAbs = Join-Path $RepoRoot $OutDir
New-Item -ItemType Directory -Path $OutAbs -Force | Out-Null

$FileSignals = @($AnchorPaths | ForEach-Object { Get-TextFileSignal $_ })
$KeywordTotals = [ordered]@{}
foreach ($streamName in $Streams.Keys) { $KeywordTotals[$streamName] = 0 }
foreach ($file in $FileSignals) {
  if (-not $file.exists) { continue }
  foreach ($streamName in $Streams.Keys) {
    $KeywordTotals[$streamName] += [int]$file.keywords[$streamName]
  }
}

$statusPath = Join-Path $RepoRoot "docs/data/status.json"
$statusDoc = Get-SafeJson $statusPath
$StatusComponents = @()
$StatusCounts = [ordered]@{}
if ($null -ne $statusDoc) {
  $components = Get-JsonProperty $statusDoc "components"
  if ($null -ne $components) {
    foreach ($component in $components.PSObject.Properties) {
      $componentStatus = Get-JsonProperty $component.Value "status" "unknown"
      if (-not $StatusCounts.Contains($componentStatus)) { $StatusCounts[$componentStatus] = 0 }
      $StatusCounts[$componentStatus] += 1
      $StatusComponents += [pscustomobject]@{
        name = $component.Name
        status = $componentStatus
        note = Get-JsonProperty $component.Value "note" ""
      }
    }
  }
}

$registryPath = Join-Path $RepoRoot "docs/atlas/registry.json"
$registryDoc = Get-SafeJson $registryPath
$AtlasEntries = @()
$AtlasTypeCounts = [ordered]@{}
if ($null -ne $registryDoc) {
  foreach ($entry in @((Get-JsonProperty $registryDoc "entries" @()))) {
    $entryType = Get-JsonProperty $entry "type" "unknown"
    if (-not $AtlasTypeCounts.Contains($entryType)) { $AtlasTypeCounts[$entryType] = 0 }
    $AtlasTypeCounts[$entryType] += 1
    $AtlasEntries += $entry
  }
}

$ChatExports = @(Get-ChatExportSignal)
$GitSignal = Get-GitSignal
$NonGreen = @($StatusComponents | Where-Object { $_.status -ne "green" })
$Actions = @()

if ($GitSignal.dirty_count -gt 0) {
  $Actions += New-StewardAction `
    -Id "STEW-BATCH-001" `
    -Title "Settle the current working batch before widening scope" `
    -Why "There are $($GitSignal.dirty_count) changed or untracked paths. GroundMesh stays steadier when batches are summarized before the next push." `
    -Command "git status --short"
}

if ($ChatExports.Count -eq 0) {
  $Actions += New-StewardAction `
    -Id "STEW-CHAT-001" `
    -Title "Import one ChatGPT export into the local archive" `
    -Why "The steward loop can preserve more of the GroundMesh memory once chat history exists in the ignored local archive." `
    -Command ".\scripts\import-chatgpt-export.ps1 -SourcePath <path-to-chatgpt-export.zip>"
}
else {
  $Actions += New-StewardAction `
    -Id "STEW-CHAT-002" `
    -Title "Promote one repeated chat insight into a reviewable artifact" `
    -Why "Imported chats are useful only after one insight becomes a visible, bounded project artifact." `
    -Command "Choose one insight and anchor it as an Atlas note, glossary entry, protocol patch, or test fixture."
}

if ($NonGreen.Count -gt 0) {
  $first = $NonGreen | Select-Object -First 1
  $Actions += New-StewardAction `
    -Id "STEW-STATUS-001" `
    -Title "Clear the first non-green public status component: $($first.name)" `
    -Why $first.note `
    -Command ".\scripts\health-check.ps1"
}
else {
  $Actions += New-StewardAction `
    -Id "STEW-STATUS-002" `
    -Title "Protect the green public layer with one health-check pass" `
    -Why "The current public status snapshot is green. The next move should keep it true while adding structure." `
    -Command ".\scripts\health-check.ps1"
}

$Actions += New-StewardAction `
  -Id "STEW-GROUND-001" `
  -Title "Use TP-04 before large or emotionally charged actions" `
  -Why "The first node grounding protocol helps keep powerful tool access tied to pause, consent, reversibility, and review." `
  -Command "Read docs/protocols/TP-04.md, then choose one small reversible action."

$Actions += New-StewardAction `
  -Id "STEW-LANGUAGE-001" `
  -Title "Translate one private or spirit-heavy phrase into plain public language" `
  -Why "GroundMesh can keep its source energy while making the doorway easier for people who arrive through ordinary public terms." `
  -Command "Pick one phrase from a private note, remove private details, and anchor only the public-safe wording."

$TopSignals = @(
  $KeywordTotals.GetEnumerator() |
    Sort-Object Value -Descending |
    Select-Object -First $TopFiles |
    ForEach-Object {
      [pscustomobject]@{
        stream = $_.Key
        hits = $_.Value
      }
    }
)

$State = [pscustomobject]@{
  generated_utc = $NowUtc
  orientation = [pscustomobject]@{
    aim = "Keep GroundMesh moving through small anchored steps without publishing private material or pretending autonomy is mature before it is."
    rule = "Observe, summarize, choose one smallest useful next action, then leave a reviewable trail."
  }
  inputs = @($FileSignals)
  keyword_totals = $KeywordTotals
  top_signals = @($TopSignals)
  public_status_counts = $StatusCounts
  atlas_type_counts = $AtlasTypeCounts
  chat_exports = @($ChatExports)
  git = $GitSignal
  next_actions = @($Actions)
}

$StatePath = Join-Path $OutAbs "steward-state.json"
$ReportPath = Join-Path $OutAbs "steward-latest.md"
$State | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $StatePath -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# GroundMesh Steward Report")
$lines.Add("")
$lines.Add("- Generated UTC: $NowUtc")
$lines.Add("- Privacy: this report is local-only under private/steward and must be reviewed before anything is made public.")
$lines.Add("")
$lines.Add("## Orientation")
$lines.Add("")
$lines.Add("Keep GroundMesh moving through small anchored steps. The loop does not publish, schedule, contact people, run credentials, or make irreversible changes. It reads the project spine, notices chat imports, and proposes the next grounded action.")
$lines.Add("")
$lines.Add("## Current Streams")
$lines.Add("")
$statusSummary = if ($StatusCounts.Count -gt 0) {
  (($StatusCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "; ")
}
else { "not available" }
$atlasSummary = if ($AtlasTypeCounts.Count -gt 0) {
  (($AtlasTypeCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "; ")
}
else { "not available" }
$lines.Add("- Public status: $statusSummary")
$lines.Add("- Atlas entries: $($AtlasEntries.Count) total ($atlasSummary)")
$lines.Add("- Imported ChatGPT export runs: $($ChatExports.Count)")
$lines.Add("- Git working entries: $($GitSignal.dirty_count)")
$lines.Add("")
$lines.Add("## Strongest Signals")
$lines.Add("")
foreach ($signal in $TopSignals) {
  $lines.Add("- $($signal.stream): $($signal.hits)")
}
$lines.Add("")
$lines.Add("## Input Anchors")
$lines.Add("")
foreach ($file in ($FileSignals | Sort-Object path)) {
  $mark = if ($file.exists) { "ok" } else { "missing" }
  $lines.Add("- $mark - $($file.path)")
}
$lines.Add("")
$lines.Add("## Imported Chats")
$lines.Add("")
if ($ChatExports.Count -eq 0) {
  $lines.Add("- No imported ChatGPT exports found yet under archives/chatgpt_exports.")
}
else {
  foreach ($export in $ChatExports) {
    $lines.Add("- $($export.path) - $($export.conversation_count) conversations - imported $($export.imported_at)")
  }
}
$lines.Add("")
$lines.Add("## Next Actions")
$lines.Add("")
foreach ($action in $Actions) {
  $lines.Add("### $($action.id): $($action.title)")
  $lines.Add("")
  $lines.Add($action.why)
  if (-not [string]::IsNullOrWhiteSpace($action.command)) {
    $lines.Add("")
    $lines.Add("Suggested command or move:")
    $lines.Add("")
    $lines.Add('```text')
    $lines.Add($action.command)
    $lines.Add('```')
  }
  $lines.Add("")
}
$lines.Add("## Handoff Prompt")
$lines.Add("")
$lines.Add("Read private/steward/steward-latest.md, then take the smallest real GroundMesh step that improves public clarity, operational structure, or commons alignment. Preserve consent, transparency, local-first stewardship, privacy, legal readiness, and refusal of capture.")
$lines.Add("")

($lines -join "`r`n") | Set-Content -LiteralPath $ReportPath -Encoding UTF8

if (-not $Quiet) {
  Write-Host "GroundMesh steward report -> $ReportPath"
  Write-Host "GroundMesh steward state  -> $StatePath"
  if ($Actions.Count -gt 0) {
    Write-Host "First suggested action    -> $($Actions[0].title)"
  }
}
