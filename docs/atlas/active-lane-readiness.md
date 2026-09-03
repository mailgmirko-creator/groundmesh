# GroundMesh ACTIVE Lane Readiness

Status: Active operating guide
Date: 2026-09-03

## Lane Roles

- `GroundMesh-ACTIVE`: clean local reflection of GitHub `main`; protected, certifiable, and not used for experimentation.
- `GroundMesh-DEV`: workshop lane for staging or feature work.
- older `GroundMesh` folders: preservation and salvage zones until unique changes are understood, copied, merged, or archived.
- private material: M2 notes, identifying evidence, secrets, and participant records stay outside the public repository.

Clean means understood and safely placed. It does not mean deleted.

## ACTIVE Certification Checklist

Run these checks from the ACTIVE checkout before treating it as certifiable:

```powershell
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
git ls-remote origin refs/heads/main
git config --get core.hooksPath
Test-Path .githooks/pre-push
```

Expected result:

- branch is `main`
- working tree is clean
- local HEAD, local `origin/main`, and live remote `refs/heads/main` match
- `core.hooksPath` points to `.githooks` or the local `.git/hooks/pre-push` guard is present
- no untracked deploy scripts, exports, private notes, case evidence, credentials, or generated archives sit in ACTIVE

## Preservation Before Cleaning

Before removing untracked files or resolving dirty state:

1. list full status and diffs
2. copy untracked or dirty work into a dated `_preserve` folder outside the checkout
3. record the source checkout, branch, HEAD, and purpose if known
4. only then move, integrate, or remove the loose files

Do not use `git clean`, `git reset --hard`, branch deletion, worktree pruning, or stash as a substitute for understanding.

## Hook Restoration

GroundMesh tracks the local pre-push guard in `.githooks/pre-push`. To inspect it without changing config:

```powershell
.\scripts\install-git-hooks.ps1 -CheckOnly
```

To activate it in the primary checkout after review:

```powershell
.\scripts\install-git-hooks.ps1
```

The hook blocks direct pushes to `main`. Release work should move through a guarded branch and PR/release review.

## Public Repo Warning

A folder named `internal/` inside a public repository is still public in practical terms. Use it for workflow boundaries and non-linked materials only, never for confidential storage.
