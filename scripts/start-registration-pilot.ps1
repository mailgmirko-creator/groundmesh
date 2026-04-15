param(
  [int]$Port = 8787,
  [switch]$OpenBrowser,
  [switch]$AllowLan
)

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ServerPath = Join-Path $RepoRoot "tools/registration_pilot_server.py"
$HostAddress = if ($AllowLan) { "0.0.0.0" } else { "127.0.0.1" }

if (!(Test-Path $ServerPath)) {
  throw "Registration pilot server not found: $ServerPath"
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) {
    $pythonExe = $py.Source
    $pythonArgs = @("-3", $ServerPath, "--host", $HostAddress, "--port", $Port)
  } else {
    throw "Python was not found on PATH."
  }
} else {
  $pythonExe = $python.Source
  $pythonArgs = @($ServerPath, "--host", $HostAddress, "--port", $Port)
}

$localUrl = "http://127.0.0.1:$Port/register-pilot.html"

Write-Host ""
Write-Host "GroundMesh registration pilot launch"
Write-Host "Local URL: $localUrl"

if ($AllowLan) {
  $getNetIp = Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue
  if ($getNetIp) {
    $lanIps = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
      Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*' -and
        $_.InterfaceAlias -notmatch 'Loopback|vEthernet|WSL|Hyper-V|Teredo|Bluetooth|Virtual'
      } |
      Select-Object -ExpandProperty IPAddress -Unique
  } else {
    $lanIps = @()
  }

  if ($lanIps) {
    Write-Host "LAN access enabled. Share only with invited-circle participants."
    foreach ($ip in $lanIps) {
      Write-Host ("Share URL: http://{0}:{1}/register-pilot.html" -f $ip, $Port)
    }
  } else {
    Write-Host "LAN access was requested, but no suitable IPv4 address was detected."
  }

  Write-Host "If Windows asks about firewall access, allow Private networks only."
}

if ($OpenBrowser) {
  Start-Process $localUrl
}

& $pythonExe @pythonArgs
