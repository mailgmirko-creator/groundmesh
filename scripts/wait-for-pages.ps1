param(
  [string]$Url = "https://mailgmirko-creator.github.io/groundmesh/",
  [int]$Interval = 5
)

Write-Host "Waiting for Pages to deploy: $Url" -ForegroundColor Cyan
while ($true) {
  try {
    $r = Invoke-WebRequest -Uri ($Url + "?nocache=" + (Get-Random)) -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) {
      Write-Host "Deployed ✅ Opening..." -ForegroundColor Green
      Start-Process $Url
      break
    }
  } catch { }
  Start-Sleep -Seconds $Interval
  Write-Host -NoNewline "."
}
