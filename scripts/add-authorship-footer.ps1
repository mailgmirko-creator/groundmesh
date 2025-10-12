param(
  [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
  [object[]]$Files
)

# Normalize to a clean string[] even if user passed one comma-separated string
$flat = @()
foreach ($item in $Files) {
  if ($null -eq $item) { continue }
  $s = $item.ToString()
  if ($s -match ",") {
    $s.Split(",") | ForEach-Object { $flat += $_.Trim() }
  } else {
    $flat += $s.Trim()
  }
}
$Files = $flat | Where-Object { $_ -ne "" } | Select-Object -Unique

$Repo = Split-Path -Parent $PSScriptRoot
$FooterPath = Join-Path $Repo "docs\_templates\authorship-footer.md"

if (-not (Test-Path $FooterPath)) {
  Write-Error "Footer template not found at $FooterPath"
  exit 1
}

$footer = Get-Content $FooterPath -Raw
$enc = New-Object System.Text.UTF8Encoding($false)

foreach ($f in $Files) {
  if (-not (Test-Path $f)) { Write-Warning "Skip: $f not found"; continue }
  $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
  if ($ext -notin @(".md",".mdx",".txt")) { Write-Warning "Skip: $f (not a text doc)"; continue }

  $content = Get-Content $f -Raw
  if ($content -match '### Authorship\s+Mirko Gilja') {
    Write-Host "Footer already present -> $f"
    continue
  }

  $new = $content.TrimEnd() + "`r`n`r`n" + $footer + "`r`n"
  [System.IO.File]::WriteAllText((Resolve-Path $f), $new, $enc)
  Write-Host "Appended footer -> $f"
}