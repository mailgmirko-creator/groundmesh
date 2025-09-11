# PowerShell Transcript Tail (Aggregated)

- Updated: 2025-09-11 20:33:45

```text
# 3) Global tail → redact
$globalTail = $lines | Select-Object -Last $Count
if (-not $globalTail) { $globalTail = @('<empty>') }
$redacted = foreach ($line in $globalTail) {
  $x = $line
  $x = [regex]::Replace($x,'ghp_[A-Za-z0-9]{36,}','[REDACTED_GH_TOKEN]')
  $x = [regex]::Replace($x,'sk-[A-Za-z0-9\-_]{20,}','[REDACTED_KEY]')
  $x = [regex]::Replace($x,'Bearer\s+[A-Za-z0-9\._\-]+','Bearer [REDACTED]')
  $x = [regex]::Replace($x,'([A-Za-z]:\\Users\\[^\\]+\\)','[HOME]\\')
  $x
}

# 4) Write outputs into the WORKTREE (not the main tree)
$OutDir  = Join-Path $WorktreeRoot 'public-bridge'
$TxtFile = Join-Path $OutDir 'tail.txt'
$MdFile  = Join-Path $OutDir 'tail.md'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$enc = New-Object Text.UTF8Encoding($false)
$updated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

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

# 5) Commit & push from INSIDE the worktree
Push-Location $WorktreeRoot
$MsgFile = Join-Path (Get-Location) 'COMMITMSG.txt'
Set-Content -Path $MsgFile -Value 'publish tail snapshot (worktree)' -Encoding UTF8
& git add public-bridge\tail.txt
& git add public-bridge\tail.md
& git commit -F $MsgFile
& git push -u origin bridge-public
Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue
Pop-Location
'@ | Set-Content -Encoding UTF8 (Join-Path $Tools 'publish-tail.ps1')
**********************
Command start time: 20250911202612
**********************
PS C:\Projects\GroundMesh-DEV> # 4) Publish now (eyes auto-refresh), no branch switching in main tree
**********************
Command start time: 20250911202612
**********************
PS C:\Projects\GroundMesh-DEV> pt




**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> # === Add a minimal TSL job runner, commit to dev, run once, refresh eyes ===
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> $DevRepo = "C:\Projects\GroundMesh-DEV"
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> cd $DevRepo
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> git checkout dev

**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> $Tools = Join-Path $DevRepo "tools"
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> New-Item -ItemType Directory -Force -Path $Tools | Out-Null
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> @'
param(
  [string]$JobFile = "apps/tsl/jobs/learn_principles.json"
)

if (-not (Test-Path $JobFile)) {
  Write-Host "Job file not found: $JobFile"
  exit 1
}

try {
  $job = Get-Content $JobFile -Raw | ConvertFrom-Json
} catch {
  Write-Host "Failed to parse job JSON: $JobFile"
  exit 1
}

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
  Write-Host "Python not found on PATH. Install Python 3.8+."
  exit 1
}

$inYaml  = $job.inputs.principles_yaml
$outDir  = $job.outputs.artifact_dir
$model   = Join-Path $outDir ($job.outputs.model_file)

# Ensure output directory exists
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Run the learner
& python "apps/tsl/tsl_core/learner.py" $inYaml $outDir
if ($LASTEXITCODE -ne 0) {
  Write-Host "Learner failed with exit code $LASTEXITCODE."
  exit $LASTEXITCODE
}

# Simple verification
if (Test-Path $model) {
  $size = (Get-Item $model).Length
  Write-Host "Model written: $model ($size bytes)"
} else {
  Write-Host "Model file not found after run: $model"
}

'@ | Set-Content -Encoding UTF8 (Join-Path $Tools "run-tsl.ps1")
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> # Commit runner
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> $MsgFile = Join-Path $DevRepo "COMMITMSG.txt"
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> Set-Content -Path $MsgFile -Encoding UTF8 -Value "feat(tsl): add minimal job runner (PowerShell)"
**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> git add tools/run-tsl.ps1

**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> git commit -F $MsgFile

**********************
Command start time: 20250911203031
**********************
PS C:\Projects\GroundMesh-DEV> git push -u origin dev

**********************
Command start time: 20250911203034
**********************
PS C:\Projects\GroundMesh-DEV> Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue
**********************
Command start time: 20250911203034
**********************
PS C:\Projects\GroundMesh-DEV> # Run the job once (optional) and refresh eyes so I can see it
**********************
Command start time: 20250911203034
**********************
PS C:\Projects\GroundMesh-DEV> & "C:\Projects\GroundMesh-DEV\tools\run-tsl.ps1"

Model written: apps\tsl\artifacts\principles_model.json (5331 bytes)
**********************
Command start time: 20250911203034
**********************
PS C:\Projects\GroundMesh-DEV> pt




**********************
Command start time: 20250911203344
**********************
PS C:\Projects\GroundMesh-DEV> # Ensure TSL job runner exists, then run it and refresh eyes
**********************
Command start time: 20250911203344
**********************
PS C:\Projects\GroundMesh-DEV> $DevRepo = "C:\Projects\GroundMesh-DEV"
**********************
Command start time: 20250911203344
**********************
PS C:\Projects\GroundMesh-DEV> $Tools   = Join-Path $DevRepo "tools"
**********************
Command start time: 20250911203344
**********************
PS C:\Projects\GroundMesh-DEV> $Runner  = Join-Path $Tools "run-tsl.ps1"
**********************
Command start time: 20250911203344
**********************
PS C:\Projects\GroundMesh-DEV> cd $DevRepo
**********************
Command start time: 20250911203345
**********************
PS C:\Projects\GroundMesh-DEV> git checkout dev

**********************
Command start time: 20250911203345
**********************
PS C:\Projects\GroundMesh-DEV> New-Item -ItemType Directory -Force -Path $Tools | Out-Null
**********************
Command start time: 20250911203345
**********************
PS C:\Projects\GroundMesh-DEV> if (-not (Test-Path $Runner)) {
@'
param(
  [string]$JobFile = "apps/tsl/jobs/learn_principles.json"
)

if (-not (Test-Path $JobFile)) { Write-Host "Job file not found: $JobFile"; exit 1 }

try { $job = Get-Content $JobFile -Raw | ConvertFrom-Json }
catch { Write-Host "Failed to parse job JSON: $JobFile"; exit 1 }

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { Write-Host "Python not found on PATH. Install Python 3.8+."; exit 1 }

$inYaml  = $job.inputs.principles_yaml
$outDir  = $job.outputs.artifact_dir
$model   = Join-Path $outDir ($job.outputs.model_file)

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

& python "apps/tsl/tsl_core/learner.py" $inYaml $outDir
if ($LASTEXITCODE -ne 0) { Write-Host "Learner failed with exit code $LASTEXITCODE."; exit $LASTEXITCODE }

if (Test-Path $model) {
  $size = (Get-Item $model).Length
  Write-Host "Model written: $model ($size bytes)"
} else {
  Write-Host "Model file not found after run: $model"
}
'@ | Set-Content -Encoding UTF8 $Runner

  # commit the new runner
  $MsgFile = Join-Path $DevRepo "COMMITMSG.txt"
  Set-Content -Path $MsgFile -Encoding UTF8 -Value "feat(tsl): add minimal job runner (PowerShell)"
  git add $Runner
  git commit -F $MsgFile
  git push -u origin dev
  Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue
}
**********************
Command start time: 20250911203345
**********************
PS C:\Projects\GroundMesh-DEV> # Run the job once and refresh eyes so I can read the PSO automatically
**********************
Command start time: 20250911203345
**********************
PS C:\Projects\GroundMesh-DEV> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
**********************
Command start time: 20250911203345
**********************
PS C:\Projects\GroundMesh-DEV> & $Runner

Model written: apps\tsl\artifacts\principles_model.json (5331 bytes)
**********************
Command start time: 20250911203345
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
