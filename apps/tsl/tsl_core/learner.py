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
