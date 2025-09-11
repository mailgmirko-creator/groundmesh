param(
  [string]$JobFile = "apps/tsl/jobs/learn_principles.json"
)

if (-not (Test-Path $JobFile)) {
  Write-Host "Job file not found: $JobFile"
  exit 1
}

try {
  $job = Get-Content $JobFile -Raw | ConvertFrom-Json
} catch {
  Write-Host "Failed to parse job JSON: $JobFile"
  exit 1
}

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
  Write-Host "Python not found on PATH. Install Python 3.8+."
  exit 1
}

$inYaml  = $job.inputs.principles_yaml
$outDir  = $job.outputs.artifact_dir
$model   = Join-Path $outDir ($job.outputs.model_file)

# Ensure output directory exists
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Run the learner
& python "apps/tsl/tsl_core/learner.py" $inYaml $outDir
if ($LASTEXITCODE -ne 0) {
  Write-Host "Learner failed with exit code $LASTEXITCODE."
  exit $LASTEXITCODE
}

# Simple verification
if (Test-Path $model) {
  $size = (Get-Item $model).Length
  Write-Host "Model written: $model ($size bytes)"
} else {
  Write-Host "Model file not found after run: $model"
}

