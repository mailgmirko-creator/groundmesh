\
    <#
      Fix-Encoding-And-JSON.ps1
      Normalizes file encodings to UTF-8 (no BOM) and validates JSON across the repo.
      Usage:
        pwsh -f tools/Fix-Encoding-And-JSON.ps1
    #>
    [CmdletBinding()]
    param(
      [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    )
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    Write-Host "==> Normalizing encodings to UTF-8 (no BOM) under '$Root'"

    $textExt = @('*.md','*.html','*.css','*.js','*.json','*.schema.json','*.yml','*.yaml','*.ps1','*.psm1','*.txt')

    $files = foreach ($p in $textExt) { Get-ChildItem -Path $Root -Recurse -Include $p -File -ErrorAction SilentlyContinue }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    $converted = 0
    $unchanged = 0

    foreach ($f in $files) {
      # Skip files in .git or node_modules just in case
      if ($f.FullName -match '\\.git\\' -or $f.FullName -match '\\node_modules\\') { continue }

      $bytes = [System.IO.File]::ReadAllBytes($f.FullName)

      # Detect common BOMs
      $hasUtf8Bom   = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
      $hasUtf16LE   = ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE)
      $hasUtf16BE   = ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF)

      $text = $null
      if ($hasUtf16LE) {
        $enc = [System.Text.Encoding]::Unicode
        $text = $enc.GetString($bytes, 2, $bytes.Length - 2)
      } elseif ($hasUtf16BE) {
        $enc = [System.Text.Encoding]::BigEndianUnicode
        $text = $enc.GetString($bytes, 2, $bytes.Length - 2)
      } elseif ($hasUtf8Bom) {
        $enc = [System.Text.Encoding]::UTF8
        $text = $enc.GetString($bytes, 3, $bytes.Length - 3)
      } else {
        # Best effort: try UTF-8 first, then current ANSI code page
        try {
          $text = [System.Text.Encoding]::UTF8.GetString($bytes)
          # Re-encode/round-trip to ensure valid UTF-8
          $round = [System.Text.Encoding]::UTF8.GetBytes($text)
          if ($round.Length -ne $bytes.Length) {
            throw "Round-trip mismatch"
          }
        } catch {
          $ansi = [System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)
          $text = $ansi.GetString($bytes)
        }
      }

      # Ensure LF line endings
      $text = $text -replace "`r`n", "`n"
      $text = $text -replace "`r", "`n"

      $newBytes = $utf8NoBom.GetBytes($text)

      if (-not ($newBytes.Length -eq $bytes.Length -and [System.Linq.Enumerable]::SequenceEqual($newBytes, $bytes))) {
        [System.IO.File]::WriteAllBytes($f.FullName, $newBytes)
        $converted++
      } else {
        $unchanged++
      }
    }

    Write-Host ("Converted: {0} | Unchanged: {1}" -f $converted, $unchanged)

    # --- JSON validation pass ---
    Write-Host "==> Validating JSON files..."
    $bad = @()
    $jsonFiles = Get-ChildItem -Path $Root -Recurse -Include *.json,*.schema.json -File -ErrorAction SilentlyContinue
    foreach ($jf in $jsonFiles) {
      try {
        $raw = Get-Content -Path $jf.FullName -Raw -Encoding utf8
        $null = $raw | ConvertFrom-Json -Depth 100
      } catch {
        $bad += [pscustomobject]@{ File=$jf.FullName; Error=$_.Exception.Message }
      }
    }
    if ($bad.Count -gt 0) {
      Write-Host "==> JSON problems detected:" -ForegroundColor Yellow
      $bad | Format-Table -AutoSize
      throw "JSON validation failed for $($bad.Count) file(s)."
    } else {
      Write-Host "All JSON files valid."
    }
