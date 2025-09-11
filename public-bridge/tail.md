# PowerShell Transcript Tail (Aggregated)

- Updated: 2025-09-11 20:23:06
- Files considered: ps_transcript_20250911_194704.txt, ps_transcript_20250911_171115.txt

```text
PS C:\Projects\GroundMesh-DEV> # README.md (no markdown code fences to avoid here-string confusion)
**********************
Command start time: 20250911202210
**********************
PS C:\Projects\GroundMesh-DEV> @'
# TinySelfLearner (TSL) — seed

Purpose: learn and internalize the project’s Seven Principles, starting with a simple
token-based pass (no external ML libs). This sets the contract so donated compute
(Transparency Grid) can run learning jobs later.

## Layout
- apps/tsl/principles/principles.yaml — canonical 7 principles (edit this with final wording).
- apps/tsl/tsl_core/learner.py — pure-Python “learning” stub: tokenizes/summarizes principles.
- apps/tsl/jobs/learn_principles.json — example job spec for future distributed runs.
- apps/tsl/artifacts/ — model outputs (e.g., principles_model.json).

## Local test (optional)
Requires Python 3.8+ on PATH.
Run:
python apps/tsl/tsl_core/learner.py apps/tsl/principles/principles.yaml apps/tsl/artifacts

This writes: apps/tsl/artifacts/principles_model.json
'@ | Set-Content -Encoding UTF8 (Join-Path $Base "README.md")
**********************
Command start time: 20250911202210
**********************
PS C:\Projects\GroundMesh-DEV> # principles.yaml
**********************
Command start time: 20250911202301
**********************
PS C:\Projects\GroundMesh-DEV> # === Clean rewrite of TSL scaffold (no code fences), commit to dev, push, refresh ===
**********************
Command start time: 20250911202301
**********************
PS C:\Projects\GroundMesh-DEV> $DevRepo = "C:\Projects\GroundMesh-DEV"
**********************
Command start time: 20250911202301
**********************
PS C:\Projects\GroundMesh-DEV> cd $DevRepo
**********************
Command start time: 20250911202301
**********************
PS C:\Projects\GroundMesh-DEV> git checkout dev

**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> $Base = Join-Path $DevRepo "apps\tsl"
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> New-Item -ItemType Directory -Force -Path $Base, "$Base\principles", "$Base\tsl_core", "$Base\jobs", "$Base\artifacts" | Out-Null
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> New-Item -ItemType File -Force -Path (Join-Path $Base "artifacts\.gitkeep") | Out-Null
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> # README.md (no markdown code fences to avoid here-string confusion)
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> @'
# TinySelfLearner (TSL) — seed

Purpose: learn and internalize the project’s Seven Principles, starting with a simple
token-based pass (no external ML libs). This sets the contract so donated compute
(Transparency Grid) can run learning jobs later.

## Layout
- apps/tsl/principles/principles.yaml — canonical 7 principles (edit this with final wording).
- apps/tsl/tsl_core/learner.py — pure-Python “learning” stub: tokenizes/summarizes principles.
- apps/tsl/jobs/learn_principles.json — example job spec for future distributed runs.
- apps/tsl/artifacts/ — model outputs (e.g., principles_model.json).

## Local test (optional)
Requires Python 3.8+ on PATH.
Run:
python apps/tsl/tsl_core/learner.py apps/tsl/principles/principles.yaml apps/tsl/artifacts

This writes: apps/tsl/artifacts/principles_model.json
'@ | Set-Content -Encoding UTF8 (Join-Path $Base "README.md")
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> # principles.yaml
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> @'
principles:
  - id: 1
    name: Non-coercion (Let Them Choose)
    summary: People must be free to opt in or out. We persuade by clarity and example, never by force.
    tenets:
      - Participation is voluntary at every layer.
      - Exit is always available without penalty.
      - Dialogue over dominance; invitation over imposition.
  - id: 2
    name: Radical Transparency
    summary: Decisions, code, money flows, and governance are observable and auditable by default.
    tenets:
      - Open logs and public changelogs.
      - Verifiable accounting and traceable flows.
      - Documented decisions with rationale.
  - id: 3
    name: Voluntary Contribution & Fair Attribution
    summary: Everyone can contribute time, compute, and resources; credit and provenance are tracked.
    tenets:
      - Contributors keep attribution and reputation trails.
      - Small contributions are as visible as large ones.
      - Rewards align with transparent impact measures.
  - id: 4
    name: Local-first Stewardship
    summary: Solve problems as close to their origin as possible; higher layers support, not overrule.
    tenets:
      - Subsidiarity: push power to the edges.
      - Local autonomy with shared interfaces.
      - Federation over centralization.
  - id: 5
    name: Accountability & Reversibility
    summary: Actions are attributable; harmful changes can be rolled back with minimal collateral damage.
    tenets:
      - Signed actions and reproducible builds.
      - Versioned state with safe rollback paths.
      - Postmortems are blameless but specific.
  - id: 6
    name: Compassion & Dignity
    summary: Design for human well-being; assume good intent; avoid extractive patterns.
    tenets:
      - Defaults that protect attention and privacy.
      - Accessible participation for all abilities.
      - Conflict handled with care and clarity.
  - id: 7
    name: Long-Horizon Sustainability
    summary: Choices should remain maintainable, affordable, and energy-aware across decades.
    tenets:
      - Favor simple, inspectable mechanisms.
      - Lean compute; measure and minimize waste.
      - Plan for handover and succession.
'@ | Set-Content -Encoding UTF8 (Join-Path $Base "principles\principles.yaml")
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> # learner.py
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> @'
#!/usr/bin/env python3
# Minimal learner: loads principles YAML, tokenizes summaries/tenets, emits a tiny "model".
import sys, json, re, collections
from pathlib import Path

def read_text(p): return Path(p).read_text(encoding="utf-8")

def load_yaml(path):
    try:
        import yaml
        return yaml.safe_load(read_text(path))
    except Exception:
        data, cur = {"principles":[]}, None
        for line in read_text(path).splitlines():
            if re.match(r"^\s*-\s+id:\s*\d+", line):
                if cur: data["principles"].append(cur)
                cur = {"tenets":[]}
                m = re.search(r"id:\s*(\d+)", line)
                if m: cur["id"] = int(m.group(1))
            elif re.search(r"\bname:\s*", line):
                cur["name"] = line.split("name:",1)[1].strip()
            elif re.search(r"\bsummary:\s*", line):
                cur["summary"] = line.split("summary:",1)[1].strip()
            elif re.match(r"^\s{6}-\s", line):
                cur["tenets"].append(line.strip()[2:].strip())
        if cur: data["principles"].append(cur)
        return data

def tokenize(text): return [t.lower() for t in re.findall(r"[a-zA-Z]{2,}", text or "")]

def learn(principles):
    global_freq = collections.Counter()
    learned = []
    for p in principles:
        blob = (p.get("summary","") + " " + " ".join(p.get("tenets",[]))).strip()
        toks = tokenize(blob); freq = collections.Counter(toks); global_freq.update(freq)
        learned.append({"id": p.get("id"), "name": p.get("name"), "top_tokens":[w for w,_ in freq.most_common(15)]})
    return {"version":1, "principles": learned, "global_top":[w for w,_ in global_freq.most_common(200)]}

def main(in_yaml="apps/tsl/principles/principles.yaml", out_dir="apps/tsl/artifacts"):
    data = load_yaml(in_yaml)
    model = learn(data.get("principles",[]))
    Path(out_dir).mkdir(parents=True, exist_ok=True)
    out_path = Path(out_dir) / "principles_model.json"
    out_path.write_text(json.dumps(model, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {out_path}")

if __name__ == "__main__":
    in_yaml = sys.argv[1] if len(sys.argv) > 1 else "apps/tsl/principles/principles.yaml"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "apps/tsl/artifacts"
    main(in_yaml, out_dir)
'@ | Set-Content -Encoding UTF8 (Join-Path $Base "tsl_core\learner.py")
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> # learn_principles.json
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> @'
{
  "job_type": "tsl_principles_learn",
  "inputs": { "principles_yaml": "apps/tsl/principles/principles.yaml" },
  "outputs": { "artifact_dir": "apps/tsl/artifacts", "model_file": "principles_model.json" },
  "params": { "version": 1, "tokenizer": "regex-alpha-lower" }
}
'@ | Set-Content -Encoding UTF8 (Join-Path $Base "jobs\learn_principles.json")
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> # Optional local test (only if Python exists)
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> $py = Get-Command python -ErrorAction SilentlyContinue
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> if ($py) { & python "apps/tsl/tsl_core/learner.py" "apps/tsl/principles/principles.yaml" "apps/tsl/artifacts" }

**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> # Commit via message file (avoids quoting issues)
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> $MsgFile = Join-Path $DevRepo "COMMITMSG.txt"
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> Set-Content -Path $MsgFile -Encoding UTF8 -Value "feat(tsl): scaffold with 7 principles and learner stub"
**********************
Command start time: 20250911202302
**********************
PS C:\Projects\GroundMesh-DEV> git add apps/tsl

**********************
Command start time: 20250911202303
**********************
PS C:\Projects\GroundMesh-DEV> git commit -F $MsgFile

**********************
Command start time: 20250911202303
**********************
PS C:\Projects\GroundMesh-DEV> git push -u origin dev

**********************
Command start time: 20250911202305
**********************
PS C:\Projects\GroundMesh-DEV> Remove-Item $MsgFile -Force -ErrorAction SilentlyContinue
**********************
Command start time: 20250911202305
**********************
PS C:\Projects\GroundMesh-DEV> # refresh PSO snapshot so I can read it automatically
**********************
Command start time: 20250911202305
**********************
PS C:\Projects\GroundMesh-DEV> pt

**********************
Windows PowerShell transcript start
Start time: 20250911171115
Username: DESKTOP-C9G76VK\mailg
RunAs User: DESKTOP-C9G76VK\mailg
Configuration Name: 
Machine: DESKTOP-C9G76VK (Microsoft Windows NT 10.0.19045.0)
Host Application: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Process ID: 5576
PSVersion: 5.1.19041.6328
PSEdition: Desktop
PSCompatibleVersions: 1.0, 2.0, 3.0, 4.0, 5.0, 5.1.19041.6328
BuildVersion: 10.0.19041.6328
CLRVersion: 4.0.30319.42000
WSManStackVersion: 3.0
PSRemotingProtocolVersion: 2.3
SerializationVersion: 1.1.0.1
**********************
**********************
Command start time: 20250911171115
**********************
PS C:\Users\mailg> Write-Host "🟢 Transcript recording to: $Transcript"
🟢 Transcript recording to: C:\Projects\Bridge\transcripts\ps_transcript_20250911_171115.txt
**********************
Command start time: 20250911171211
**********************
PS [HOME]\\Projects
**********************
Command start time: 20250911171212
**********************
PS C:\Projects> New-Item -ItemType Directory -Force -Path C:\Projects\Bridge | Out-Null
**********************
Command start time: 20250911171212
**********************
PS C:\Projects> cd C:\Projects\Bridge
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> cd C:\Projects
**********************
Command start time: 20250911171240
**********************
PS C:\Projects> New-Item -ItemType Directory -Force -Path C:\Projects\Bridge | Out-Null
**********************
Command start time: 20250911171240
**********************
PS C:\Projects> cd C:\Projects\Bridge
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> @'
param(
  [string]$TranscriptDir = "C:\Projects\Bridge\transcripts",
  [int]$Port = 5059,
  [int]$Tail = 400
)

Add-Type -AssemblyName System.Net.HttpListener

$listener = [System.Net.HttpListener]::new()
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Clear()
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "🔎 Bridge reader listening on $prefix"

function Get-LatestTranscript {
  param([string]$Dir)
  $files = Get-ChildItem $Dir -Filter "ps_transcript_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($files) { return $files[0].FullName } else { return $null }
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $req = $ctx.Request
    $res = $ctx.Response

    switch ($req.Url.AbsolutePath) {
      "/tail" {
        $file = Get-LatestTranscript -Dir $TranscriptDir
        if (-not $file) {
          $msg = "No transcript files found."
          $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
          $res.StatusCode = 404
          $res.OutputStream.Write($bytes,0,$bytes.Length)
          break
        }
        $lines = Get-Content $file -ErrorAction SilentlyContinue | Select-Object -Last $Tail
        $text  = ($lines -join "`n")
        $bytes = [Text.Encoding]::UTF8.GetBytes($text)
        $res.ContentType = "text/plain; charset=utf-8"
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes,0,$bytes.Length)
      }
      default {
        $msg = "Use /tail to read the latest $Tail lines."
        $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
        $res.ContentType = "text/plain; charset=utf-8"
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes,0,$bytes.Length)
      }
    }
  } catch {
    Write-Host "Bridge error: $_" -ForegroundColor Red
  } finally {
    $ctx.Response.OutputStream.Close()
  }
}
'@ | Set-Content -Encoding UTF8 .\reader.ps1
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> # Verify it exists
**********************
Command start time: 20250911171240
**********************
PS C:\Projects\Bridge> Get-ChildItem .\reader.ps1


    Directory: C:\Projects\Bridge


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        11/09/2025     17:12           1848 reader.ps1



```
