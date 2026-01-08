param(
  [string]$RegistryPath = "docs/atlas/registry.json",
  [string]$OutPath      = "docs/atlas/index.html"
)

# Stable repo-root: parent of /scripts
$RepoRoot = Split-Path -Parent $PSScriptRoot

$regAbs = Join-Path $RepoRoot $RegistryPath
$outAbs = Join-Path $RepoRoot $OutPath

if (!(Test-Path $regAbs)) { throw "Registry not found: $regAbs" }

$reg = Get-Content $regAbs -Raw | ConvertFrom-Json

# Accept either root array or object with .entries array
$entries = @()
if ($reg -is [System.Array]) {
  $entries = $reg
} elseif ($reg.PSObject.Properties.Name -contains "entries") {
  $entries = $reg.entries
} else {
  throw "Registry JSON must be an array or an object with 'entries'."
}

$entries = $entries | Sort-Object id

$rows = foreach ($e in $entries) {
  $id     = ($e.id     | Out-String).Trim()
  $name   = ($e.name   | Out-String).Trim()
  $type   = ($e.type   | Out-String).Trim()
  $status = ($e.status | Out-String).Trim()
  $path   = ($e.path   | Out-String).Trim()

  $link = if ($path) { "<a href=""../$path"">$id</a>" } else { $id }
  "<tr><td>$link</td><td>$name</td><td>$type</td><td>$status</td></tr>"
}

$html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>GroundMesh Atlas</title>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 2rem; }
    h1 { margin: 0 0 0.5rem 0; }
    p { margin: 0 0 1.25rem 0; color: #444; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 0.6rem; text-align: left; }
    th { background: #f6f6f6; }
    a { text-decoration: none; }
    a:hover { text-decoration: underline; }
    .meta { font-size: 0.9rem; color: #666; margin-top: 1rem; }
  </style>
</head>
<body>
  <h1>GroundMesh Atlas</h1>
  <p>Registry-backed map of governance artifacts and system components.</p>

  <table>
    <thead>
      <tr>
        <th>ID</th>
        <th>Name</th>
        <th>Type</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      $(if ($rows) { $rows -join "`n      " } else { "<tr><td colspan='4'><em>No entries yet.</em></td></tr>" })
    </tbody>
  </table>

  <div class="meta">Generated from <code>$RegistryPath</code></div>
</body>
</html>
"@

# Ensure output folder exists
$outDir = Split-Path -Parent $outAbs
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# Write UTF-8 without BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outAbs, $html, $utf8NoBom)

Write-Host "Atlas generated -> $OutPath"