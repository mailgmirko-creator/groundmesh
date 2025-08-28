Write-Host "=== GroundMesh Bootstrap ===" -ForegroundColor Cyan

function OK($label,$value){ Write-Host ("[OK]  {0} -> {1}" -f $label,$value) -ForegroundColor Green }
function XX($label,$value){ Write-Host ("[X]   {0} -> {1}" -f $label,$value) -ForegroundColor Red }

# Git
try { $gv = git --version; OK "Git version" $gv } catch { XX "Git version" $_.Exception.Message }

# Python
try { $pv = python --version; OK "Python version" $pv } catch { XX "Python version" $_.Exception.Message }

# Network to GitHub (443)
try {
  $r = Test-NetConnection github.com -Port 443 -WarningAction SilentlyContinue
  if ($r -and $r.TcpTestSucceeded) { OK "Network to GitHub (443)" $r.TcpTestSucceeded }
  else { XX "Network to GitHub (443)" "False" }
} catch {
  XX "Network to GitHub (443)" "Test-NetConnection not available on this Windows"
}

# Files (accept MD or PDF)
if (Test-Path .\constitution\AI_Freedom_Constitution.pdf)      { OK "Constitution" "PDF" }
elseif (Test-Path .\constitution\AI_Freedom_Constitution.md)    { OK "Constitution" "MD" }
else { XX "Constitution" "missing" }

if (Test-Path .\checklists\Commons_First_Moves_Checklist.pdf)   { OK "Checklist" "PDF" }
elseif (Test-Path .\checklists\Commons_First_Moves_Checklist.md){ OK "Checklist" "MD" }
else { XX "Checklist" "missing" }

Write-Host "`nBootstrap checks complete." -ForegroundColor Cyan
