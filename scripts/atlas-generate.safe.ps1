\
    <#
      atlas-generate.safe.ps1
      Drop-in safer variant: generates docs/atlas/index.html and tolerates encoding glitches.
      Usage:
        pwsh -f scripts/atlas-generate.safe.ps1
    #>
    [CmdletBinding()]
    param(
      [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
      [string]$RegistryPath = (Join-Path $RepoRoot 'docs/atlas/registry.json'),
      [string]$OutPath = (Join-Path $RepoRoot 'docs/atlas/index.html')
    )
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # Read registry with robust UTF-8 handling (no BOM)
    function Read-JsonUtf8 {
      param([string]$Path)
      $bytes = [System.IO.File]::ReadAllBytes($Path)
      # Strip UTF-8 BOM if present
      if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length-1)]
      }
      $text = [System.Text.Encoding]::UTF8.GetString($bytes)
      return $text | ConvertFrom-Json -Depth 100
    }

    Write-Host "Building Atlas from $RegistryPath"
    $reg = Read-JsonUtf8 -Path $RegistryPath

    $items = @()
    foreach ($e in $reg.items) {
      $items += "<li><a href='$($e.href)'>$($e.title)</a> — <span class='badge'>$($e.category)</span></li>"
    }

    $html = @"
    <!doctype html>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GroundMesh — Atlas</title>
    <link rel="stylesheet" href="../assets/style.css">
    <header class="site">
      <div class="container">
        <strong><a href="/">GroundMesh</a></strong>
        <nav>
          <a href="/docs/get-started/index.html">Get Started</a>
          <a href="/docs/compute.html">Compute</a>
          <a href="/atlas/index.html">Atlas</a>
        </nav>
      </div>
    </header>
    <main class="container">
      <h1>Atlas</h1>
      <div class="card">
        <p>Auto-generated index from <code>docs/atlas/registry.json</code>.</p>
      </div>
      <ol>
        $('\n        ').Join("", @($items))
      </ol>
    </main>
    <footer class="site">
      <div class="container">© GroundMesh</div>
    </footer>
    "@

    New-Item -ItemType Directory -Force -Path (Split-Path $OutPath) | Out-Null
    Set-Content -Path $OutPath -Value $html -Encoding utf8
    Write-Host "Wrote $OutPath"
