# Runtime Boundary: Public Pages vs Live Services

## Why this exists

GroundMesh uses GitHub Pages as a transparent public front door. That is a strength, but only if the runtime boundary stays explicit.

This document defines what belongs in static public hosting and what must run in dedicated services or node agents.

## Public static layer (GitHub Pages)

Use for:

- Public narrative and orientation pages.
- Atlas and documentation artifacts.
- Public checklists and governance references.
- PWA shell, static assets, and non-sensitive read-only views.

Characteristics:

- Deterministic, inspectable, low operational risk.
- No private secrets.
- No server-side compute.

## Live service / node layer (outside Pages)

Use for:

- Assignment distribution and result collection.
- Durable job execution and scheduling.
- Trust-sensitive verification/signing workflows.
- Any write operation requiring integrity controls.
- Any API that could expose sensitive metadata.

Characteristics:

- Requires authentication and authorization design.
- Requires observability, alerting, and incident handling.
- Must handle abuse resistance and rate controls.

## Non-negotiable controls

- Never store credentials or private keys in the static site.
- Never assume client-side code can protect secrets.
- Treat browser storage as user convenience, not secure state.
- Validate and sanitize every input at live service boundaries.
- Keep public and privileged command paths separate by design.

## Data classification quick map

- **Public**: docs, static maps, openly published status snapshots.
- **Operational**: queue states, assignment receipts, node health records.
- **Sensitive**: secrets, private contacts, trust anchors, privileged controls.

Only the first class should exist in GitHub Pages artifacts.

## Evolution rule

Start centralized for safety and clarity, then decentralize intentionally:

1. Public documentation and transparency first.
2. Minimal live loop with bounded tasks.
3. Hardened verification and trust services.
4. Federated participation as operational maturity proves out.
