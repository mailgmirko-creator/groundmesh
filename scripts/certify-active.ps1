param(
  [switch]$AllowNonMain,
  [switch]$AllowMissingInstalledHook,
  [switch]$SkipWorkingTreeClean,
  [switch]$SkipRemoteHeadMatch,
  [switch]$SkipLiveRemote,
  [switch]$SkipHealth,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (& git rev-parse --show-toplevel).Trim()
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  throw "Could not resolve repository root."
}

$errors = New-Object System.Collections.Generic.List[string]
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
  param(
    [string]$Name,
    [bool]$Ok,
    [string]$Detail
  )

  $checks.Add([pscustomobject]@{
    name = $Name
    ok = $Ok
    detail = $Detail
  })

  if (-not $Ok) {
    $errors.Add("${Name}: $Detail")
  }
}

function Invoke-GitText {
  param([string[]]$Arguments)

  $output = @(& git -C $RepoRoot @Arguments 2>&1)
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
  }
  return (($output | Out-String).Trim())
}

function Invoke-Guard {
  param(
    [string]$Name,
    [string]$RelativePath,
    [scriptblock]$Command
  )

  $abs = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
    Add-Check $Name $false "missing $RelativePath"
    return
  }

  try {
    $script:LASTEXITCODE = 0
    $output = @(& $Command 2>&1)
    if ($LASTEXITCODE -ne 0) {
      Add-Check $Name $false (($output | Out-String).Trim())
      return
    }
    $detail = (($output | Select-Object -Last 2) | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($detail)) { $detail = "OK" }
    Add-Check $Name $true $detail
  }
  catch {
    Add-Check $Name $false $_.Exception.Message
  }
}

function Test-JsonFile {
  param(
    [string]$Name,
    [string]$RelativePath
  )

  $abs = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
    Add-Check $Name $false "missing $RelativePath"
    return $null
  }

  try {
    $json = Get-Content -LiteralPath $abs -Raw | ConvertFrom-Json -Depth 100
    Add-Check $Name $true "$RelativePath parses"
    return $json
  }
  catch {
    Add-Check $Name $false "$RelativePath is invalid JSON: $($_.Exception.Message)"
    return $null
  }
}

$branch = Invoke-GitText -Arguments @("branch", "--show-current")
if ([string]::IsNullOrWhiteSpace($branch)) {
  Add-Check "branch" $AllowNonMain "detached HEAD; allowed only for CI/smoke tests"
}
elseif ($branch -eq "main" -or $AllowNonMain) {
  Add-Check "branch" $true "current branch: $branch"
}
else {
  Add-Check "branch" $false "expected main, found $branch"
}

if (-not $SkipWorkingTreeClean) {
  $statusLines = @(& git -C $RepoRoot status --porcelain=v1 2>&1)
  if ($LASTEXITCODE -ne 0) {
    Add-Check "working tree" $false "git status failed: $($statusLines -join [Environment]::NewLine)"
  }
  elseif ($statusLines.Count -eq 0) {
    Add-Check "working tree" $true "clean"
  }
  else {
    $preview = ($statusLines | Select-Object -First 20) -join "; "
    Add-Check "working tree" $false "$($statusLines.Count) changed/untracked path(s): $preview"
  }
}
else {
  Add-Check "working tree" $true "clean check skipped by caller"
}

$head = $null
$originMain = $null
try {
  $head = Invoke-GitText -Arguments @("rev-parse", "HEAD")
  Add-Check "local HEAD" $true $head
}
catch {
  Add-Check "local HEAD" $false $_.Exception.Message
}

try {
  $originMain = Invoke-GitText -Arguments @("rev-parse", "--verify", "origin/main")
  Add-Check "origin/main" $true $originMain
}
catch {
  Add-Check "origin/main" $false $_.Exception.Message
}

if ($head -and $originMain) {
  if ($SkipRemoteHeadMatch -or $head -eq $originMain) {
    $detail = if ($SkipRemoteHeadMatch) { "match skipped by caller" } else { "HEAD matches origin/main" }
    Add-Check "local main parity" $true $detail
  }
  else {
    Add-Check "local main parity" $false "HEAD $head does not match origin/main $originMain"
  }
}

if (-not $SkipLiveRemote) {
  try {
    $remoteLine = Invoke-GitText -Arguments @("ls-remote", "origin", "refs/heads/main")
    $liveMain = (($remoteLine -split "\s+")[0]).Trim()
    if ([string]::IsNullOrWhiteSpace($liveMain)) {
      Add-Check "live remote main" $false "no refs/heads/main returned by ls-remote"
    }
    else {
      Add-Check "live remote main" $true $liveMain
      if ($originMain -and $originMain -ne $liveMain) {
        Add-Check "remote tracking parity" $false "origin/main $originMain does not match live main $liveMain; fetch before certifying"
      }
      else {
        Add-Check "remote tracking parity" $true "origin/main matches live main"
      }

      if ($head -and -not $SkipRemoteHeadMatch -and $head -ne $liveMain) {
        Add-Check "ACTIVE remote parity" $false "HEAD $head does not match live main $liveMain"
      }
      elseif ($head) {
        $detail = if ($SkipRemoteHeadMatch) { "match skipped by caller" } else { "HEAD matches live main" }
        Add-Check "ACTIVE remote parity" $true $detail
      }
    }
  }
  catch {
    Add-Check "live remote main" $false $_.Exception.Message
  }
}
else {
  Add-Check "live remote main" $true "live remote check skipped by caller"
}

