# Assistant Brief — GroundMesh

## How we work (directives)
- Atlas-first: Consult docs/atlas/registry.json + Atlas page before adding or changing anything.
- Smallest safe change: Prefer incremental, reversible edits.
- Hospitality: clear messages, zero shaming, Brave-friendly UIs.
- Guarded patches only: never overwrite/rename widely without a backup or branch.

## Current focus
- Stabilize public docs (Contributors, Map, Compute, Atlas).
- Surface existing donate/volunteer flow; avoid re-invention.

## Golden links
- Atlas: /atlas/index.html
- Contributors: /contribute.html
- Map: /map.html
- Compute Transparency: /compute.html

## Session ritual
1) Run scripts/health-check.ps1
2) Fix one red/yellow, commit
3) Update status.json if state changed
4) Regenerate Atlas
