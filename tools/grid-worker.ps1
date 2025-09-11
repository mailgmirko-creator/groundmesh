param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$InboxRel     = "grid\inbox",
  [string]$OutboxRel    = "grid\outbox",
  [string]$ProcessedRel = "grid\processed",
  [string]$FailedRel    = "grid\failed"
)
$ErrorActionPreference = "Stop"

$Inbox     = Join-Path $RepoRoot $InboxRel
$Outbox    = Join-Path $RepoRoot $OutboxRel
$Processed = Join-Path $RepoRoot $ProcessedRel
$Failed    = Join-Path $RepoRoot $FailedRel

# Ensure dirs exist
$null = New-Item -ItemType Directory -Force -Path $Inbox,$Outbox,$Processed,$Failed

function Write-ResultJson { param([string]$Path,[hashtable]$Obj)
  $json = $Obj | ConvertTo-Json -Depth 8
  [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

$jobFile = Get-ChildItem $Inbox -Filter *.json -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
if (-not $jobFile) { Write-Host "No jobs in $Inbox"; exit 0 }

Write-Host ("Picked job: {0}" -f $jobFile.Name)

try { $job = Get-Content $jobFile.FullName -Raw | ConvertFrom-Json }
catch {
  Write-Host ("Invalid job JSON: {0}" -f $jobFile.Name)
  Move-Item $jobFile.FullName (Join-Path $Failed $jobFile.Name) -Force
  exit 1
}

$jobType = $job.job_type
$started = Get-Date

switch ($jobType) {
  'tsl_principles_learn' {
    $inYaml  = Join-Path $RepoRoot $job.inputs.principles_yaml
    $outDir  = Join-Path $RepoRoot $job.outputs.artifact_dir
    $model   = Join-Path $outDir ($job.outputs.model_file)

    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { throw "Python not found on PATH." }

    & python (Join-Path $RepoRoot "apps\tsl\tsl_core\learner.py") $inYaml $outDir
    if ($LASTEXITCODE -ne 0) { throw "Learner failed with exit code $LASTEXITCODE." }
    if (-not (Test-Path $model)) { throw "Model file missing after run: $model" }

    $size = (Get-Item $model).Length
    $res  = @{
      job_type = $jobType
      started  = $started.ToString("s")
      finished = (Get-Date).ToString("s")
      status   = "success"
      outputs  = @{ model_file = $model; size_bytes = $size }
    }
    $outFile = Join-Path $Outbox ("result_" + [IO.Path]::GetFileNameWithoutExtension($jobFile.Name) + ".json")
    Write-ResultJson -Path $outFile -Obj $res
    Move-Item $jobFile.FullName (Join-Path $Processed $jobFile.Name) -Force
    Write-Host ("Job OK -> {0}" -f $outFile)
  }
  default {
    $res = @{
      job_type = $jobType
      started  = $started.ToString("s")
      finished = (Get-Date).ToString("s")
      status   = "unsupported_job_type"
    }
    $outFile = Join-Path $Outbox ("result_" + [IO.Path]::GetFileNameWithoutExtension($jobFile.Name) + ".json")
    Write-ResultJson -Path $outFile -Obj $res
    Move-Item $jobFile.FullName (Join-Path $Failed $jobFile.Name) -Force
    Write-Host ("Unsupported job type: {0}" -f $jobType)
  }
}