$installHooksScript = Join-Path $RepoRoot "scripts/install-git-hooks.ps1"
Invoke-Guard -Name "tracked pre-push hook" -RelativePath "scripts/install-git-hooks.ps1" -Command {
  & $installHooksScript -CheckOnly
}

$hooksPath = (& git -C $RepoRoot config --get core.hooksPath 2>$null)
if ($null -eq $hooksPath) { $hooksPath = "" }
$hooksPath = ([string]$hooksPath).Trim()
$gitHookPath = Invoke-GitText -Arguments @("rev-parse", "--git-path", "hooks/pre-push")
$hasLocalMainHook = Test-Path -LiteralPath $gitHookPath -PathType Leaf

if ($hooksPath -eq ".githooks" -or $hasLocalMainHook -or $AllowMissingInstalledHook) {
  $detail = if ($hooksPath -eq ".githooks") {
    "core.hooksPath=.githooks"
  }
  elseif ($hasLocalMainHook) {
    "local hook present at $gitHookPath"
  }
  else {
    "installed hook check skipped by caller"
  }
  Add-Check "installed pre-push protection" $true $detail
}
else {
  Add-Check "installed pre-push protection" $false "core.hooksPath is '$hooksPath' and no local pre-push hook is installed"
}

$registry = Test-JsonFile "Atlas registry JSON" "docs/atlas/registry.json"
if ($null -ne $registry) {
  $entries = @($registry.entries)
  $certEntry = @($entries | Where-Object { $_.id -eq "SCRIPT-CERTIFY-ACTIVE" })
  if ($certEntry.Count -eq 1) {
    Add-Check "Atlas certification entry" $true "SCRIPT-CERTIFY-ACTIVE registered"
  }
  else {
    Add-Check "Atlas certification entry" $false "SCRIPT-CERTIFY-ACTIVE must be registered in docs/atlas/registry.json"
  }
}

$status = Test-JsonFile "public status JSON" "docs/data/status.json"
if ($null -ne $status) {
  $components = $status.PSObject.Properties["components"]
  if ($null -eq $components) {
    Add-Check "public status components" $false "docs/data/status.json has no components object"
  }
  else {
    Add-Check "public status components" $true "components object present"
  }
}

$stewardScript = Join-Path $RepoRoot "scripts/groundmesh-steward.ps1"
Invoke-Guard -Name "GroundMesh steward loop" -RelativePath "scripts/groundmesh-steward.ps1" -Command {
  & $stewardScript -CheckOnly -Quiet
}

$needsOffersScript = Join-Path $RepoRoot "scripts/needs-offers-readiness-guard.ps1"
Invoke-Guard -Name "needs/offers readiness" -RelativePath "scripts/needs-offers-readiness-guard.ps1" -Command {
  & $needsOffersScript
}

$moneyValueScript = Join-Path $RepoRoot "scripts/money-value-readiness-guard.ps1"
Invoke-Guard -Name "money/value readiness" -RelativePath "scripts/money-value-readiness-guard.ps1" -Command {
  & $moneyValueScript
}

$balanceBoundaryScript = Join-Path $RepoRoot "scripts/balance-engine-boundary-guard.ps1"
Invoke-Guard -Name "Balance Engine boundary" -RelativePath "scripts/balance-engine-boundary-guard.ps1" -Command {
  & $balanceBoundaryScript -Quiet
}

if (-not $SkipHealth) {
  $healthScript = Join-Path $RepoRoot "scripts/health-check.ps1"
  Invoke-Guard -Name "public health check" -RelativePath "scripts/health-check.ps1" -Command {
    & $healthScript
  }
}
else {
  Add-Check "public health check" $true "health check skipped by caller"
}

if (-not $Quiet) {
  Write-Host ""
  Write-Host "== ACTIVE CERTIFICATION =="
  foreach ($check in $checks) {
    $mark = if ($check.ok) { "OK " } else { "BAD" }
    Write-Host ("{0}  {1} - {2}" -f $mark, $check.name, $check.detail)
  }
}

if ($errors.Count -gt 0) {
  throw (($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine)
}

if (-not $Quiet) {
  Write-Host ""
  Write-Host "GroundMesh ACTIVE certification OK"
}
