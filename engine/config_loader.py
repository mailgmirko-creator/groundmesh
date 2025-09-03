import yaml, os
def load_behavior(root=None):
    root = root or os.path.dirname(os.path.dirname(__file__))
    path = os.path.join(root, "policies", "behavior.yml")
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)
