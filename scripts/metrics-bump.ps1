param([int]$cpu=0,[int]$gpu=0,[int]$jobs=0,[int]$online=$null,[int]$regs=$null)
$p="docs/data/metrics.json"
if(-not (Test-Path $p)){ throw "Missing $p" }
$m=(Get-Content $p -Raw | ConvertFrom-Json)
$m.last_updated_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
if($null -ne $online){ $m.totals.nodes_online = $online }
if($null -ne $regs){   $m.totals.nodes_registered = $regs }
$m.totals.donated_cpu_hours += $cpu
$m.totals.donated_gpu_hours += $gpu
$m.totals.jobs_completed    += $jobs
$m | ConvertTo-Json -Depth 6 | Set-Content $p -Encoding UTF8
git add $p; git commit -m "chore(metrics): cpu+$cpu gpu+$gpu jobs+$jobs"; git push origin dev
