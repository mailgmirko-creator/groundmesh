param(
  [string]$Url = "http://127.0.0.1:5059",
  [switch]$Attest
)

$Root = $PSScriptRoot
$EventPath = Join-Path $Root "event.sample.json"
$Event = Get-Content -LiteralPath $EventPath -Raw
$dec = Invoke-RestMethod -Uri "$Url/decide" -Method POST -Body $Event -ContentType "application/json"
Write-Host "`n--- Decision ---"
$dec | ConvertTo-Json -Depth 8

if ($Attest) {
  $payload = @{ event = ($Event | ConvertFrom-Json); decision = $dec } | ConvertTo-Json -Depth 8
  Invoke-RestMethod -Uri "$Url/attest" -Method POST -Body $payload -ContentType "application/json"
  Write-Host "`nLedger appended."
}
else {
  Write-Host "`nDecision-only test complete. Pass -Attest to append a ledger record deliberately."
}
