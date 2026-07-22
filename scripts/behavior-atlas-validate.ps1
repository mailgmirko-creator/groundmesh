param(
  [string]$SchemaPath = "docs/behavior-atlas/schema/v0.1.schema.json",
  [string]$DataPath = "docs/behavior-atlas/examples/synthetic-case.json",
  [switch]$RequireSynthetic
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-RepoPath {
  param([string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  return Join-Path $RepoRoot $Path
}

$script:ValidationErrors = @()

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
    'automatic_publication'
  )

  foreach ($property in $Node.PSObject.Properties) {
    $name = $property.Name.ToLowerInvariant()
    if ($forbidden -contains $name) {
      Add-ValidationError ("Forbidden public field at {0}.{1}" -f $Path, $property.Name)
    }
    Test-ForbiddenProperties -Node $property.Value -Path ("{0}.{1}" -f $Path, $property.Name)
  }
}

function New-IdIndex {
  param(
    [object[]]$Items,
    [string]$IdProperty,
    [string]$CollectionName
  )

  $index = @{}
  foreach ($item in @($Items)) {
    $id = Get-PropertyValue -Object $item -Name $IdProperty
    if ([string]::IsNullOrWhiteSpace([string]$id)) {
      Add-ValidationError ("{0} contains a record without {1}." -f $CollectionName, $IdProperty)
      continue
    }
    if ($index.ContainsKey([string]$id)) {
      Add-ValidationError ("Duplicate {0} '{1}' in {2}." -f $IdProperty, $id, $CollectionName)
      continue
    }
    $index[[string]$id] = $item
  }
  return $index
}

function Test-Reference {
  param(
    [hashtable]$Index,
    [string]$Id,
    [string]$Context
  )
  if ([string]::IsNullOrWhiteSpace($Id) -or -not $Index.ContainsKey($Id)) {
    Add-ValidationError ("Broken reference '{0}' at {1}." -f $Id, $Context)
  }
}

function Test-DateValue {
  param(
    [object]$Value,
    [string]$Context,
    [switch]$AllowNull
  )
  if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
    if (-not $AllowNull) { Add-ValidationError ("Missing date value at {0}." -f $Context) }
    return
  }
  $parsed = [DateTimeOffset]::MinValue
  if (-not [DateTimeOffset]::TryParse([string]$Value, [ref]$parsed)) {
    Add-ValidationError ("Invalid date or date-time '{0}' at {1}." -f $Value, $Context)
  }
}

$schemaAbs = Resolve-RepoPath -Path $SchemaPath
$dataAbs = Resolve-RepoPath -Path $DataPath

if (-not (Test-Path $schemaAbs)) { throw "Schema not found: $schemaAbs" }
if (-not (Test-Path $dataAbs)) { throw "Data file not found: $dataAbs" }

try {
  $schema = Get-Content $schemaAbs -Raw | ConvertFrom-Json
} catch {
  throw "Schema JSON is invalid: $($_.Exception.Message)"
}

try {
  $data = Get-Content $dataAbs -Raw | ConvertFrom-Json
} catch {
  throw "Data JSON is invalid: $($_.Exception.Message)"
}

$schemaDraft = Get-PropertyValue -Object $schema -Name '$schema'
if ($schemaDraft -ne 'https://json-schema.org/draft/2020-12/schema') {
  Add-ValidationError "Schema must declare JSON Schema Draft 2020-12."
}

if ((Get-PropertyValue -Object $data -Name 'schema_version') -ne '0.1') {
  Add-ValidationError "Data schema_version must be '0.1'."
}

$requiredCollections = @(
  'subjects',
  'sources',
  'evidence_items',
  'claims',
  'assessments',
  'review_events',
  'correction_requests'
)
foreach ($name in $requiredCollections) {
  if ($null -eq $data.PSObject.Properties[$name]) {
    Add-ValidationError ("Missing root collection '{0}'." -f $name)
  }
}

Test-ForbiddenProperties -Node $data

$subjects = @((Get-PropertyValue -Object $data -Name 'subjects'))
$sources = @((Get-PropertyValue -Object $data -Name 'sources'))
$evidenceItems = @((Get-PropertyValue -Object $data -Name 'evidence_items'))
$claims = @((Get-PropertyValue -Object $data -Name 'claims'))
$assessments = @((Get-PropertyValue -Object $data -Name 'assessments'))
$reviewEvents = @((Get-PropertyValue -Object $data -Name 'review_events'))
$corrections = @((Get-PropertyValue -Object $data -Name 'correction_requests'))

