# PowerShell Transcript Tail

- Updated: 2025-09-11 19:36:55
- Source file: ps_transcript_20250911_171115.txt

```text
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
