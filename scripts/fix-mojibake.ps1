param(
  [Parameter()][string]$Root = ".",
  [switch]$Apply,
  [string[]]$Globs = @("**\*.md","**\*.html","**\*.yml","**\*.yaml","**\*.json","**\*.txt")
)

# Build mojibake sequences from Unicode code points (ASCII-only source)
function StrFromCodePoints([int[]]$codes) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($c in $codes) { [void]$sb.Append([char]$c) }
  $sb.ToString()
}

# Correct glyphs
$EMDASH = [string][char]0x2014
$ENDASH = [string][char]0x2013
$ELLIPS = [string][char]0x2026
$LSQUO  = [string][char]0x2018
$RSQUO  = [string][char]0x2019
$LDQUO  = [string][char]0x201C
$RDQUO  = [string][char]0x201D
$BULLET = [string][char]0x2022
$TIMES  = [string][char]0x00D7
$DIVIDE = [string][char]0x00F7
$NBSP   = [string][char]0x00A0
$REPL   = [string][char]0xFFFD

# Mojibake sequences when UTF-8 bytes got read as CP1252:
# em dash (0xE2 0x80 0x94) -> 'â' '' '”'  => U+00E2 U+20AC U+201D
$MJ_EMDASH = StrFromCodePoints(0x00E2,0x20AC,0x201D)
# en dash (0xE2 0x80 0x93) -> 'â' '' '“'  => U+00E2 U+20AC U+201C
$MJ_ENDASH = StrFromCodePoints(0x00E2,0x20AC,0x201C)
# ellipsis (0xE2 0x80 0xA6) -> 'â' '' '¦' => U+00E2 U+20AC U+00A6
$MJ_ELLIPS = StrFromCodePoints(0x00E2,0x20AC,0x00A6)
# left single quote (0xE2 0x80 0x98) -> 'â' '' '˜' => U+00E2 U+20AC U+02DC? (varies)
$MJ_LSQUO  = StrFromCodePoints(0x00E2,0x20AC,0x02DC)
# right single quote (0xE2 0x80 0x99) -> 'â' '' '™' => U+00E2 U+20AC U+2122
$MJ_RSQUO  = StrFromCodePoints(0x00E2,0x20AC,0x2122)
# left double quote (0xE2 0x80 0x9C) -> 'â' '' 'œ' => U+00E2 U+20AC U+0153
$MJ_LDQUO  = StrFromCodePoints(0x00E2,0x20AC,0x0153)
# right double quote (0xE2 0x80 0x9D) -> 'â' '' '�' => fallback varies; handle common form:
$MJ_RDQUO  = StrFromCodePoints(0x00E2,0x20AC,0x201D) # safe default

# stray 'Â' (U+00C2) often precedes spaces or symbols after mis-decoding
$CHAR_A_CIRC = [string][char]0x00C2

# Replacement map (built in-memory; script stays ASCII-safe)
$replacements = @(
  @{ from = $MJ_EMDASH; to = $EMDASH },
  @{ from = $MJ_ENDASH; to = $ENDASH },
  @{ from = $MJ_ELLIPS; to = $ELLIPS },
  @{ from = $MJ_LSQUO;  to = $LSQUO  },
  @{ from = $MJ_RSQUO;  to = $RSQUO  },
  @{ from = $MJ_LDQUO;  to = $LDQUO  },
  @{ from = $MJ_RDQUO;  to = $RDQUO  }
)

# Collect files
$files = @()
foreach ($g in $Globs) {
  $files += Get-ChildItem -Path $Root -Recurse -File -Include $g -ErrorAction SilentlyContinue
}

$encUTF8 = New-Object System.Text.UTF8Encoding($false)
$changed = @()

foreach ($f in $files) {
  $orig = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
  if ($null -eq $orig) { continue }

  $new = $orig

  foreach ($r in $replacements) {
    $new = $new -replace [regex]::Escape($r.from), [regex]::Escape($r.to).Replace("\","")
  }

  # Clean up common stray 'Â' artifacts
  $new = $new -replace ([regex]::Escape($CHAR_A_CIRC) + "\s"), " "
  $new = $new -replace [regex]::Escape($CHAR_A_CIRC), ""

  if ($new -ne $orig) {
    if ($Apply) {
      [System.IO.File]::WriteAllText($f.FullName, $new, $encUTF8)
    }
    $changed += $f.FullName
  }
}

if ($Apply) {
  "Applied fixes to {0} file(s):" -f $changed.Count
} else {
  "Preview: {0} file(s) would change (run with -Apply to write):" -f $changed.Count
}
$changed | ForEach-Object { " - $_" }