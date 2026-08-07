param(
  [string]$ModelPath = "docs/coordination/coordination-field.v0.1.json",
  [string]$FixturePath = "docs/coordination/examples/synthetic-need-capacity-cycle.v0.1.json"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$script:ValidationErrors = @()

function Resolve-RepoPath {
  param([string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  return Join-Path $RepoRoot $Path
}

function Add-ValidationError {
  param([string]$Message)
  $script:ValidationErrors += $Message
}

function Get-PropertyValue {
  param(
    [object]$Object,
    [string]$Name
  )
  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { return $null }
  return $property.Value
}

function Test-ForbiddenProperties {
  param(
    [object]$Node,
    [string]$Path = '$'
  )

  if ($null -eq $Node -or $Node -is [string] -or $Node.GetType().IsValueType) { return }

  if ($Node -is [System.Collections.IEnumerable] -and
      $Node -isnot [System.Collections.IDictionary] -and
      $Node -isnot [System.Management.Automation.PSCustomObject]) {
    $index = 0
    foreach ($item in $Node) {
      Test-ForbiddenProperties -Node $item -Path ("{0}[{1}]" -f $Path, $index)
      $index++
    }
    return
  }

  $forbidden = @(
    'score',
    'rank',
    'ranking',
    'person_score',
    'reputation_score',
    'moral_label',
    'guilt_finding',
    'inferred_motive',
    'composite_score',
    'automatic_allocation',
    'allocation_order'
  )

  foreach ($property in $Node.PSObject.Properties) {
    $name = $property.Name.ToLowerInvariant()
    if ($forbidden -contains $name) {
      Add-ValidationError ("Forbidden field at {0}.{1}" -f $Path, $property.Name)
    }
    Test-ForbiddenProperties -Node $property.Value -Path ("{0}.{1}" -f $Path, $property.Name)
  }
}

function Assert-NumberEqual {
  param(
    [double]$Actual,
    [double]$Expected,
    [string]$Context
  )
  if ([Math]::Abs($Actual - $Expected) -gt 0.0000001) {
    Add-ValidationError ("{0}: expected {1}, got {2}." -f $Context, $Expected, $Actual)
  }
}

function Assert-StringEqual {
  param(
    [string]$Actual,
    [string]$Expected,
    [string]$Context
  )
  if ($Actual -ne $Expected) {
    Add-ValidationError ("{0}: expected '{1}', got '{2}'." -f $Context, $Expected, $Actual)
  }
}

function Test-NeedState {
  param([object]$State)

  $n = [double]$State.need.N
  $d = [double]$State.need.D
  $k = [double]$State.need.K_outstanding
  $u = [double]$State.need.U
  $g = [double]$State.need.G

  foreach ($pair in @(
    @('N', $n),
    @('D', $d),
    @('K_outstanding', $k),
    @('U', $u),
    @('G', $g)
  )) {
    if ([double]$pair[1] -lt 0) {
      Add-ValidationError ("State '{0}' need.{1} must be non-negative." -f $State.state_id, $pair[0])
    }
  }

  if ($d -gt $n) {
    Add-ValidationError ("State '{0}' delivery exceeds assessed need." -f $State.state_id)
  }
  if ($k -gt [Math]::Max(0, $n - $d)) {
    Add-ValidationError ("State '{0}' outstanding need-side commitments exceed the remaining need boundary." -f $State.state_id)
  }

  Assert-NumberEqual -Actual $u -Expected ([Math]::Max(0, $n - $d)) -Context ("{0}.need.U" -f $State.state_id)
  Assert-NumberEqual -Actual $g -Expected ([Math]::Max(0, $n - $d - $k)) -Context ("{0}.need.G" -f $State.state_id)
}

function Test-CapacityState {
  param([object]$State)

  $c = [double]$State.capacity.C_remaining
  $k = [double]$State.capacity.K_outstanding
  $s = [double]$State.capacity.S

  foreach ($pair in @(
    @('C_remaining', $c),
    @('K_outstanding', $k),
    @('S', $s)
  )) {
    if ([double]$pair[1] -lt 0) {
      Add-ValidationError ("State '{0}' capacity.{1} must be non-negative." -f $State.state_id, $pair[0])
    }
  }

  if ($k -gt $c) {
    Add-ValidationError ("State '{0}' outstanding capacity commitments exceed remaining capacity." -f $State.state_id)
  }

  Assert-NumberEqual -Actual $s -Expected ([Math]::Max(0, $c - $k)) -Context ("{0}.capacity.S" -f $State.state_id)
}

function Get-StateById {
  param(
    [object[]]$States,
    [string]$Id
  )
  $matches = @($States | Where-Object { [string]$_.state_id -eq $Id })
  if ($matches.Count -ne 1) {
    Add-ValidationError ("Expected exactly one state '{0}', found {1}." -f $Id, $matches.Count)
    return $null
  }
  return $matches[0]
}

$modelAbs = Resolve-RepoPath -Path $ModelPath
$fixtureAbs = Resolve-RepoPath -Path $FixturePath

if (-not (Test-Path $modelAbs)) { throw "Coordination model not found: $modelAbs" }
if (-not (Test-Path $fixtureAbs)) { throw "Coordination fixture not found: $fixtureAbs" }

try {
  $model = Get-Content $modelAbs -Raw | ConvertFrom-Json
} catch {
  throw "Coordination model JSON is invalid: $($_.Exception.Message)"
}

try {
  $fixture = Get-Content $fixtureAbs -Raw | ConvertFrom-Json
} catch {
  throw "Coordination fixture JSON is invalid: $($_.Exception.Message)"
}

Assert-StringEqual -Actual ([string]$model.version) -Expected '0.1' -Context 'model.version'
Assert-StringEqual -Actual ([string]$model.quantities.U.formula) -Expected 'max(0, N - D)' -Context 'model.quantities.U.formula'
Assert-StringEqual -Actual ([string]$model.quantities.G.formula) -Expected 'max(0, N - D - K_valid)' -Context 'model.quantities.G.formula'
Assert-StringEqual -Actual ([string]$model.quantities.S.formula) -Expected 'max(0, C - K)' -Context 'model.quantities.S.formula'

Assert-StringEqual -Actual ([string]$fixture.version) -Expected '0.1' -Context 'fixture.version'
if (-not [bool]$fixture.is_synthetic) { Add-ValidationError 'Fixture must set is_synthetic = true.' }
if ([bool]$fixture.public_release) { Add-ValidationError 'Synthetic fixture must set public_release = false.' }

Test-ForbiddenProperties -Node $fixture

if (-not [bool]$fixture.authority.proposal_only) { Add-ValidationError 'Fixture must remain proposal-only.' }
if ([bool]$fixture.authority.allocation_authority) { Add-ValidationError 'Fixture must not grant allocation authority.' }
if ([bool]$fixture.authority.autonomous_commitment) { Add-ValidationError 'Fixture must not permit autonomous commitment.' }
if (-not [bool]$fixture.authority.consent_required) { Add-ValidationError 'Fixture must require consent.' }

$participants = @($fixture.participants)
if ($participants.Count -lt 2) { Add-ValidationError 'Fixture requires at least two fictional participants.' }
$participantIds = @{}
foreach ($participant in $participants) {
  $id = [string]$participant.participant_id
  if ([string]::IsNullOrWhiteSpace($id)) {
    Add-ValidationError 'Participant is missing participant_id.'
  } elseif ($participantIds.ContainsKey($id)) {
    Add-ValidationError ("Duplicate participant_id '{0}'." -f $id)
  } else {
    $participantIds[$id] = $true
  }

  if (-not [bool]$participant.fictional) {
    Add-ValidationError ("Participant '{0}' must be explicitly fictional." -f $id)
  }
  if ([bool]$participant.is_person -or [string]$participant.participant_type -eq 'person') {
    Add-ValidationError ("Participant '{0}' may not be a person in this synthetic fixture." -f $id)
  }
}

foreach ($required in @('resource_id', 'class', 'unit', 'quality_threshold', 'geography', 'scope')) {
  $value = Get-PropertyValue -Object $fixture.resource -Name $required
  if ([string]::IsNullOrWhiteSpace([string]$value)) {
    Add-ValidationError ("resource.{0} is required." -f $required)
  }
}

$start = [DateTimeOffset]::MinValue
$end = [DateTimeOffset]::MinValue
if (-not [DateTimeOffset]::TryParse([string]$fixture.resource.time_window.start, [ref]$start)) {
  Add-ValidationError 'resource.time_window.start is not a valid date-time.'
}
if (-not [DateTimeOffset]::TryParse([string]$fixture.resource.time_window.end, [ref]$end)) {
  Add-ValidationError 'resource.time_window.end is not a valid date-time.'
}
if ($end -le $start) { Add-ValidationError 'resource.time_window.end must be after start.' }

foreach ($semantic in @('N', 'D', 'K_outstanding', 'C_remaining', 'U_formula', 'G_formula', 'S_formula')) {
  $value = Get-PropertyValue -Object $fixture.semantics -Name $semantic
  if ([string]::IsNullOrWhiteSpace([string]$value)) {
    Add-ValidationError ("semantics.{0} is required." -f $semantic)
  }
}

$states = @($fixture.states)
if ($states.Count -ne 4) { Add-ValidationError ("Expected four test states, found {0}." -f $states.Count) }

$stateIds = @{}
foreach ($state in $states) {
  $id = [string]$state.state_id
  if ([string]::IsNullOrWhiteSpace($id)) {
    Add-ValidationError 'State is missing state_id.'
  } elseif ($stateIds.ContainsKey($id)) {
    Add-ValidationError ("Duplicate state_id '{0}'." -f $id)
  } else {
    $stateIds[$id] = $true
  }
  Test-NeedState -State $state
  Test-CapacityState -State $state
}

$s0 = Get-StateById -States $states -Id 'S0-observed'
$s1 = Get-StateById -States $states -Id 'S1-proposed'
$s2 = Get-StateById -States $states -Id 'S2-committed'
$s3 = Get-StateById -States $states -Id 'S3-partial-delivery'

if ($null -ne $s0 -and $null -ne $s1 -and $null -ne $s2 -and $null -ne $s3) {
  Assert-StringEqual -Actual ([string]$s0.stage) -Expected 'observed' -Context 'S0.stage'
  Assert-StringEqual -Actual ([string]$s1.stage) -Expected 'proposed' -Context 'S1.stage'
  Assert-StringEqual -Actual ([string]$s2.stage) -Expected 'committed' -Context 'S2.stage'
  Assert-StringEqual -Actual ([string]$s3.stage) -Expected 'partial_verified_delivery' -Context 'S3.stage'

  foreach ($name in @('N', 'D', 'K_outstanding', 'U', 'G')) {
    Assert-NumberEqual -Actual ([double](Get-PropertyValue -Object $s1.need -Name $name)) -Expected ([double](Get-PropertyValue -Object $s0.need -Name $name)) -Context ("pending proposal preserves need.{0}" -f $name)
  }
  foreach ($name in @('C_remaining', 'K_outstanding', 'S')) {
    Assert-NumberEqual -Actual ([double](Get-PropertyValue -Object $s1.capacity -Name $name)) -Expected ([double](Get-PropertyValue -Object $s0.capacity -Name $name)) -Context ("pending proposal preserves capacity.{0}" -f $name)
  }

  if ($null -eq $s1.proposal) {
    Add-ValidationError 'S1 must contain a proposal.'
  } else {
    $amount = [double]$s1.proposal.amount
    if ($amount -le 0) { Add-ValidationError 'S1 proposal amount must be positive.' }
    if ($amount -gt [double]$s0.need.G) { Add-ValidationError 'S1 proposal exceeds observed planned gap.' }
    if ($amount -gt [double]$s0.capacity.S) { Add-ValidationError 'S1 proposal exceeds observed spare capacity.' }
    Assert-StringEqual -Actual ([string]$s1.proposal.consent_state) -Expected 'pending' -Context 'S1.proposal.consent_state'
    if ([bool]$s1.proposal.binding) { Add-ValidationError 'Pending S1 proposal must not be binding.' }

    Assert-StringEqual -Actual ([string]$s2.proposal.consent_state) -Expected 'accepted' -Context 'S2.proposal.consent_state'
    if (-not [bool]$s2.proposal.binding) { Add-ValidationError 'Accepted S2 proposal must be binding in the synthetic state model.' }
    Assert-NumberEqual -Actual ([double]$s2.proposal.amount) -Expected $amount -Context 'S2.proposal.amount'

    Assert-NumberEqual -Actual ([double]$s2.need.N) -Expected ([double]$s1.need.N) -Context 'consent preserves need.N'
    Assert-NumberEqual -Actual ([double]$s2.need.D) -Expected ([double]$s1.need.D) -Context 'consent does not invent delivery'
    Assert-NumberEqual -Actual ([double]$s2.need.K_outstanding) -Expected ([double]$s1.need.K_outstanding + $amount) -Context 'consent adds need-side outstanding commitment'
    Assert-NumberEqual -Actual ([double]$s2.capacity.C_remaining) -Expected ([double]$s1.capacity.C_remaining) -Context 'consent does not consume capacity before delivery'
    Assert-NumberEqual -Actual ([double]$s2.capacity.K_outstanding) -Expected ([double]$s1.capacity.K_outstanding + $amount) -Context 'consent adds capacity-side outstanding commitment'

    $delivered = [double]$s3.transition_from_previous.delivered_amount
    if ($delivered -le 0) { Add-ValidationError 'S3 delivered_amount must be positive.' }
    if ($delivered -gt $amount) { Add-ValidationError 'S3 delivered_amount exceeds accepted proposal amount.' }

    Assert-NumberEqual -Actual ([double]$s3.need.N) -Expected ([double]$s2.need.N) -Context 'delivery preserves need.N'
    Assert-NumberEqual -Actual ([double]$s3.need.D) -Expected ([double]$s2.need.D + $delivered) -Context 'delivery increases need.D'
    Assert-NumberEqual -Actual ([double]$s3.need.K_outstanding) -Expected ([double]$s2.need.K_outstanding - $delivered) -Context 'delivery reduces need-side outstanding commitment'
    Assert-NumberEqual -Actual ([double]$s3.capacity.C_remaining) -Expected ([double]$s2.capacity.C_remaining - $delivered) -Context 'delivery consumes remaining capacity'
    Assert-NumberEqual -Actual ([double]$s3.capacity.K_outstanding) -Expected ([double]$s2.capacity.K_outstanding - $delivered) -Context 'delivery reduces capacity-side outstanding commitment'
    Assert-NumberEqual -Actual ([double]$s3.need.U) -Expected ([double]$s2.need.U - $delivered) -Context 'delivery reduces observed unmet need'
    Assert-NumberEqual -Actual ([double]$s3.need.G) -Expected ([double]$s2.need.G) -Context 'delivery of planned quantity preserves planned gap'
    Assert-NumberEqual -Actual ([double]$s3.capacity.S) -Expected ([double]$s2.capacity.S) -Context 'delivery of committed quantity preserves spare capacity'
    Assert-NumberEqual -Actual ([double]$s3.transition_from_previous.remaining_match_commitment) -Expected ($amount - $delivered) -Context 'remaining match commitment'
  }
}

if ($script:ValidationErrors.Count -gt 0) {
  Write-Host 'Coordination fixture validation failed:'
  foreach ($errorMessage in $script:ValidationErrors) {
    Write-Host ("- {0}" -f $errorMessage)
  }
  throw ("Coordination fixture validation failed with {0} error(s)." -f $script:ValidationErrors.Count)
}

Write-Host ("Coordination synthetic breathing test OK: {0} states validated." -f $states.Count)