$subjectIndex = New-IdIndex -Items $subjects -IdProperty 'subject_id' -CollectionName 'subjects'
$sourceIndex = New-IdIndex -Items $sources -IdProperty 'source_id' -CollectionName 'sources'
$evidenceIndex = New-IdIndex -Items $evidenceItems -IdProperty 'evidence_id' -CollectionName 'evidence_items'
$claimIndex = New-IdIndex -Items $claims -IdProperty 'claim_id' -CollectionName 'claims'
$assessmentIndex = New-IdIndex -Items $assessments -IdProperty 'assessment_id' -CollectionName 'assessments'
$reviewIndex = New-IdIndex -Items $reviewEvents -IdProperty 'review_event_id' -CollectionName 'review_events'
$correctionIndex = New-IdIndex -Items $corrections -IdProperty 'correction_id' -CollectionName 'correction_requests'

$allRecords = @{}
$caseId = [string](Get-PropertyValue -Object $data.case -Name 'case_id')
if ([string]::IsNullOrWhiteSpace($caseId)) {
  Add-ValidationError "case.case_id is required."
} else {
  $allRecords[$caseId] = $data.case
}

foreach ($index in @($subjectIndex, $sourceIndex, $evidenceIndex, $claimIndex, $assessmentIndex, $reviewIndex, $correctionIndex)) {
  foreach ($id in $index.Keys) {
    if ($allRecords.ContainsKey($id)) {
      Add-ValidationError ("Record id '{0}' is duplicated across collections." -f $id)
    } else {
      $allRecords[$id] = $index[$id]
    }
  }
}

$allowedSubjectTypes = @('project', 'institution', 'public_program', 'policy', 'contract', 'event')
foreach ($subject in $subjects) {
  $subjectType = [string](Get-PropertyValue -Object $subject -Name 'subject_type')
  if ($allowedSubjectTypes -notcontains $subjectType) {
    Add-ValidationError ("Subject '{0}' has forbidden or unknown type '{1}'." -f $subject.subject_id, $subjectType)
  }
}

foreach ($subjectId in @($data.case.subject_ids)) {
  Test-Reference -Index $subjectIndex -Id ([string]$subjectId) -Context 'case.subject_ids'
}

if ($RequireSynthetic) {
  if (-not [bool](Get-PropertyValue -Object $data.case -Name 'is_synthetic')) {
    Add-ValidationError "-RequireSynthetic requires case.is_synthetic = true."
  }
  if (@('draft', 'internal_review') -notcontains [string]$data.case.status) {
    Add-ValidationError "Synthetic M1 fixtures must stay in draft or internal_review status."
  }
  if ([bool]$data.case.release.public_release) {
    Add-ValidationError "Synthetic M1 fixtures must set release.public_release = false."
  }
}

if (@('unlisted_preview', 'public_alpha', 'contested') -contains [string]$data.case.status) {
  if ([string]::IsNullOrWhiteSpace([string]$data.case.correction_path)) {
    Add-ValidationError "Preview, public, or contested cases require case.correction_path."
  }
}

Test-DateValue -Value $data.case.release.created_at -Context 'case.release.created_at'

foreach ($source in $sources) {
  if (@('A', 'B', 'C', 'D') -notcontains [string]$source.source_class) {
    Add-ValidationError ("Source '{0}' has unknown class '{1}'." -f $source.source_id, $source.source_class)
  }
  if ([string]$source.content_hash -notmatch '^sha256:[a-f0-9]{64}$') {
    Add-ValidationError ("Source '{0}' has an invalid content_hash." -f $source.source_id)
  }
  Test-DateValue -Value $source.accessed_at -Context ("sources[{0}].accessed_at" -f $source.source_id)
}

foreach ($evidence in $evidenceItems) {
  Test-Reference -Index $sourceIndex -Id ([string]$evidence.source_id) -Context ("evidence_items[{0}].source_id" -f $evidence.evidence_id)
  Test-DateValue -Value $evidence.captured_at -Context ("evidence_items[{0}].captured_at" -f $evidence.evidence_id)
}

$reviewedStates = @('reviewed', 'publishable', 'contested', 'corrected', 'retired')
$sourcedStates = @('sourced', 'reviewed', 'publishable', 'contested', 'corrected', 'retired')

