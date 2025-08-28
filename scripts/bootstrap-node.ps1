Write-Host "=== GroundMesh Bootstrap ===" -ForegroundColor Cyan
function Check($label,$cmd){ try{$r=Invoke-Expression $cmd;Write-Host "[OK]  $label -> $r" -ForegroundColor Green}catch{Write-Host "[X]   $label -> $($_.Exception.Message)" -ForegroundColor Red} }
Check "Git version" "git --version"
Check "Python version" "python --version"
Check "Network to GitHub (443)" "($r=Test-NetConnection github.com -Port 443).TcpTestSucceeded"
Check "README exists" "Test-Path .\README.md"
Check "Constitution PDF" "Test-Path .\constitution\AI_Freedom_Constitution.pdf"
Check "Checklist MD" "Test-Path .\checklists\Commons_First_Moves_Checklist.md"
Write-Host "`nBootstrap checks complete." -ForegroundColor Cyan
