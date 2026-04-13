# Assistant Brief — GroundMesh

## How we work (directives)
- Atlas-first: Consult docs/atlas/registry.json + Atlas page before adding or changing anything.
- Smallest safe change: Prefer incremental, reversible edits.
- Small batches: Prefer one meaningful chunk at a time, then summarize what changed and what remains next.
- Recovery before rush: If a session or approval flow freezes, inspect current state first and resume from the last stable point.
- Hospitality: clear messages, zero shaming, Brave-friendly UIs.
- Guarded patches only: never overwrite/rename widely without a backup or branch.

## Current focus
- Unify the stronger `groundmesh-world` public seed with the Atlas-backed `GroundMesh/docs` front door.
- Stabilize public docs (Home, Get Started, Contributors, Map, Compute, Atlas, Landscape, Contact, Privacy).
- Surface existing donate/volunteer flow; avoid re-invention and avoid repo drift.

## Golden links
- Get Started: /get-started/index.html
- Atlas: /atlas/index.html
- Landscape: /landscape.html
- Contributors: /contribute.html
- Map: /map.html
- Contact: /contact.html
- Privacy: /privacy.html
- Compute Transparency: /compute.html

## Session ritual
1) Run scripts/health-check.ps1
2) Inspect pending state and group the next change into one practical batch
3) Fix one red/yellow or one integration slice, then summarize touched files + next step
4) Update status.json if state changed
5) Regenerate Atlas
