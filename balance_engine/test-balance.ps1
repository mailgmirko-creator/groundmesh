$Root = "C:\Projects\GroundMesh-DEV\balance_engine"
$Event = Get-Content "$Root\event.sample.json" -Raw
$dec = Invoke-RestMethod -Uri http://127.0.0.1:5059/decide -Method POST -Body $Event -ContentType "application/json"
$payload = @{ event = ($Event | ConvertFrom-Json); decision = $dec } | ConvertTo-Json -Depth 8
Invoke-RestMethod -Uri http://127.0.0.1:5059/attest -Method POST -Body $payload -ContentType "application/json"
Write-Host "`n--- Decision ---"
$dec | ConvertTo-Json -Depth 8
Write-Host "`nLedger appended."
