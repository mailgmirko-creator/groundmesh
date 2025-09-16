try { Get-Transcript | Out-Null } catch {}
try { Stop-Transcript | Out-Null } catch {}
Write-Host "Transcript stopped."
