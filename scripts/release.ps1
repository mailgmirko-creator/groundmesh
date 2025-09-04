$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root "docs"
$rels = Join-Path $root "releases"
New-Item -ItemType Directory -Path $rels -Force | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zip   = Join-Path $rels "site-$stamp.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $src "*") -DestinationPath $zip
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash
$man  = Join-Path $rels "site-$stamp.sha256.txt"
("$([IO.Path]::GetFileName($zip))  SHA256=$hash") | Out-File -FilePath $man -Encoding utf8
Write-Host "Release created: $zip"
Write-Host "SHA256: $hash"
