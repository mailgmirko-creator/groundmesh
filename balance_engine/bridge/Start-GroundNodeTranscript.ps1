param(
  [string]$Path = "$env:USERPROFILE\Documents\GroundNode_transcript.txt"
)
if (-not (Test-Path $Path)) {
  New-Item -ItemType File -Path $Path | Out-Null
}
Write-Host "Starting transcript at: $Path"
Start-Transcript -Path $Path -Append -IncludeInvocationHeader | Out-Null
