param(
  [string]$TranscriptPath = "$env:USERPROFILE\Documents\GroundNode_transcript.txt",
  [string]$Layer = "system"
)

. "$PSScriptRoot\bridge-groundnode.ps1"

$TagRegex = '\[(LIE|STEAL|KILL|DESTROY|TRUTH|STEWARDSHIP|CARE|CREATION)\]'
$Map = @{
  "LIE"          = "lie"
  "STEAL"        = "steal"
  "KILL"         = "kill"
  "DESTROY"      = "destroy"
  "TRUTH"        = "truth"
  "STEWARDSHIP"  = "stewardship"
  "CARE"         = "care"
  "CREATION"     = "creation"
}

if (-not (Test-Path $TranscriptPath)) { New-Item -ItemType File -Path $TranscriptPath | Out-Null }

Write-Host "=== QUIET agent ready ==="
Write-Host "Watching: $TranscriptPath"
Write-Host "Tags: [LIE] [STEAL] [KILL] [DESTROY] [TRUTH] [STEWARDSHIP] [CARE] [CREATION]"

Get-Content -Path $TranscriptPath -Wait -Tail 0 | ForEach-Object {
  $line = $_
  if (-not $line) { return }
  $m = [regex]::Match($line, $TagRegex, 'IgnoreCase')
  if (-not $m.Success) { return }

  $tag = $m.Groups[1].Value.ToUpperInvariant()
  $etype = $Map[$tag]

  # sanitize and bound the line passed into context
  $clean = [string]$line
  $clean = ($clean -replace '\p{C}', ' ')
  if ($clean.Length -gt 500) { $clean = $clean.Substring(0,500) + '…' }

  $ctx = @{
    source   = "PS_Transcript"
    line     = $clean
    machine  = $env:COMPUTERNAME
    when     = (Get-Date).ToUniversalTime().ToString("s") + "Z"
  }

  try {
    $res = Send-BalanceEvent -Type $etype -Layer $Layer -Context $ctx
    Write-Host ("[{0}] -> {1} | ledger={2}" -f $tag, $res.opposite, $res.ledger) -ForegroundColor Green
  } catch {
    Write-Warning ("Failed to send event for [{0}]: {1}" -f $tag, $_.Exception.Message)
  }
}
