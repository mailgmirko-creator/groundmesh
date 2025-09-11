# PowerShell Transcript Tail (Aggregated)

- Updated: 2025-09-11 20:56:48

```text
$Failed    = Join-Path $RepoRoot $FailedRel

# Ensure dirs exist
$null = New-Item -ItemType Directory -Force -Path $Inbox,$Outbox,$Processed,$Failed

function Write-ResultJson { param([string]$Path,[hashtable]$Obj)
  $json = $Obj | ConvertTo-Json -Depth 8
  [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

$jobFile = Get-ChildItem $Inbox -Filter *.json -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
if (-not $jobFile) { Write-Host "No jobs in $Inbox"; exit 0 }

Write-Host ("Picked job: {0}" -f $jobFile.Name)

try { $job = Get-Content $jobFile.FullName -Raw | ConvertFrom-Json }
catch {
  Write-Host ("Invalid job JSON: {0}" -f $jobFile.Name)
  Move-Item $jobFile.FullName (Join-Path $Failed $jobFile.Name) -Force
  exit 1
}

$jobType = $job.job_type
$started = Get-Date

switch ($jobType) {
  'tsl_principles_learn' {
    $inYaml  = Join-Path $RepoRoot $job.inputs.principles_yaml
    $outDir  = Join-Path $RepoRoot $job.outputs.artifact_dir
    $model   = Join-Path $outDir ($job.outputs.model_file)

    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { throw "Python not found on PATH." }

    & python (Join-Path $RepoRoot "apps\tsl\tsl_core\learner.py") $inYaml $outDir
    if ($LASTEXITCODE -ne 0) { throw "Learner failed with exit code $LASTEXITCODE." }
    if (-not (Test-Path $model)) { throw "Model file missing after run: $model" }

    $size = (Get-Item $model).Length
    $res  = @{
      job_type = $jobType
      started  = $started.ToString("s")
      finished = (Get-Date).ToString("s")
      status   = "success"
      outputs  = @{ model_file = $model; size_bytes = $size }
    }
    $outFile = Join-Path $Outbox ("result_" + [IO.Path]::GetFileNameWithoutExtension($jobFile.Name) + ".json")
    Write-ResultJson -Path $outFile -Obj $res
    Move-Item $jobFile.FullName (Join-Path $Processed $jobFile.Name) -Force
    Write-Host ("Job OK -> {0}" -f $outFile)
  }
  default {
    $res = @{
      job_type = $jobType
      started  = $started.ToString("s")
      finished = (Get-Date).ToString("s")
      status   = "unsupported_job_type"
    }
    $outFile = Join-Path $Outbox ("result_" + [IO.Path]::GetFileNameWithoutExtension($jobFile.Name) + ".json")
    Write-ResultJson -Path $outFile -Obj $res
    Move-Item $jobFile.FullName (Join-Path $Failed $jobFile.Name) -Force
    Write-Host ("Unsupported job type: {0}" -f $jobType)
  }
}
'@ | Set-Content -Encoding UTF8 (Join-Path $Tools "grid-worker.ps1")
**********************
Command start time: 20250911203949
**********************
PS C:\Projects\GroundMesh-DEV> # Commit the fixed worker + .gitkeep files
**********************
Command start time: 20250911203949
**********************
PS C:\Projects\GroundMesh-DEV> $MsgFile = Join-Path $DevRepo "COMMITMSG.txt"
**********************
Command start time: 20250911203949
**********************
PS C:\Projects\GroundMesh-DEV> Set-Content -Path $MsgFile -Encoding UTF8 -Value "fix(grid): absolute repo paths and ensured outbox; add .gitkeep"
**********************
Command start time: 20250911203949
**********************
PS C:\Projects\GroundMesh-DEV> git add tools/grid-worker.ps1 grid/**/.gitkeep

**********************
Command start time: 20250911203949
**********************
PS C:\Projects\GroundMesh-DEV> git commit -F $MsgFile

**********************
Command start time: 20250911203949
**********************
PS C:\Projects\GroundMesh-DEV> git push -u origin dev

**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> # Enqueue a fresh job, run one cycle, refresh eyes so I can see it
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> $Stamp  = Get-Date -Format "yyyyMMdd_HHmmss"
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> $Inbox  = Join-Path $DevRepo "grid\inbox"
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> $JobEnq = Join-Path $Inbox ("tsl_principles_learn_" + $Stamp + ".json")
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> Copy-Item "apps/tsl/jobs/learn_principles.json" $JobEnq -Force
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> & "C:\Projects\GroundMesh-DEV\tools\grid-worker.ps1"
Picked job: tsl_principles_learn_20250911_203952.json

Job OK -> C:\Projects\GroundMesh-DEV\grid\outbox\result_tsl_principles_learn_20250911_203952.json
**********************
Command start time: 20250911203952
**********************
PS C:\Projects\GroundMesh-DEV> pt




**********************
Command start time: 20250911205647
**********************
PS C:\Projects\GroundMesh-DEV> # === Upgrade publisher: commit-pinned URLs + cachebuster + latest.json pointer ===
**********************
Command start time: 20250911205647
**********************
PS C:\Projects\GroundMesh-DEV> $DevRepo = "C:\Projects\GroundMesh-DEV"
**********************
Command start time: 20250911205647
**********************
PS C:\Projects\GroundMesh-DEV> $Tools   = Join-Path $DevRepo "tools"
**********************
Command start time: 20250911205647
**********************
PS C:\Projects\GroundMesh-DEV> New-Item -ItemType Directory -Force -Path $Tools | Out-Null
**********************
Command start time: 20250911205647
**********************
PS C:\Projects\GroundMesh-DEV> @'
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
'@ | Set-Content -Encoding UTF8 (Join-Path $Tools 'publish-tail.ps1')
**********************
Command start time: 20250911205647
**********************
PS C:\Projects\GroundMesh-DEV> # Publish now so I can read it immediately
**********************
Command start time: 20250911205647
**********************
PS C:\Projects\GroundMesh-DEV> pt

**********************
Windows PowerShell transcript start
Start time: 20250911171115
Username: DESKTOP-C9G76VK\mailg
RunAs User: DESKTOP-C9G76VK\mailg
Configuration Name: 
Machine: DESKTOP-C9G76VK (Microsoft Windows NT 10.0.19045.0)
Host Application: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Process ID: 5576
PSVersion: 5.1.19041.6328
PSEdition: Desktop
PSCompatibleVersions: 1.0, 2.0, 3.0, 4.0, 5.0, 5.1.19041.6328
BuildVersion: 10.0.19041.6328
CLRVersion: 4.0.30319.42000
WSManStackVersion: 3.0
PSRemotingProtocolVersion: 2.3
SerializationVersion: 1.1.0.1
**********************
**********************
Command start time: 20250911171115
**********************
PS C:\Users\mailg> Write-Host "🟢 Transcript recording to: $Transcript"
🟢 Transcript recording to: C:\Projects\Bridge\transcripts\ps_transcript_20250911_171115.txt
**********************
Command start time: 20250911171211
**********************
PS [HOME]\\Projects
**********************
Command start time: 20250911171212
**********************
PS C:\Projects> New-Item -ItemType Directory -Force -Path C:\Projects\Bridge | Out-Null
**********************
Command start time: 20250911171212
**********************
PS C:\Projects> cd C:\Projects\Bridge
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> cd C:\Projects
**********************
Command start time: 20250911171240
**********************
PS C:\Projects> New-Item -ItemType Directory -Force -Path C:\Projects\Bridge | Out-Null
**********************
Command start time: 20250911171240
**********************
PS C:\Projects> cd C:\Projects\Bridge
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> @'
param(
  [string]$TranscriptDir = "C:\Projects\Bridge\transcripts",
  [int]$Port = 5059,
  [int]$Tail = 400
)

Add-Type -AssemblyName System.Net.HttpListener

$listener = [System.Net.HttpListener]::new()
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Clear()
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "🔎 Bridge reader listening on $prefix"

function Get-LatestTranscript {
  param([string]$Dir)
  $files = Get-ChildItem $Dir -Filter "ps_transcript_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($files) { return $files[0].FullName } else { return $null }
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $req = $ctx.Request
    $res = $ctx.Response

    switch ($req.Url.AbsolutePath) {
      "/tail" {
        $file = Get-LatestTranscript -Dir $TranscriptDir
        if (-not $file) {
          $msg = "No transcript files found."
          $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
          $res.StatusCode = 404
          $res.OutputStream.Write($bytes,0,$bytes.Length)
          break
        }
        $lines = Get-Content $file -ErrorAction SilentlyContinue | Select-Object -Last $Tail
        $text  = ($lines -join "`n")
        $bytes = [Text.Encoding]::UTF8.GetBytes($text)
        $res.ContentType = "text/plain; charset=utf-8"
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes,0,$bytes.Length)
      }
      default {
        $msg = "Use /tail to read the latest $Tail lines."
        $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
        $res.ContentType = "text/plain; charset=utf-8"
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes,0,$bytes.Length)
      }
    }
  } catch {
    Write-Host "Bridge error: $_" -ForegroundColor Red
  } finally {
    $ctx.Response.OutputStream.Close()
  }
}
'@ | Set-Content -Encoding UTF8 .\reader.ps1
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> # Verify it exists
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> Get-ChildItem .\reader.ps1


    Directory: C:\Projects\Bridge


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        11/09/2025     17:12           1848 reader.ps1



```
