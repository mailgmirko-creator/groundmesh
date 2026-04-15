param(
  [switch]$OpenFolderOnly
)

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PilotRoot = Join-Path $RepoRoot "private/registration_pilot"
$RecordsRoot = Join-Path $PilotRoot "records"
$SubmissionsRoot = Join-Path $PilotRoot "submissions"

if (!(Test-Path $PilotRoot)) {
  throw "Registration pilot workspace not found: $PilotRoot"
}

Start-Process explorer.exe $PilotRoot

if ($OpenFolderOnly) {
  return
}

$latestRecord = Get-ChildItem $RecordsRoot -File -Filter *.md -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -notlike "*-draft.md" } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

$latestSubmission = Get-ChildItem $SubmissionsRoot -File -Filter *.json -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if ($latestRecord) {
  Start-Process notepad.exe $latestRecord.FullName
}

if ($latestSubmission) {
  Start-Process notepad.exe $latestSubmission.FullName
}

if (-not $latestRecord -and -not $latestSubmission) {
  Write-Host "No live registration pilot record or submission was found yet."
}
