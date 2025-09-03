import json, subprocess, sys
from pathlib import Path

model = sys.argv[1] if len(sys.argv) > 1 else "gemma:2b"

# run each node worker
subprocess.run([sys.executable, "NodeA/worker.py", "NodeA/datasetA.json", model], check=True)
subprocess.run([sys.executable, "NodeB/worker.py", "NodeB/datasetB.json", model], check=True)

# collect results
results = []
for node in ["NodeA", "NodeB"]:
    with open(Path(node) / "result.json", "r", encoding="utf-8") as f:
        results.append(json.load(f))

avg = sum(r["score"] for r in results) / len(results)
print("\n=== Coordinator Report ===")
print(json.dumps(results, indent=2))
print(f"Average score across nodes: {avg:.3f}")
