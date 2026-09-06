$RepoRoot = Split-Path -Parent $PSScriptRoot
python (Join-Path $RepoRoot "balance_engine\tsl_loop.py")
