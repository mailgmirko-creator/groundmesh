# Assistant Brief — GroundMesh

## How we work (directives)
- Atlas-first: Consult docs/atlas/registry.json + Atlas page before adding or changing anything.
- Coordination-field first: Before adding need/capacity matching, allocation, metric, or scoring logic, read `docs/coordination/coordination-field.md` and `docs/coordination/coordination-field.v0.1.json`; preserve consent, context, evidence provenance, non-capture, no person-worth scoring, and no autonomous allocation.
- Needs/offers readiness first: Before opening any public needs/offers page, issue template, data feed, form, board, or matching workflow, read `docs/checklists/Needs_Offers_Readiness_Checklist.md`; keep emergency, confidential, high-risk, money-flow, and public-ranking material out of the static public queue.
- Money/value readiness first: Before adding Mesh Credits, seed-vault economy material, payments, donations, grants, sponsorships, tokens, wallets, fiat bridges, rewards, public balances, or value exchange, read `docs/checklists/Money_Value_Exchange_Readiness_Checklist.md`; keep legal, tax, accounting, securities, money-transmission, privacy, anti-fraud, and non-capture gates explicit.
- Human-Mesh first: Before changing registration, human identity, public human-ledger fields, verification, accountability events, participant visibility, correction, withdrawal, or global enrollment, read `docs/human-mesh/foundation-v0.1.md` together with ADR-0005. Keep public declaration data minimal, keep sensitive enrollment separate, never scrape people into the registry, never compute human worth, and do not open broad intake from the static docs layer.
- Constitutional stewardship first: Before changing governance, administrator authority, repository ownership, constitutional voting, key custody, domain control, steward succession, suspension, or removal, read `docs/decisions/0007-bootstrap-stewardship-constitutional-authority.md`; distinguish technical control from constitutional legitimacy and preserve the invariant core.
- Legal-readiness first: Before publishing real-world cases, opening registration, collecting personal data, requesting money, changing licensing language, or releasing public-interest CI-assisted text, read `docs/decisions/0008-legal-readiness-and-release-gates.md` and `docs/legal/PUBLICATION_GATE.md`; treat legal readiness as a release gate, not a compliance claim.
- Behavior-Atlas first: Before changing Behavior Atlas schema, cases, pages, releases, or validators, read ADR-0006, `docs/behavior-atlas/PUBLIC_ALPHA_POLICY.md`, and `docs/behavior-atlas/PATTERNS_NOT_ENEMIES.md`; preserve no person subjects, no scores/ranks, no enemy labels, no motive inference, no guilt findings, no autonomous publication, and no unguarded M2 publication.
- Steward-loop local first: For broad, memory-heavy, or emotionally charged sessions, use `.\scripts\groundmesh-steward.ps1` only as a local synthesis tool; keep its output under ignored `private/steward/` and review before public use.
- Smallest safe change: Prefer incremental, reversible edits.
- Small batches: Prefer one meaningful chunk at a time, then summarize what changed and what remains next.
- Recovery before rush: If a session or approval flow freezes, inspect current state first and resume from the last stable point.
- Shared external spine: Anchor important state in GitHub through repo files, issues, PRs, Atlas, or ADRs rather than relying on tool memory alone.
- Less, but more anchored: Do not add a new layer unless it clearly reduces friction, increases clarity, improves execution, or preserves meaning in a more usable form.
- Promotion model: `main` is the active public lane, `dev` is the staging lane when needed, and short-lived branches carry focused work.
- Hospitality: clear messages, zero shaming, Brave-friendly UIs.
- Guarded patches only: never overwrite/rename widely without a backup or branch.

## Current focus
- Unify the stronger `groundmesh-world` public seed with the Atlas-backed `GroundMesh/docs` front door.
- Stabilize public docs (Home, Get Started, Contributors, Map, Compute, Atlas, Landscape, Contact, Privacy).
- Surface existing donate/volunteer flow; avoid re-invention and avoid repo drift.
- Treat future registration as a narrow pilot with real moderation, privacy, and rollback gates rather than a broad launch.
- Grow Human Mesh through H0/H1 guarded stages: universal voluntary invitation in principle, small real cohorts in practice until handling capacity is proven.

## Golden links
- Get Started: /get-started/index.html
- Atlas: /atlas/index.html
- Landscape: /landscape.html
- Contributors: /contribute.html
- Map: /map.html
- Human Mesh: /human-mesh/index.html
- Registration: /register.html
- Contact: /contact.html
- Privacy: /privacy.html
- Compute Transparency: /compute.html

## Session ritual
1) Run scripts/health-check.ps1
2) Inspect pending state and group the next change into one practical batch
3) Fix one red/yellow or one integration slice, then summarize touched files + next step
4) Update status.json if state changed
5) Regenerate Atlas
6) Run `.\scripts\install-git-hooks.ps1 -CheckOnly` before certifying an ACTIVE checkout
7) Anchor any real decision in GitHub-visible memory before treating it as settled
