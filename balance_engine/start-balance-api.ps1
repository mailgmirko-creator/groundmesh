Set-Location "C:\Projects\GroundMesh-DEV\balance_engine"
.\.venv\Scripts\Activate.ps1
$env:PYTHONPATH = "$PWD"
python -m api.service
