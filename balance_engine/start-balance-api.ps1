$Root = $PSScriptRoot
Set-Location $Root

$VenvActivate = Join-Path $Root ".venv\Scripts\Activate.ps1"
if (Test-Path -LiteralPath $VenvActivate -PathType Leaf) {
  . $VenvActivate
}

if ([string]::IsNullOrWhiteSpace($env:PYTHONPATH)) {
  $env:PYTHONPATH = $Root
}
else {
  $env:PYTHONPATH = "$Root$([System.IO.Path]::PathSeparator)$env:PYTHONPATH"
}
python -m api.service
