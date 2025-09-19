param(
  [Parameter(Mandatory=$true)][string]$Title
)
$slug = ($Title.ToLower() -replace "[^a-z0-9]+","-").Trim("-")
$path = "proposals/$((Get-Date).ToString("yyyyMMdd"))_$slug.md"
$tpl = Get-Content "proposals/spec-template.md" -Raw
$tpl -replace "# Title","# $Title" | Set-Content $path -Encoding UTF8
Write-Host "Created $path"
