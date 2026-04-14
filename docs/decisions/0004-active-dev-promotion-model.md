# 0004 — Active / Dev Promotion Model
Date: 2026-04-14T20:30:00Z
Status: Accepted

## Context
GroundMesh previously explored separate local folder copies such as `GroundMesh-ACTIVE` and
`GroundMesh-DEV` to protect a working public surface from breaking during experimentation.

That instinct was correct: public trust surfaces, uptime, and contributor-facing pages should not
be casually destabilized by in-progress work. But long-lived folder or repo copies also create
their own problems:

- drift between copies
- duplicate fixes and duplicated memory
- uncertainty about which surface is canonical
- harder recovery when many versions diverge

GroundMesh now has a healthier GitHub-centered workflow with small PR-sized batches, visible
history, and a working public deploy path from the canonical repo.

## Decision
Keep the `ACTIVE / DEV` idea, but translate it into a single canonical repo with promotion lanes.

The working model is:

1. `main` is the active public lane.
   - It represents the trusted, presentable public surface.
   - Only reviewed and verified changes should land here.
2. `dev` is the integration and staging lane when a separate merge buffer is useful.
   - It is for combining or checking batches before promotion to `main`.
   - It should not become a second source of truth.
3. Short-lived feature branches are the normal place for focused work.
   - Use them for experiments, fixes, and discrete implementation slices.
   - Merge or close them quickly rather than letting them become parallel worlds.
4. Separate systems should be introduced only when the operational risk is truly different.
   - Future registration, identity, moderation, privacy, or confidential intake services may
     deserve separate private repos or services.
   - Static public docs and sensitive intake should not be collapsed into the same operational
     surface by default.

## Consequences

- GroundMesh keeps one canonical memory spine instead of many drifting folder copies.
- Public stability is protected through promotion discipline rather than duplicate trees.
- The project can keep moving in small safe batches without sacrificing uptime or clarity.
- Future public registration can be piloted carefully in a separate sensitive layer if needed,
  rather than being rushed into the static public docs surface.
