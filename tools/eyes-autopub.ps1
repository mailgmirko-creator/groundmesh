param(
  [int]$IntervalSec = 30,
  [string]$Publisher = "C:\Projects\GroundMesh-DEV\tools\publish-tail.ps1"
)
$ErrorActionPreference = "SilentlyContinue"
Write-Host ("EYES AUTOPUB starting; interval={0}s" -f $IntervalSec)
while ($true) {
  try {
    & $Publisher
  } catch {
    Write-Host ("EYES AUTOPUB error: " + $_.Exception.Message)
  }
  Start-Sleep -Seconds $IntervalSec
}
