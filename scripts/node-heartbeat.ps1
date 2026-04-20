param(
  [string]$ManifestPath = "private/node_agent/node-manifest.local.json",
  [string]$OutPath = "",
  [ValidateSet("active","paused","degraded","revoked")]
  [string]$Status = "active",
  [switch]$WriteFile
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
if (-not (Test-Path $absManifest)) {
  throw "Manifest not found at $absManifest. Run .\\scripts\\node-agent-init.ps1 first."
}

$manifest = Get-Content -Raw -Path $absManifest | ConvertFrom-Json -AsHashtable
$hbTarget = if ($OutPath) { $OutPath } else { $manifest.paths.heartbeat_path }
$absHeartbeat = Join-Path $root $hbTarget
$hbDir = Split-Path $absHeartbeat -Parent
if (-not (Test-Path $hbDir)) {
  New-Item -ItemType Directory -Force -Path $hbDir | Out-Null
}

$cpuLoad = 0.0
try {
  $cpu = Get-CimInstance Win32_Processor
  $avg = ($cpu | Measure-Object -Property LoadPercentage -Average).Average
  $cpuLoad = [math]::Round(($avg / 100.0), 3)
} catch {
  $cpuLoad = 0.0
}

$memoryFree = 0.0
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $memoryFree = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 1)
} catch {
  $memoryFree = 0.0
}

$storageFree = 0.0
try {
  $driveName = [System.IO.Path]::GetPathRoot($root).TrimEnd('\').TrimEnd(':')
  $drive = Get-PSDrive -Name $driveName -PSProvider FileSystem -ErrorAction Stop
  $storageFree = [math]::Round($drive.Free / 1GB, 1)
} catch {
  $storageFree = 0.0
}

$reachable = $false
$latencyClass = "offline"
try {
  $net = Test-NetConnection github.com -Port 443 -WarningAction SilentlyContinue
  $reachable = [bool]$net.TcpTestSucceeded
  if ($reachable) {
    $latency = [double]$net.PingReplyDetails.RoundtripTime
    if ($latency -le 30) { $latencyClass = "fast" }
    elseif ($latency -le 120) { $latencyClass = "normal" }
    else { $latencyClass = "slow" }
  }
} catch {
  $reachable = $false
  $latencyClass = "offline"
}

$availability = if ($Status -eq "paused") {
  "paused"
} elseif ($Status -eq "revoked") {
  "no_work"
} elseif ($manifest.consent.public_state_sync -or $manifest.consent.public_cache -or $manifest.consent.public_health_probe) {
  "accepting_public_work"
} else {
  "limited_work"
}

$completedSinceBoot = 0
$lastResult = "unknown"
if ($manifest.paths.outbox_path) {
  $absOutbox = Join-Path $root $manifest.paths.outbox_path
  if (Test-Path $absOutbox) {
    try {
      $outbox = Get-Content -Raw -Path $absOutbox | ConvertFrom-Json -AsHashtable
      $results = @($outbox.results)
      $completedSinceBoot = $results.Count
      if ($results.Count -gt 0) {
        $latest = $results | Sort-Object { $_.recorded_at_utc } -Descending | Select-Object -First 1
        $lastResult = switch ($latest.status) {
          "ok" { "ok" }
          "warn" { "warn" }
          "error" { "error" }
          default { "unknown" }
        }
      }
    } catch {
      $completedSinceBoot = 0
      $lastResult = "unknown"
    }
  }
}

$heartbeat = [ordered]@{
  protocol_version = "gm.node.v1"
  node_id = $manifest.node_id
  ts_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  status = $Status
  availability = $availability
  resources = [ordered]@{
    cpu_load = $cpuLoad
    memory_free_gb = $memoryFree
    storage_free_gb = $storageFree
  }
  network = [ordered]@{
    reachable = $reachable
    latency_class = $latencyClass
  }
  jobs = [ordered]@{
    running = 0
    completed_since_boot = $completedSinceBoot
    last_result = $lastResult
  }
}

$json = $heartbeat | ConvertTo-Json -Depth 6
if ($WriteFile -or -not $OutPath) {
  Write-Utf8NoBom -Path $absHeartbeat -Content $json
}
Write-Output $json
