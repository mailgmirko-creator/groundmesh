param(
  [string]$ValidatorPath = "scripts/behavior-atlas-validate.ps1",
  [string]$FixtureDir = "tests/behavior-atlas/fixtures"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-RepoPath {
  param([string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  return Join-Path $RepoRoot $Path
}

$validatorAbs = Resolve-RepoPath -Path $ValidatorPath
$fixtureAbs = Resolve-RepoPath -Path $FixtureDir

if (-not (Test-Path $validatorAbs)) { throw "Validator not found: $validatorAbs" }
if (-not (Test-Path $fixtureAbs)) { throw "Fixture directory not found: $fixtureAbs" }

$shellCommand = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $shellCommand) {
  $shellCommand = Get-Command powershell -ErrorAction Stop
}

$fixtures = @(Get-ChildItem -Path $fixtureAbs -Filter "fail-*.json" -File | Sort-Object Name)
if ($fixtures.Count -lt 1) {
  throw "No negative Behavior Atlas fixtures found in $fixtureAbs."
}

$failures = @()

foreach ($fixture in $fixtures) {
  Write-Host ("Expecting rejection: {0}" -f $fixture.Name)
  $output = & $shellCommand.Source -NoProfile -File $validatorAbs -DataPath $fixture.FullName -RequireSynthetic 2>&1
  $exitCode = $LASTEXITCODE

  if ($exitCode -eq 0) {
    $failures += ("Negative fixture unexpectedly passed: {0}" -f $fixture.FullName)
    continue
  }

  $text = ($output | Out-String)
  if ($text -notmatch 'Behavior Atlas validation FAILED') {
    $failures += ("Negative fixture failed outside validator reporting: {0}`n{1}" -f $fixture.FullName, $text.Trim())
    continue
  }

  Write-Host ("Rejected as expected: {0}" -f $fixture.Name) -ForegroundColor Green
}

if ($failures.Count -gt 0) {
  Write-Host "Behavior Atlas negative fixture guard FAILED" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host (" - {0}" -f $failure) -ForegroundColor Red
  }
  exit 1
}

Write-Host ("Behavior Atlas negative fixture guard OK ({0} fixture(s))" -f $fixtures.Count) -ForegroundColor Green
exit 0
