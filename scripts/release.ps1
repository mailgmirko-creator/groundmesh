$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root "docs"
$rels = Join-Path $root "releases"
New-Item -ItemType Directory -Path $rels -Force | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zip   = Join-Path $rels "site-$stamp.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $src "*") -DestinationPath $zip

# Use .NET directly instead of Get-FileHash so release creation works in both
# Windows PowerShell and pwsh environments, including GitHub-hosted runners.
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$stream = [System.IO.File]::OpenRead($zip)
try {
  $hashBytes = $sha256.ComputeHash($stream)
  $hash = -join ($hashBytes | ForEach-Object { $_.ToString("X2") })
} finally {
  $stream.Dispose()
  $sha256.Dispose()
}

$man  = Join-Path $rels "site-$stamp.sha256.txt"
("$([IO.Path]::GetFileName($zip))  SHA256=$hash") | Out-File -FilePath $man -Encoding utf8
Write-Host "Release created: $zip"
Write-Host "SHA256: $hash"
