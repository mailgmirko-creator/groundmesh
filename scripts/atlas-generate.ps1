param(
  [string]$RegistryPath = "docs/atlas/registry.json",
  [string]$OutPath      = "docs/atlas/index.html"
)

# Stable repo-root: parent of /scripts
$RepoRoot = Split-Path -Parent $PSScriptRoot

$regAbs = Join-Path $RepoRoot $RegistryPath
$outAbs = Join-Path $RepoRoot $OutPath
$outDir = Split-Path -Parent $outAbs

if (!(Test-Path $regAbs)) { throw "Registry not found: $regAbs" }

$reg = Get-Content $regAbs -Raw | ConvertFrom-Json

function Get-RelativeHref {
  param(
    [string]$FromDirectory,
    [string]$ToPath
  )

  $fromUri = New-Object System.Uri((Resolve-Path $FromDirectory).Path.TrimEnd('\') + '\')
  $toUri = New-Object System.Uri((Resolve-Path $ToPath).Path)
  $relativeUri = $fromUri.MakeRelativeUri($toUri)
  return [System.Uri]::UnescapeDataString($relativeUri.ToString())
}

function Escape-Html {
  param([string]$Value)

  if ([string]::IsNullOrEmpty($Value)) { return "" }
  return [System.Net.WebUtility]::HtmlEncode($Value)
}

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
$entryCount = @($entries).Count
$activeCount = @($entries | Where-Object { (($_.status | Out-String).Trim()).ToLowerInvariant() -eq "active" }).Count

$rows = foreach ($e in $entries) {
  $id     = ($e.id     | Out-String).Trim()
  $name   = ($e.name   | Out-String).Trim()
  $type   = ($e.type   | Out-String).Trim()
  $status = ($e.status | Out-String).Trim()
  $path   = ($e.path   | Out-String).Trim()
  $summary = ($e.summary | Out-String).Trim()

  $idText = Escape-Html $id
  $nameText = Escape-Html $(if ($name) { $name } else { "Untitled entry" })
  $typeText = Escape-Html $(if ($type) { $type } else { "unknown" })
  $statusText = Escape-Html $(if ($status) { $status } else { "unknown" })
  $pathText = Escape-Html $(if ($path) { $path } else { "n/a" })
  $summaryText = Escape-Html $(if ($summary) { $summary } else { "No summary yet." })
  $statusClass = if ($status) { $status.ToLowerInvariant() -replace '[^a-z0-9]+', '-' } else { "unknown" }

  $link = if ($path) {
    $targetAbs = Join-Path $RepoRoot $path
    if (Test-Path $targetAbs) {
      $href = Escape-Html (Get-RelativeHref -FromDirectory $outDir -ToPath $targetAbs)
      "<a class=""id-link"" href=""$href"">$idText</a>"
    } else {
      "<span class=""id-link missing"">$idText</span>"
    }
  } else { "<span class=""id-link missing"">$idText</span>" }

  @"
<tr>
  <td>$link</td>
  <td><strong>$nameText</strong></td>
  <td><span class="chip">$typeText</span></td>
  <td><span class="status status-$statusClass">$statusText</span></td>
  <td><code>$pathText</code></td>
  <td>$summaryText</td>
</tr>
"@
}

$html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>GroundMesh Atlas</title>
  <style>
    :root {
      --bg: #f3efe6;
      --paper: #fffdf8;
      --ink: #1d251f;
      --muted: #566259;
      --line: #d8d0c2;
      --accent: #1f5c46;
      --accent-soft: #dbece3;
      --gold: #c68a2a;
      --shadow: rgba(63, 49, 29, 0.10);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: radial-gradient(circle at top, #fffdf8 0, var(--bg) 58%, #e7dece 100%);
      color: var(--ink);
      font-family: Georgia, "Times New Roman", serif;
      line-height: 1.55;
    }
    .wrap { max-width: 1180px; margin: 0 auto; padding: 28px 20px 56px; }
    .hero, .card {
      background: linear-gradient(135deg, rgba(255,253,248,.94), rgba(246,241,232,.92));
      border: 1px solid var(--line);
      border-radius: 24px;
      box-shadow: 0 18px 50px var(--shadow);
    }
    .hero { padding: 28px; }
    .eyebrow {
      display: inline-block;
      padding: 6px 10px;
      border-radius: 999px;
      background: var(--accent-soft);
      color: var(--accent);
      font: 600 .85rem/1.2 "Segoe UI", Arial, sans-serif;
      letter-spacing: .04em;
      text-transform: uppercase;
    }
    h1 { margin: 14px 0 10px; font-size: clamp(2rem, 4.5vw, 3.4rem); line-height: 1.04; }
    p { margin: 0; color: var(--muted); }
    .lede { max-width: 68ch; font-size: 1.05rem; }
    .quicklinks, .stats {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      margin-top: 18px;
    }
    .quicklinks a {
      display: inline-block;
      padding: 10px 14px;
      border-radius: 12px;
      border: 1px solid var(--accent);
      background: var(--accent);
      color: #fff;
      text-decoration: none;
      font: 600 .95rem/1.2 "Segoe UI", Arial, sans-serif;
    }
    .quicklinks a.secondary {
      background: transparent;
      color: var(--accent);
    }
    .stat {
      min-width: 150px;
      padding: 14px 16px;
      border-radius: 16px;
      background: rgba(255,253,248,.76);
      border: 1px solid var(--line);
    }
    .stat .label {
      display: block;
      margin-bottom: 6px;
      color: var(--muted);
      font: 600 .82rem/1.2 "Segoe UI", Arial, sans-serif;
      text-transform: uppercase;
      letter-spacing: .04em;
    }
    .stat strong { font-size: 1.55rem; }
    .guide {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-top: 20px;
    }
    .card { padding: 18px; }
    .card h2 {
      margin: 0 0 8px;
      font-size: 1.08rem;
      font-family: "Segoe UI", Arial, sans-serif;
    }
    .table-card {
      margin-top: 20px;
      overflow: hidden;
    }
    .table-wrap { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; }
    th, td {
      padding: 0.85rem 0.8rem;
      border-top: 1px solid var(--line);
      text-align: left;
      vertical-align: top;
    }
    th {
      color: var(--muted);
      font: 600 .82rem/1.2 "Segoe UI", Arial, sans-serif;
      text-transform: uppercase;
      letter-spacing: .04em;
      background: rgba(219,236,227,.45);
    }
    tr:first-child td { border-top: 0; }
    .id-link {
      color: var(--accent);
      text-decoration: none;
      font: 700 .95rem/1.2 "Segoe UI", Arial, sans-serif;
    }
    .id-link:hover { text-decoration: underline; }
    .id-link.missing { color: #915d21; }
    .chip, .status {
      display: inline-block;
      padding: 0.32rem 0.58rem;
      border-radius: 999px;
      font: 600 .8rem/1.2 "Segoe UI", Arial, sans-serif;
      white-space: nowrap;
    }
    .chip {
      background: #efe8dc;
      border: 1px solid #ddd1bd;
      color: #5f5646;
    }
    .status {
      border: 1px solid #cfe0d7;
      background: #eff7f2;
      color: #20563f;
    }
    .status-active {
      border-color: #cfe0d7;
      background: #eff7f2;
      color: #20563f;
    }
    code {
      display: inline-block;
      padding: 0.15rem 0.4rem;
      border-radius: 6px;
      background: #efe7d9;
      color: #4f4637;
      font-family: Consolas, "Courier New", monospace;
      word-break: break-word;
    }
    .meta {
      margin-top: 14px;
      color: var(--muted);
      font-size: 0.92rem;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <div class="eyebrow">GroundMesh Atlas</div>
      <h1>The living map of what already exists.</h1>
      <p class="lede">Atlas is the orientation layer for GroundMesh. Open this before adding new structure, so the project grows through continuity rather than drift.</p>
      <div class="quicklinks">
        <a href="../index.html">Start Here</a>
        <a class="secondary" href="../contribute.html">Contribute</a>
        <a class="secondary" href="../map.html">Map</a>
        <a class="secondary" href="../compute.html">Compute</a>
        <a class="secondary" href="../landscape.html">Landscape</a>
      </div>
      <div class="stats">
        <div class="stat">
          <span class="label">Entries</span>
          <strong>$entryCount</strong>
        </div>
        <div class="stat">
          <span class="label">Active</span>
          <strong>$activeCount</strong>
        </div>
      </div>
    </section>

    <section class="guide">
      <article class="card">
        <h2>1. Orient first</h2>
        <p>Scan the registry before creating new files, pages, or concepts.</p>
      </article>
      <article class="card">
        <h2>2. Reuse what exists</h2>
        <p>Follow linked artifacts outward and prefer extension over duplication.</p>
      </article>
      <article class="card">
        <h2>3. Grow carefully</h2>
        <p>When new artifacts are added, update the registry so humans and systems stay aligned.</p>
      </article>
    </section>

    <section class="card table-card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Type</th>
              <th>Status</th>
              <th>Path</th>
              <th>Summary</th>
            </tr>
          </thead>
          <tbody>
            $(if ($rows) { $rows -join "`n            " } else { "<tr><td colspan='6'><em>No entries yet.</em></td></tr>" })
          </tbody>
        </table>
      </div>
    </section>

    <div class="meta">Generated from <code>$RegistryPath</code></div>
  </div>
</body>
</html>
"@

# Ensure output folder exists
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# Write UTF-8 without BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outAbs, $html, $utf8NoBom)

Write-Host "Atlas generated -> $OutPath"
