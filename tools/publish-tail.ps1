param(
  [string]$TranscriptDir = "C:\Projects\Bridge\transcripts",
  [Alias("Lines")][int]$Count = 400,
  [int]$LookBackFiles = 6,
  [string]$WorktreeRoot = "C:\Projects\GroundMesh-DEV\.bridge-wt"
)

function Read-UnlockedText {
  param([string]$Path)
  try {
    $fs = New-Object System.IO.FileStream($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try { $sr = New-Object IO.StreamReader($fs,[Text.Encoding]::UTF8,$true); $t=$sr.ReadToEnd(); $sr.Close(); return $t }
    finally { $fs.Close() }
  } catch { return $null }
}

# 1) Collect newest-by-name transcripts
$all = Get-ChildItem -Path $TranscriptDir -Filter 'ps_transcript_*.txt' -ErrorAction SilentlyContinue
if (-not $all) { Write-Output 'No transcript found.'; exit 1 }
$pick = $all | Sort-Object Name -Descending | Select-Object -First $LookBackFiles

# 2) Merge lines and take global tail
$lines  = New-Object System.Collections.Generic.List[string]
foreach ($f in $pick) {
  $t = Read-UnlockedText -Path $f.FullName
  if ($t) {
    $parts = [Text.RegularExpressions.Regex]::Split($t,'\r?\n')
    foreach ($p in $parts) { if ($p -ne $null) { $lines.Add($p) | Out-Null } }
  }
}
$globalTail = $lines | Select-Object -Last $Count
if (-not $globalTail) { $globalTail = @('<empty>') }

# 3) Redact per line
$redacted = foreach ($line in $globalTail) {
  $x = $line
  $x = [regex]::Replace($x,'ghp_[A-Za-z0-9]{36,}','[REDACTED_GH_TOKEN]')
  $x = [regex]::Replace($x,'sk-[A-Za-z0-9\-_]{20,}','[REDACTED_KEY]')
  $x = [regex]::Replace($x,'Bearer\s+[A-Za-z0-9\._\-]+','Bearer [REDACTED]')
  $x = [regex]::Replace($x,'([A-Za-z]:\\Users\\[^\\]+\\)','[HOME]\\')
  $x
}

# 4) Write outputs into the dedicated worktree
$OutDir  = Join-Path $WorktreeRoot 'public-bridge'
$TxtFile = Join-Path $OutDir 'tail.txt'
$MdFile  = Join-Path $OutDir 'tail.md'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$enc = New-Object Text.UTF8Encoding($false)
$updated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$ts = Get-Date -Format 'yyyyMMddHHmmss'

# tail.txt — newest-first with header
$rev = $redacted.Clone(); [Array]::Reverse($rev)
[IO.File]::WriteAllLines($TxtFile, @("AGGREGATED | Updated: $updated") + $rev, $enc)

# tail.md — human order with header
$md = New-Object System.Collections.Generic.List[string]
$md.Add('# PowerShell Transcript Tail (Aggregated)') | Out-Null
$md.Add('') | Out-Null
$md.Add('- Updated: ' + $updated) | Out-Null
$md.Add('') | Out-Null
$md.Add('```text') | Out-Null
foreach($l in $redacted){ $md.Add($l) | Out-Null }
$md.Add('```') | Out-Null
[IO.File]::WriteAllLines($MdFile, $md, $enc)

# 5) Commit/push the snapshot from INSIDE the worktree
Push-Location $WorktreeRoot
$MsgFile = Join-Path (Get-Location) 'COMMITMSG.txt'
Set-Content -Path $MsgFile -Value 'publish tail snapshot (cacheproof step 1)' -Encoding UTF8
& git add public-bridge\tail.txt
& git add public-bridge\tail.md
& git commit -F $MsgFile
& git push -u origin bridge-public
Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue

# 6) Compute commit SHA and write latest.json pointer, then commit/push again
$sha = (git rev-parse HEAD).Trim()
$baseRaw  = 'https://raw.githubusercontent.com/mailgmirko-creator/groundmesh'
$baseBlob = 'https://github.com/mailgmirko-creator/groundmesh/blob'

$latest = [ordered]@{
  updated              = $updated
  commit               = $sha
  raw_cachebuster_url  = "$baseRaw/bridge-public/public-bridge/tail.txt?ts=$ts"
  raw_commit_url       = "$baseRaw/$sha/public-bridge/tail.txt"
  pretty_commit_url    = "$baseBlob/$sha/public-bridge/tail.md"
}
$LatestFile = Join-Path $OutDir 'latest.json'
$latest | ConvertTo-Json -Depth 4 | Out-File -FilePath $LatestFile -Encoding utf8 -Force

$MsgFile = Join-Path (Get-Location) 'COMMITMSG.txt'
Set-Content -Path $MsgFile -Value 'publish latest.json (cacheproof pointers)' -Encoding UTF8
& git add public-bridge\latest.json
& git commit -F $MsgFile
& git push -u origin bridge-public
Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue
Pop-Location

# 7) Print the three URLs (so you see them; I’ll use the cachebuster one)
Write-Host ('RAW (cachebuster): ' + "$baseRaw/bridge-public/public-bridge/tail.txt?ts=$ts")
Write-Host ('RAW (commit):      ' + "$baseRaw/$sha/public-bridge/tail.txt")
Write-Host ('PRETTY (commit):   ' + "$baseBlob/$sha/public-bridge/tail.md")
