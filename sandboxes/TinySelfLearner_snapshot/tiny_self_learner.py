import argparse, json, os, re, time, requests
from pathlib import Path

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")

DATASET = [
    {"input": "Tomorrow I need to buy milk and call John. Also schedule dentist next week. Already paid electricity.",
     "gold": ["buy milk", "call john", "schedule dentist appointment"]},
    {"input": "Notes: - Finish GroundNode README; - Push to GitHub; - Check Flask port 5000; done: installed requests",
     "gold": ["finish groundnode readme", "push to github", "check flask port 5000"]},
    {"input": "No action items here, just thinking out loud about balance and flow.", "gold": []},
    {"input": "Tasks: 1) water tomatoes daily, 2) fix fence, 3) plan boat storage layout; Completed: water tomatoes",
     "gold": ["fix fence", "plan boat storage layout"]},
    {"input": "Email Maja re parking rates; compare long-term rates in Tivat; prepare one-page proposal.",
     "gold": ["email maja about parking rates", "compare long-term rates in tivat", "prepare one-page proposal"]}
]

BASE_INSTRUCTION = """You extract actionable TODO items from a short note.

Rules:
- Return only the pending TODOs as a bullet list, one item per line, no numbering.
- Use concise verb-first phrasing (e.g., "buy milk", "call John").
- Exclude anything explicitly marked as done/completed.
- If there are no TODOs, return an empty string.
"""

MUTATION_SYSTEM = """You improve instruction prompts for a task.
Given a current instruction and its score, propose 3 concise variants that might improve accuracy,
formatting, and faithfulness. Keep each variant under 8 lines. Return JSON array of strings only.
"""

def ollama_generate(model: str, prompt: str, temperature: float = 0.0, system: str | None = None, timeout=120):
    payload = {
        "model": model,
        "prompt": (("" if system is None else system + "\n\n") + prompt),
        "stream": False,
        "options": {"temperature": temperature}
    }
    r = requests.post(f"{OLLAMA_URL}/api/generate", json=payload, timeout=timeout)
    r.raise_for_status()
    return r.json().get("response", "")

def normalize_item(s: str) -> str:
    s = s.lower().strip()
    s = re.sub(r"[\\.,;:!?]", "", s)
    s = re.sub(r"\\s+", " ", s)
    return s

def parse_todo_lines(text: str):
    lines = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        line = re.sub(r"^(\\-|\\*|\\d+[\\.)])\\s*", "", line)
        lines.append(line)
    if not lines:
        parts = [p.strip() for p in re.split(r"[;\\n]", text) if p.strip()]
        lines = parts
    return [normalize_item(x) for x in lines if x]

def evaluate_prompt(model: str, instruction: str, dataset):
    eps = 1e-9
    f1s = []
    for ex in dataset:
        user_input = ex["input"]
        gold = set(normalize_item(x) for x in ex["gold"])

        msg = f"{instruction}\\n\\nInput:\\n{user_input}\\n\\nYour Output:"
        out = ollama_generate(model, msg, temperature=0.0)
        preds = set(parse_todo_lines(out))

        tp = len(gold & preds)
        fp = len(preds - gold)
        fn = len(gold - preds)

        prec = tp / (tp + fp + eps)
        rec  = tp / (tp + fn + eps)
        f1   = 2*prec*rec / (prec + rec + eps)
        f1s.append(f1)
    return sum(f1s)/len(f1s)

def propose_mutations(model: str, current_instruction: str, current_score: float):
    prompt = f"""Current instruction (score {current_score:.3f}):
\"\"\"{current_instruction}\"\"\"

Propose 3 improved instruction variants. JSON array only."""
    raw = ollama_generate(model, prompt, temperature=0.2, system=MUTATION_SYSTEM)
    try:
        arr = json.loads(raw.strip())
        if isinstance(arr, list):
            cleaned = []
            for s in arr:
                if isinstance(s, str):
                    s_lines = s.splitlines()
                    if len(s_lines) > 12:
                        s = "\\n".join(s_lines[:12])
                    cleaned.append(s)
            return cleaned[:3]
    except Exception:
        pass

    return [
        current_instruction + "\\n- Always return only the tasks not marked done.",
        current_instruction + "\\n- If uncertain, err on precision over recall (avoid hallucinating tasks).",
        current_instruction + "\\n- Preserve original proper names (e.g., 'John', 'Maja').",
    ]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="gemma:2b")
    ap.add_argument("--iters", type=int, default=5)
    ap.add_argument("--keep", type=int, default=2)
    args = ap.parse_args()

    workdir = Path(".")
    memory_file = workdir / "memory.json"
    history = []

    best_prompt = BASE_INSTRUCTION
    best_score = evaluate_prompt(args.model, best_prompt, DATASET)
    history.append({"prompt": best_prompt, "score": best_score})
    print(f"Init score: {best_score:.3f}")

    for it in range(1, args.iters + 1):
        candidates = [best_prompt] + propose_mutations(args.model, best_prompt, best_score)
        scored = []
        for p in candidates:
            try:
                s = evaluate_prompt(args.model, p, DATASET)
            except Exception:
                s = -1.0
            scored.append((s, p))
            print(f"[Iter {it}] candidate score={s:.3f}")

        scored.sort(key=lambda x: x[0], reverse=True)
        pool = [p for (s, p) in scored[:args.keep]]

        if scored[0][0] > best_score:
            best_score, best_prompt = scored[0]
            print(f"[Iter {it}] New BEST: {best_score:.3f}")

        history.append({
            "iter": it,
            "candidates": [{"score": s, "prompt": p} for (s, p) in scored],
            "best_score": best_score,
            "best_prompt": best_prompt
        })

        time.sleep(0.5)

    print("\\n=== BEST PROMPT ===")
    print(best_prompt)
    print(f"\\nBest score: {best_score:.3f}")

    with open(memory_file, "w", encoding="utf-8") as f:
        json.dump({
            "model": args.model,
            "best_score": best_score,
            "best_prompt": best_prompt,
            "history": history
        }, f, ensure_ascii=False, indent=2)
    print(f"\\nSaved learning trace to {memory_file.resolve()}")

if __name__ == "__main__":
    main()
