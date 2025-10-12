param(
  [Parameter(Mandatory=$true)][string[]]$Files
)

$Repo = Split-Path -Parent $PSScriptRoot
$FooterPath = Join-Path $Repo "docs\_templates\authorship-footer.md"

if (-not (Test-Path $FooterPath)) {
  Write-Error "Footer template not found at $FooterPath"
  exit 1
}

$footer = Get-Content $FooterPath -Raw

foreach ($f in $Files) {
  if (-not (Test-Path $f)) { Write-Warning "Skip: $f not found"; continue }
  $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
  if ($ext -notin @(".md",".mdx",".txt")) { Write-Warning "Skip: $f (not a text doc)"; continue }

  $content = Get-Content $f -Raw
  # If footer already present, skip
  if ($content -match '### Authorship\s+Mirko Gilja') {
    Write-Host "Footer already present -> $f"
    continue
  }

  $new = $content.TrimEnd() + "`r`n`r`n" + $footer + "`r`n"
  [System.IO.File]::WriteAllText($f, $new, (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "Appended footer -> $f"
}