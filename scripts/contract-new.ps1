param(
  [Parameter(Mandatory)][string]$Name,
  [string]$Contexts = "dev,staging",
  [string]$Requires = "human_signature,audit_log_entry"
)
$ErrorActionPreference = "Stop"

function Write-Utf8NoBom { param([string]$Path,[string]$Content)
  $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
  [System.IO.File]::WriteAllBytes($Path, $bytes)
}

$root = (git rev-parse --show-toplevel) 2>$null
if ($LASTEXITCODE -ne 0 -or -not $root) { $root = (Get-Location).Path }
$CcDir = Join-Path $root "balance_engine/contracts"
if (-not (Test-Path $CcDir)) { New-Item -ItemType Directory -Force -Path $CcDir | Out-Null }

$idSafe = ($Name -replace '[^A-Za-z0-9._-]','-')
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$id    = "CC.{0}.{1}" -f $idSafe, "v1"
$now   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$file  = Join-Path $CcDir ("{0}.json" -f $id)

if (Test-Path $file) { Write-Host "File exists: $file"; exit 1 }

$ctx = ($Contexts -split '\s*,\s*' | Where-Object { $_ -ne "" })
$req = ($Requires -split '\s*,\s*' | Where-Object { $_ -ne "" })

$doc = @{
  id = $id
  version = "1.0.0"
  action = @{ name = $Name; params = @{ } }
  scope  = @{ project = "GroundMesh"; resources = @() }
  contexts = $ctx
  requires = $req
  safeguards = @{ revert_window = "10m"; alert_nodes = @("lead_node"); rate_limit = "3/h"; dry_run_first = $true }
  approvals = @{ min_signatures = 1; roles = @("maintainer") }
  constraints = @{ }
  audit = @{ reason = "new contract"; created_by = "Mirko" }
  created = $now
  updated = $now
} | ConvertTo-Json -Depth 8

Write-Utf8NoBom -Path $file -Content $doc
Write-Host "Created $file"