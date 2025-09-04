# scripts/ipfs_publish.ps1
$ErrorActionPreference = "SilentlyContinue"

# Resolve repo root from this script's location
$root = Split-Path -Parent $PSScriptRoot
$docs = Join-Path $root "docs"
$cidsDir = Join-Path $root "data\cids"
$logsDir = Join-Path $root "data\logs"
New-Item -ItemType Directory -Path $cidsDir -Force | Out-Null
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

# Run upload and capture ALL output (stdout+stderr)
$result = (& w3 up $docs 2>&1) -join "`r`n"
$lastUpload = Join-Path $cidsDir "last-upload.txt"
Set-Content -Path $lastUpload -Value $result -Encoding UTF8

# Extract the newest bafy... CID
$matches = [regex]::Matches($result, 'bafy[a-z0-9]+')
if ($matches.Count -gt 0) {
    $cid = $matches[$matches.Count - 1].Value
    $latest = Join-Path $cidsDir "latest.txt"
    Set-Content -Path $latest -Value $cid -Encoding UTF8
    Write-Host "CID=$cid"
} else {
    Write-Warning "CID not found in output. Check $lastUpload"
    exit 1
}

# Quick gateway checks (HEAD)
$urls = @("https://w3s.link/ipfs/$cid", "https://ipfs.io/ipfs/$cid")
foreach ($u in $urls) {
    Write-Host "HEAD $u"
    try { & curl.exe -I --max-time 20 $u } catch { Write-Warning $_ }
}

# Log a publish line
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logPath = Join-Path $logsDir ("publish-{0}.txt" -f (Get-Date -Format "yyyyMMdd"))
Add-Content -Path $logPath -Value ("{0} CID={1}" -f $stamp, $cid)
Write-Host "Wrote log: $logPath"