foreach ($claim in $claims) {
  foreach ($subjectId in @($claim.subject_ids)) {
    Test-Reference -Index $subjectIndex -Id ([string]$subjectId) -Context ("claims[{0}].subject_ids" -f $claim.claim_id)
  }

  $hasEvidence = $false
  foreach ($link in @($claim.evidence_links)) {
    $evidenceId = [string]$link.evidence_id
    Test-Reference -Index $evidenceIndex -Id $evidenceId -Context ("claims[{0}].evidence_links" -f $claim.claim_id)
    if (@('supports', 'contradicts') -contains [string]$link.relationship) { $hasEvidence = $true }

    if ([string]$claim.state -eq 'publishable' -and $evidenceIndex.ContainsKey($evidenceId)) {
      $evidence = $evidenceIndex[$evidenceId]
      if (-not [bool]$evidence.public_safe) {
        Add-ValidationError ("Publishable claim '{0}' references evidence not marked public_safe." -f $claim.claim_id)
      }
      $sourceId = [string]$evidence.source_id
      if ($sourceIndex.ContainsKey($sourceId) -and [string]$sourceIndex[$sourceId].source_class -eq 'D') {
        Add-ValidationError ("Publishable claim '{0}' relies on class D lead material." -f $claim.claim_id)
      }
    }
  }

  if ($sourcedStates -contains [string]$claim.state -and -not $hasEvidence) {
    Add-ValidationError ("Claim '{0}' is {1} but has no supporting or contradicting evidence link." -f $claim.claim_id, $claim.state)
  }
  if ($reviewedStates -contains [string]$claim.state) {
    if (@($claim.reviewer_refs).Count -lt 1) {
      Add-ValidationError ("Reviewed claim '{0}' has no reviewer_refs." -f $claim.claim_id)
    }
    Test-DateValue -Value $claim.review_due -Context ("claims[{0}].review_due" -f $claim.claim_id)
  }
  if ($null -ne $claim.supersedes_claim_id) {
    Test-Reference -Index $claimIndex -Id ([string]$claim.supersedes_claim_id) -Context ("claims[{0}].supersedes_claim_id" -f $claim.claim_id)
  }
}

foreach ($assessment in $assessments) {
  $supporting = @($assessment.supporting_claim_ids)
  $counter = @($assessment.counter_claim_ids)
  foreach ($claimId in $supporting) {
    Test-Reference -Index $claimIndex -Id ([string]$claimId) -Context ("assessments[{0}].supporting_claim_ids" -f $assessment.assessment_id)
    if ($counter -contains $claimId) {
      Add-ValidationError ("Assessment '{0}' uses claim '{1}' as both support and counterevidence." -f $assessment.assessment_id, $claimId)
    }
  }
  foreach ($claimId in $counter) {
    Test-Reference -Index $claimIndex -Id ([string]$claimId) -Context ("assessments[{0}].counter_claim_ids" -f $assessment.assessment_id)
  }
  if ([string]$assessment.confidence -eq 'substantiated' -and $supporting.Count -lt 2) {
    Add-ValidationError ("Substantiated assessment '{0}' requires at least two supporting claims." -f $assessment.assessment_id)
  }
  if ([string]$assessment.direction -eq 'mixed' -and $counter.Count -lt 1) {
    Add-ValidationError ("Mixed assessment '{0}' requires at least one counter claim." -f $assessment.assessment_id)
  }
  Test-DateValue -Value $assessment.assessed_at -Context ("assessments[{0}].assessed_at" -f $assessment.assessment_id)
  Test-DateValue -Value $assessment.review_due -Context ("assessments[{0}].review_due" -f $assessment.assessment_id)
}

foreach ($event in $reviewEvents) {
  Test-Reference -Index $allRecords -Id ([string]$event.target_id) -Context ("review_events[{0}].target_id" -f $event.review_event_id)
  Test-DateValue -Value $event.timestamp -Context ("review_events[{0}].timestamp" -f $event.review_event_id)
  if ($null -ne $event.supersedes_record_id) {
    Test-Reference -Index $allRecords -Id ([string]$event.supersedes_record_id) -Context ("review_events[{0}].supersedes_record_id" -f $event.review_event_id)
  }
}

foreach ($correction in $corrections) {
  Test-Reference -Index $allRecords -Id ([string]$correction.target_id) -Context ("correction_requests[{0}].target_id" -f $correction.correction_id)
  Test-DateValue -Value $correction.received_at -Context ("correction_requests[{0}].received_at" -f $correction.correction_id)
  if (@('accepted', 'partially_accepted', 'rejected') -contains [string]$correction.status) {
    Test-DateValue -Value $correction.resolved_at -Context ("correction_requests[{0}].resolved_at" -f $correction.correction_id)
    if ([string]::IsNullOrWhiteSpace([string]$correction.resolution_note)) {
      Add-ValidationError ("Resolved correction '{0}' requires resolution_note." -f $correction.correction_id)
    }
  }
}

if ($script:ValidationErrors.Count -gt 0) {
  Write-Host "Behavior Atlas validation FAILED" -ForegroundColor Red
  foreach ($message in $script:ValidationErrors) {
    Write-Host (" - {0}" -f $message) -ForegroundColor Red
  }
  exit 1
}

Write-Host "Behavior Atlas validation OK" -ForegroundColor Green
Write-Host ("Schema: {0}" -f $SchemaPath)
Write-Host ("Data:   {0}" -f $DataPath)
Write-Host ("Counts: {0} subject(s), {1} source(s), {2} evidence item(s), {3} claim(s), {4} assessment(s), {5} review event(s), {6} correction request(s)" -f `
  $subjects.Count,
  $sources.Count,
  $evidenceItems.Count,
  $claims.Count,
  $assessments.Count,
  $reviewEvents.Count,
  $corrections.Count)
exit 0
