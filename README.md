# GroundMesh

GroundMesh is the canonical core repository for the public docs layer, Atlas, contributor flow,
governance artifacts, and trust scaffolding around the wider GroundMesh project.

The stronger narrative public seed currently lives alongside this repo as
[`groundmesh-world`](https://mailgmirko-creator.github.io/groundmesh-world/).
The current working pattern is:

- `GroundMesh` = canonical core, Atlas, docs, contributor and trust layer
- `groundmesh-world` = narrative public seed and design reference
- merge by small translation steps, not by collapsing the repos all at once

## Open now

- Public front door: [https://mailgmirko-creator.github.io/groundmesh/](https://mailgmirko-creator.github.io/groundmesh/)
- Atlas: [https://mailgmirko-creator.github.io/groundmesh/atlas/index.html](https://mailgmirko-creator.github.io/groundmesh/atlas/index.html)
- Contributors hub: [https://mailgmirko-creator.github.io/groundmesh/contribute.html](https://mailgmirko-creator.github.io/groundmesh/contribute.html)
- Public narrative seed: [https://mailgmirko-creator.github.io/groundmesh-world/](https://mailgmirko-creator.github.io/groundmesh-world/)

## What this repo holds

- `docs/` public pages, Atlas, contributor flow, glossary, decisions, invariants
- `scripts/` guarded operational scripts for health checks, Atlas generation, bootstrap, release
- `apps/` application surfaces such as transparency-grid
- `balance_engine/` adjacent operational and dashboard experiments

## Current public posture

GroundMesh is already strong enough to act as a public statement, contributor doorway, and
transparent orientation layer. It is not yet a hardened emergency intake or confidential reporting
system. The public layer should stay honest about those limits.

## Quick local start

```powershell
git clone https://github.com/mailgmirko-creator/groundmesh.git
cd groundmesh
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\bootstrap-node.ps1
.\scripts\health-check.ps1
```

If you want the project map before changing anything, open Atlas first:

```powershell
.\scripts\atlas-generate.ps1
start .\docs\atlas\index.html
```

## Best next pages

- Builder start: [docs/get-started/index.html](docs/get-started/index.html)
- Contributors hub: [docs/contribute.html](docs/contribute.html)
- Contact: [docs/contact.html](docs/contact.html)
- Privacy: [docs/privacy.html](docs/privacy.html)
- Landscape scan: [docs/landscape.html](docs/landscape.html)

## Working pattern

- Atlas-first before adding new structures
- Smallest safe change
- Small batches with a quick summary after each one
- Recovery before rush when a session or approval flow stalls

## License

Tranquility Commons License - NoDerivatives 1.0 (`TCL-ND-1.0`).
Non-commercial. No derivatives. Attribution plus purpose-integrity required.
See [LICENSE-TRANQUILITY.md](LICENSE-TRANQUILITY.md).
