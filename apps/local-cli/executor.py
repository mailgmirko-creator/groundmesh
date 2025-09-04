import subprocess, sys, os, datetime, pathlib, re

DENY_PATTERNS = [
    " rm ", " rm -", " rmdir ", " del ",
    " format ", " mkfs", " diskpart",
    " shutdown ", " poweroff ",
    " :> ", " >/dev/sda", " >/dev/nvme",
]

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
LOG_DIR = REPO_ROOT / "data" / "logs"

def log_line(mode: str, cmd: str, rc: int | None = None):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    day = datetime.datetime.now().strftime("%Y%m%d")
    path = LOG_DIR / f"actions-{day}.txt"
    status = "" if rc is None else f" rc={rc}"
    with open(path, "a", encoding="utf-8") as f:
        f.write(f"{stamp} [{mode}]{status} {cmd}\n")

def is_dangerous(cmd: str) -> bool:
    c = f" {cmd.lower()} "
    return any(p in c for p in DENY_PATTERNS)

def run_command(cmd: str, dry_run: bool, yes: bool):
    if dry_run:
        print(f"[plan] would run: {cmd}")
        log_line("plan", cmd, None)
        return 0

    if is_dangerous(cmd) and not yes:
        msg = "[guard] blocked potentially destructive command. Use --yes to force."
        print(msg, file=sys.stderr)
        log_line("blocked", cmd, 2)
        return 2

    print(f"[run] {cmd}")
    try:
        if os.name == "nt":
            completed = subprocess.run(
                ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd]
            )
        else:
            completed = subprocess.run(cmd, shell=True)
        rc = completed.returncode
        log_line("run", cmd, rc)
        return rc
    except Exception as e:
        print(f"[error] {e}", file=sys.stderr)
        log_line("error", f"{cmd} :: {e}", 1)
        return 1
