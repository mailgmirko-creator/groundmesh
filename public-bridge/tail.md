# PowerShell Transcript Tail (Aggregated)

- Updated: 2025-09-11 20:26:12

```text
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> if ($py) { & python "apps/tsl/tsl_core/learner.py" "apps/tsl/principles/principles.yaml" "apps/tsl/artifacts" }

**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> # Commit via message file (avoids quoting issues)
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> $MsgFile = Join-Path $DevRepo "COMMITMSG.txt"
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> Set-Content -Path $MsgFile -Encoding UTF8 -Value "feat(tsl): scaffold with 7 principles and learner stub"
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> git add apps/tsl

**********************
Command start time: 20250911202303
**********************
PS C:\Projects\GroundMesh-DEV> git commit -F $MsgFile

**********************
Command start time: 20250911202303
**********************
PS C:\Projects\GroundMesh-DEV> git push -u origin dev

**********************
Command start time: 20250911202305
**********************
PS C:\Projects\GroundMesh-DEV> Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue
**********************
Command start time: 20250911202305
**********************
PS C:\Projects\GroundMesh-DEV> # refresh PSO snapshot so I can read it automatically
**********************
Command start time: 20250911202305
**********************
PS C:\Projects\GroundMesh-DEV> pt




**********************
Command start time: 20250911202539
**********************
PS C:\Projects\GroundMesh-DEV> # === Set up dedicated worktree for bridge-public and update the publisher to use it ===
**********************
Command start time: 20250911202539
**********************
PS C:\Projects\GroundMesh-DEV> $DevRepo = "C:\Projects\GroundMesh-DEV"
**********************
Command start time: 20250911202540
**********************
PS C:\Projects\GroundMesh-DEV> $WT      = "C:\Projects\GroundMesh-DEV\.bridge-wt"
**********************
Command start time: 20250911202540
**********************
PS C:\Projects\GroundMesh-DEV> cd $DevRepo
**********************
Command start time: 20250911202540
**********************
PS C:\Projects\GroundMesh-DEV> # 1) Fetch and create a clean worktree for bridge-public
**********************
Command start time: 20250911202540
**********************
PS C:\Projects\GroundMesh-DEV> git fetch origin

**********************
Command start time: 20250911202542
**********************
PS C:\Projects\GroundMesh-DEV> & git worktree remove --force $WT 2>$null
git.exe : fatal: 'C:\Projects\GroundMesh-DEV\.bridge-wt' is not a working tree
At line:1 char:1
+ & git worktree remove --force $WT 2>$null
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (fatal: 'C:\Proj... a working tree:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError

**********************
Command start time: 20250911202542
**********************
PS C:\Projects\GroundMesh-DEV> # If branch doesn't exist yet remotely, this creates local branch from current HEAD; else tracks remote.
**********************
Command start time: 20250911202542
**********************
PS C:\Projects\GroundMesh-DEV> if ((git ls-remote --heads origin bridge-public) -ne $null) {
  git worktree add -B bridge-public $WT origin/bridge-public
} else {
  git worktree add -B bridge-public $WT
  Push-Location $WT; git push -u origin bridge-public; Pop-Location
}

**********************
Command start time: 20250911202544
**********************
PS C:\Projects\GroundMesh-DEV> # 2) Ensure no stray public-bridge files linger in the main worktree
**********************
Command start time: 20250911202544
**********************
PS C:\Projects\GroundMesh-DEV> Remove-Item -Recurse -Force (Join-Path $DevRepo "public-bridge") -ErrorAction SilentlyContinue
**********************
Command start time: 20250911202544
**********************
PS C:\Projects\GroundMesh-DEV> # 3) Overwrite publisher to use the dedicated worktree
**********************
Command start time: 20250911202544
**********************
PS C:\Projects\GroundMesh-DEV> $Tools = Join-Path $DevRepo "tools"
**********************
Command start time: 20250911202544
**********************
PS C:\Projects\GroundMesh-DEV> New-Item -ItemType Directory -Force -Path $Tools | Out-Null
**********************
Command start time: 20250911202606
**********************
PS C:\Projects\GroundMesh-DEV> # === Set up dedicated worktree for bridge-public and update the publisher to use it ===
**********************
Command start time: 20250911202607
**********************
PS C:\Projects\GroundMesh-DEV> $DevRepo = "C:\Projects\GroundMesh-DEV"
**********************
Command start time: 20250911202607
**********************
PS C:\Projects\GroundMesh-DEV> $WT      = "C:\Projects\GroundMesh-DEV\.bridge-wt"
**********************
Command start time: 20250911202607
**********************
PS C:\Projects\GroundMesh-DEV> cd $DevRepo
**********************
Command start time: 20250911202607
**********************
PS C:\Projects\GroundMesh-DEV> # 1) Fetch and create a clean worktree for bridge-public
**********************
Command start time: 20250911202607
**********************
PS C:\Projects\GroundMesh-DEV> git fetch origin

**********************
Command start time: 20250911202609
**********************
PS C:\Projects\GroundMesh-DEV> & git worktree remove --force $WT 2>$null

**********************
Command start time: 20250911202609
**********************
PS C:\Projects\GroundMesh-DEV> # If branch doesn't exist yet remotely, this creates local branch from current HEAD; else tracks remote.
**********************
Command start time: 20250911202609
**********************
PS C:\Projects\GroundMesh-DEV> if ((git ls-remote --heads origin bridge-public) -ne $null) {
  git worktree add -B bridge-public $WT origin/bridge-public
} else {
  git worktree add -B bridge-public $WT
  Push-Location $WT; git push -u origin bridge-public; Pop-Location
}

**********************
Command start time: 20250911202612
**********************
PS C:\Projects\GroundMesh-DEV> # 2) Ensure no stray public-bridge files linger in the main worktree
**********************
Command start time: 20250911202612
**********************
PS C:\Projects\GroundMesh-DEV> Remove-Item -Recurse -Force (Join-Path $DevRepo "public-bridge") -ErrorAction SilentlyContinue
**********************
Command start time: 20250911202612
**********************
PS C:\Projects\GroundMesh-DEV> # 3) Overwrite publisher to use the dedicated worktree
**********************
Command start time: 20250911202612
**********************
PS C:\Projects\GroundMesh-DEV> $Tools = Join-Path $DevRepo "tools"
**********************
Command start time: 20250911202612
**********************
PS C:\Projects\GroundMesh-DEV> New-Item -ItemType Directory -Force -Path $Tools | Out-Null
**********************
Command start time: 20250911202612
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

# 2) Merge lines from picked files
$lines  = New-Object System.Collections.Generic.List[string]
foreach ($f in $pick) {
  $t = Read-UnlockedText -Path $f.FullName
  if ($t) {
    $parts = [Text.RegularExpressions.Regex]::Split($t,'\r?\n')
    foreach ($p in $parts) { if ($p -ne $null) { $lines.Add($p) | Out-Null } }
  }
}

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
