import argparse, sys, os, re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

try:
    from engine.config_loader import load_behavior
except Exception:
    import yaml
    def load_behavior(root=None):
        root_path = Path(root) if root else REPO_ROOT
        with open(root_path / "policies" / "behavior.yml", "r", encoding="utf-8") as f:
            return yaml.safe_load(f)

from executor import run_command

def load_env_file(path: Path):
    env = {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()
    return env

VAR_PATTERN = re.compile(r"\$\{([A-Z0-9_]+)\}")
def expand_vars(cmd: str, variables: dict) -> str:
    def repl(m):
        key = m.group(1)
        return variables.get(key, os.environ.get(key, m.group(0)))
    return VAR_PATTERN.sub(repl, cmd)

def load_commands(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    if lines:
        lines[0] = lines[0].lstrip("\ufeff")  # strip BOM
    cmds = []
    for ln in lines:
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        cmds.append(s)
    return cmds

def main():
    parser = argparse.ArgumentParser(
        description="GroundMesh local CLI with dry-run, guardrails, logs,  templates, and tasks/"
    )
    parser.add_argument("--cmd", type=str, help="One command (supports )")
    parser.add_argument("--file", type=str, help="Path to cmds file (supports )")
    parser.add_argument("--task", type=str, help="Task name inside apps/local-cli/tasks (e.g., daily-setup)")
    parser.add_argument("--dry-run", action="store_true", help="Plan only; do not execute")
    parser.add_argument("--yes", action="store_true", help="Skip safety confirmation for risky commands")
    args = parser.parse_args()

    _ = load_behavior(str(REPO_ROOT))  # load, no output

    cli_dir = Path(__file__).resolve().parent
    env_file_vars = load_env_file(cli_dir / ".env")
    defaults = {"PROJECT_ROOT": str(REPO_ROOT), "USERPROFILE": os.environ.get("USERPROFILE", "")}
    variables = {**defaults, **env_file_vars}

    cmds = []
    if args.cmd:
        cmds.append(args.cmd)
    if args.file:
        cmds.extend(load_commands(Path(args.file)))
    if args.task:
        task_path = cli_dir / "tasks" / f"{args.task}.cmds.txt"
        if not task_path.exists():
            print(f"Task not found: {task_path}", file=sys.stderr)
            sys.exit(2)
        cmds.extend(load_commands(task_path))

    if not cmds:
        print('No commands given. Use --cmd "..." or --file path.txt or --task name', file=sys.stderr)
        sys.exit(2)

    exit_code = 0
    for raw in cmds:
        expanded = expand_vars(raw, variables).strip()
        if not expanded or expanded.lstrip().startswith("#"):
            continue
        rc = run_command(expanded, args.dry_run, args.yes)
        if rc != 0:
            exit_code = rc
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
