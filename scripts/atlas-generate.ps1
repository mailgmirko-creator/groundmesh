param(
  [string]$BaseUrl = "https://mailgmirko-creator.github.io/groundmesh",
  [string]$RegistryPath = "docs/atlas/registry.json",
  [string]$OutPath = "docs/atlas/index.html"
)

if (-not (Test-Path $RegistryPath)) { throw "Registry not found: $RegistryPath" }
$reg = Get-Content $RegistryPath -Raw | ConvertFrom-Json

function Test-UrlOk($u) {
  if ([string]::IsNullOrWhiteSpace($u)) { return $null }
  try {
    $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
    return ($r.StatusCode -eq 200)
  } catch { return $false }
}

function Test-PathOk($p) { if ([string]::IsNullOrWhiteSpace($p)) { return $null } else { return (Test-Path $p) } }

$rows = @()
foreach ($c in $reg.components) {
  $pathOk = Test-PathOk $c.path
  $urlOk  = Test-UrlOk  $c.url
  $health = if (($pathOk -in $true,$null) -and ($urlOk -in $true,$null)) { "ok" } elseif ($pathOk -or $urlOk) { "partial" } else { "missing" }
  $rows += [pscustomobject]@{
    id=$c.id; name=$c.name; type=$c.type; status=$c.status; path=$c.path; url=$c.url; depends=($c.depends -join ", "); health=$health
  }
}

# Build HTML
$css = @"
:root { --bg:#0b0b0c; --card:#141417; --text:#e9e9ee; --muted:#b8b8c3; --ok:#6ee7b7; --warn:#facc15; --bad:#f87171 }
*{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--text);font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,"Noto Sans",sans-serif;line-height:1.45}
.wrap{max-width:1100px;margin:0 auto;padding:28px 20px}
h1{font-size:clamp(1.6rem,2.6vw,2.2rem);margin:0 0 8px}
p.lead{color:var(--muted);margin:0 0 16px}
.grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));margin-top:14px}
.card{background:var(--card);border:1px solid #23232a;border-radius:14px;padding:14px}
.k{color:var(--muted);font-size:.9rem;margin:0}
.v{margin:2px 0 0}
.badge{display:inline-block;padding:3px 8px;border-radius:999px;border:1px solid #2a2a33;font-size:.8rem;margin-left:6px}
.ok{color:var(--ok);border-color:#225b47} .partial{color:var(--warn);border-color:#5b4a22} .missing{color:var(--bad);border-color:#5b2222}
a.btn{display:inline-block;text-decoration:none;padding:10px 14px;border-radius:10px;border:1px solid #2a2a33;background:#1a1a20;color:var(--text);font-weight:600}
small{color:var(--muted)}
"@

$cards = ($rows | ForEach-Object {
  $link = if ($_.url) { "<a class='btn' href='$($_.url)'>Open</a>" } else { "<span class='btn' style='opacity:.5;cursor:not-allowed'>No URL</span>" }
  @"
  <div class='card'>
    <div class='v'><strong>$($_.name)</strong> <span class='badge $_.health'>$($_.health)</span></div>
    <p class='k'>type: $($_.type) · status: $($_.status)</p>
    <p class='k'>path: <code>$($_.path)</code></p>
    <p class='k'>depends: $($_.depends)</p>
    $link
  </div>
"@
}) -join "`n"

$html = @"
<!doctype html><html lang='en'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>
<title>GroundMesh — Project Atlas</title>
<style>$css</style>
<div class='wrap'>
  <h1>Project Atlas</h1>
  <p class='lead'>Single place to see what exists, where it lives, and how it connects. Update <code>docs/atlas/registry.json</code> whenever you add something new.</p>
  <div class='grid'>
    $cards
  </div>
  <p><small>Source registry: <code>docs/atlas/registry.json</code></small></p>
  <p><a class='btn' href='$Base/contribute.html'>← Back to Contributors</a>
     <a class='btn' href='$Base/compute.html'>Compute Transparency</a>
     <a class='btn' href='$Base/map.html'>Living Map</a>
  </p>
</div>
</html>
"@

$OutPath = "docs/atlas/index.html"
Set-Content $OutPath $html -Encoding UTF8
Write-Host "Wrote $OutPath"
