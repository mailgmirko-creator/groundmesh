param(
  [string]$Base = "https://mailgmirko-creator.github.io/groundmesh"
)

$urls = @(
  "$Base/",
  "$Base/contribute.html",
  "$Base/map.html",
  "$Base/atlas/index.html",
  "$Base/compute.html",
  "$Base/contributors-quickstart.md"
)

$files = @(
  "docs/contribute.html",
  "docs/map.html",
  "docs/assistant-brief.md",
  "docs/glossary.md",
  "docs/decisions/0001-why-atlas.md",
  "docs/data/status.json",
  "docs/atlas/registry.json",
  "docs/atlas/index.html"
)

Write-Host "`n== LIVE PAGES =="
$ok=0;$bad=0
foreach($u in $urls){
  try{ $r=Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 10
    if($r.StatusCode -eq 200){ Write-Host "OK  $u"; $ok++ } else { Write-Host "BAD $u ($($r.StatusCode))"; $bad++ }
  } catch { Write-Host "BAD $u (fetch error)"; $bad++ }
}

Write-Host "`n== LOCAL FILES =="
$lok=0;$lbad=0
foreach($p in $files){
  if(Test-Path $p){ Write-Host "OK  $p"; $lok++ } else { Write-Host "MISS $p"; $lbad++ }
}

Write-Host "`n== SUMMARY =="
Write-Host "Live OK: $ok  Live BAD: $bad"
Write-Host "Files OK: $lok  Files MISS: $lbad"
