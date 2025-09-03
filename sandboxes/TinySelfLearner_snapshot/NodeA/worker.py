import sys, json
from pathlib import Path

# make project root importable (…/TinySelfLearner)
sys.path.append(str(Path(__file__).resolve().parents[1]))
from tiny_self_learner import evaluate_prompt, BASE_INSTRUCTION

def main():
    if len(sys.argv) < 3:
        print("Usage: python worker.py <dataset.json> <model>")
        sys.exit(1)

    dataset_file = Path(sys.argv[1])
    model = sys.argv[2]

    # NOTE: utf-8-sig handles Windows BOM safely
    with open(dataset_file, "r", encoding="utf-8-sig") as f:
        dataset = json.load(f)

    score = evaluate_prompt(model, BASE_INSTRUCTION, dataset)
    print(f"Worker finished {dataset_file}, score={score:.3f}")

    # save result.json inside the same node folder
    result_path = dataset_file.parent / "result.json"
    with open(result_path, "w", encoding="utf-8") as f:
        json.dump({"dataset": str(dataset_file), "score": score}, f)

if __name__ == "__main__":
    main()
