$pilotProcesses = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Name -eq 'python.exe' -and
    $_.CommandLine -match 'registration_pilot_server\.py'
  } |
  Sort-Object ProcessId

if (-not $pilotProcesses) {
  Write-Host "No GroundMesh registration pilot server is currently running."
  return
}

foreach ($proc in $pilotProcesses) {
  try {
    Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
    Write-Host ("Stopped registration pilot PID {0}" -f $proc.ProcessId)
  } catch {
    Write-Host ("Could not stop registration pilot PID {0}: {1}" -f $proc.ProcessId, $_.Exception.Message)
  }
}
