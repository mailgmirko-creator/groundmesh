param(
  [int]$Port = 8787,
  [switch]$OpenBrowser
)

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ServerPath = Join-Path $RepoRoot "tools/registration_pilot_server.py"

if (!(Test-Path $ServerPath)) {
  throw "Registration pilot server not found: $ServerPath"
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) {
    $pythonExe = $py.Source
    $pythonArgs = @("-3", $ServerPath, "--port", $Port)
  } else {
    throw "Python was not found on PATH."
  }
} else {
  $pythonExe = $python.Source
  $pythonArgs = @($ServerPath, "--port", $Port)
}

if ($OpenBrowser) {
  Start-Process "http://127.0.0.1:$Port/register-pilot.html"
}

& $pythonExe @pythonArgs
