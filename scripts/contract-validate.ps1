param(
  [string]$ContractsDir = "balance_engine/contracts",
  [string]$SchemaPath   = "balance_engine/schemas/command_contract.schema.json",
  [switch]$Quiet
)
$ErrorActionPreference = "Stop"

function Write-Utf8NoBom { param([string]$Path,[string]$Content)
  $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
  [System.IO.File]::WriteAllBytes($Path, $bytes)
}
function Ensure-Dir([string]$Path){ if(-not(Test-Path $Path)){ New-Item -ItemType Directory -Force -Path $Path | Out-Null } }

# Minimal rule set mirroring the schema (no external libs)
$allowedContexts = @("dev","staging","prod")
$allowedRequires = @("human_signature","council_quorum","audit_log_entry","change_ticket")
$rxTimeWindow    = '^[0-9]+[smhd]$'
$rxRate          = '^[0-9]+/[smhd]$'
$rxSha256        = '^[A-Fa-f0-9]{64}$'

$root = (git rev-parse --show-toplevel) 2>$null
if ($LASTEXITCODE -ne 0 -or -not $root) { $root = (Get-Location).Path }

$absContracts = Join-Path $root $ContractsDir
$absSchema    = Join-Path $root $SchemaPath
$absIndex     = Join-Path $root "docs/command_contracts/index.md"

$files = Get-ChildItem -Path $absContracts -Filter *.json -ErrorAction SilentlyContinue | Sort-Object Name
$rows = @()
foreach ($f in $files) {
  $ok = $true; $note = "OK"
  try {
    $raw = Get-Content -Raw -Path $f.FullName
    $obj = ConvertFrom-Json -InputObject $raw
    # Required top-level
    foreach ($k in "id","action","scope","contexts","requires","safeguards","approvals","audit","created") {
      if ($null -eq $obj.$k) { $ok=$false; $note="Missing '$k'"; break }
    }
    if ($ok -and -not ($obj.contexts | ForEach-Object { $_ } | ? { $allowedContexts -contains $_ } | Measure-Object).Count -ge 1) { $ok=$false; $note="contexts invalid/empty" }
    if ($ok -and -not ($obj.requires | ForEach-Object { $_ } | ? { $allowedRequires -contains $_ } | Measure-Object).Count -ge 1) { $ok=$false; $note="requires invalid/empty" }
    if ($ok -and $obj.safeguards.revert_window -and (-not ($obj.safeguards.revert_window -match $rxTimeWindow))) { $ok=$false; $note="bad safeguards.revert_window" }
    if ($ok -and $obj.safeguards.rate_limit -and (-not ($obj.safeguards.rate_limit -match $rxRate))) { $ok=$false; $note="bad safeguards.rate_limit" }
    if ($ok -and $obj.constraints -and $obj.constraints.hash_of_payload -and (-not ($obj.constraints.hash_of_payload -match $rxSha256))) { $ok=$false; $note="bad constraints.hash_of_payload" }
  } catch {
    $ok = $false; $note = "JSON parse error: $($_.Exception.Message)"
  }
  $rows += [pscustomobject]@{
    File   = $f.Name
    Id     = if ($obj) { $obj.id } else { "" }
    Action = if ($obj) { $obj.action.name } else { "" }
    Ctx    = if ($obj) { ($obj.contexts -join ",") } else { "" }
    Needs  = if ($obj) { ($obj.requires -join ",") } else { "" }
    Valid  = $ok
    Note   = $note
  }
}

# Rebuild docs index
Ensure-Dir (Split-Path $absIndex -Parent)
$md = @()
$md += "# Command Contracts"
$md += ""
$md += "| Id | Action | Contexts | Requires | File | Valid | Note |"
$md += "|---|---|---|---|---|---|---|"
foreach ($r in $rows) {
  $md += "| $($r.Id) | $($r.Action) | $($r.Ctx) | $($r.Needs) | $($r.File) | $($r.Valid) | $($r.Note) |"
}
[System.IO.File]::WriteAllText($absIndex, ($md -join "`r`n"), [System.Text.UTF8Encoding]::new($false))

if (-not $Quiet) { $rows | Format-Table -AutoSize }