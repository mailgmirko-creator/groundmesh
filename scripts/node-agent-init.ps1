param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$DisplayName,
  [string]$OperatorName = $env:USERNAME,
  [string]$Country = "",
  [string]$City = "",
  [ValidateSet("desktop","mini-pc","home-server","edge-box","laptop","mobile")]
  [string]$DeviceClass = "desktop",
  [switch]$CanRunLocalModel,
  [switch]$CanRelayBandwidth,
  [switch]$CanAcceptBackgroundJobs,
  [switch]$Force
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
$manifestDir = Split-Path $absManifest -Parent
if (-not (Test-Path $manifestDir)) {
  New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
}

if ((Test-Path $absManifest) -and -not $Force) {
  throw "Manifest already exists at $absManifest. Use -Force to replace it."
}

$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$nodeId = "node-" + ([guid]::NewGuid().ToString("N").Substring(0, 12))
$defaultName = if ($DisplayName) { $DisplayName } else { "{0}-{1}" -f $env:COMPUTERNAME, "light-node" }

$cpuCores = [Environment]::ProcessorCount
$memoryGb = 0.0
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $memoryGb = [math]::Round(($os.TotalVisibleMemorySize * 1KB) / 1GB, 1)
} catch {
  $memoryGb = 0.0
}

$storageGb = 0.0
try {
  $driveName = [System.IO.Path]::GetPathRoot($root).TrimEnd('\').TrimEnd(':')
  $drive = Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction Stop
  $storageGb = [math]::Round($drive.Free / 1GB, 1)
} catch {
  $storageGb = 0.0
}

$workspaceRoot = "private/node_agent/workspace/"
$heartbeatPath = "private/node_agent/node-heartbeat.latest.json"
$inboxPath = "private/node_agent/public-node-inbox.latest.json"
$outboxPath = "private/node_agent/public-node-outbox.latest.json"
$claimsPath = "private/node_agent/public-node-claims.latest.json"
$acksPath = "private/node_agent/public-node-acks.latest.json"
$logPath = "private/node_agent/node-agent.log"

$manifest = [ordered]@{
  protocol_version = "gm.node.v1"
  agent_version = "0.1.0"
  node_id = $nodeId
  node_class = "light"
  device_class = $DeviceClass
  display_name = $defaultName
  operator = [ordered]@{
    name = if ($OperatorName) { $OperatorName } else { "local-operator" }
    consent_mode = "explicit"
  }
  location_hint = [ordered]@{
    country = $Country
    city = $City
  }
  capabilities = [ordered]@{
    cpu_cores = $cpuCores
    memory_gb = $memoryGb
    storage_free_gb = $storageGb
    can_cache_public_state = $true
    can_run_local_model = [bool]$CanRunLocalModel
    can_relay_bandwidth = [bool]$CanRelayBandwidth
    can_accept_background_jobs = [bool]$CanAcceptBackgroundJobs
  }
  limits = [ordered]@{
    max_job_minutes = 15
    max_cpu_percent = 35
    network_mode = "metered-safe"
    energy_mode = "prefer-plugged-in"
  }
  consent = [ordered]@{
    public_state_sync = $true
    public_cache = $true
    public_health_probe = $true
    non_sensitive_compute = $false
  }
  paths = [ordered]@{
    workspace_root = $workspaceRoot
    heartbeat_path = $heartbeatPath
    inbox_path = $inboxPath
    outbox_path = $outboxPath
    claims_path = $claimsPath
    acks_path = $acksPath
    log_path = $logPath
  }
  created_utc = $now
  updated_utc = $now
}

foreach ($dirPath in @($workspaceRoot, (Split-Path $inboxPath -Parent), (Split-Path $outboxPath -Parent), (Split-Path $acksPath -Parent))) {
  $absDir = Join-Path $root $dirPath
  if (-not (Test-Path $absDir)) {
    New-Item -ItemType Directory -Force -Path $absDir | Out-Null
  }
}

$json = $manifest | ConvertTo-Json -Depth 8
Write-Utf8NoBom -Path $absManifest -Content $json
Write-Host "Created $absManifest"
