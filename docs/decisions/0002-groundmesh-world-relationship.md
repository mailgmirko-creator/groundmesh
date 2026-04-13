# 0002 — Relationship Between GroundMesh World and GroundMesh
Date: 2026-04-13T08:30:00Z
Status: Accepted

## Context
We now have two meaningful public-facing surfaces:

- `groundmesh-world` is the stronger narrative-facing public seed.
- `GroundMesh/docs` is the stronger structural and operational surface because it already contains Atlas, contributor flow, map, compute transparency, and governance references.

We also learned a practical workflow lesson: large multi-step sessions can hit UI or approval bottlenecks before the real work is conceptually blocked. That makes smaller, commit-sized integration slices safer than broad collapses.

## Decision
Do not hard-merge the two repos yet.

Instead:

1. `GroundMesh` remains the canonical core repository for:
   - Atlas and project memory
   - public docs and contributor flow
   - governance artifacts and operational references
2. `groundmesh-world` remains a standalone public seed and design reference.
3. Merge by translation, not by collapse:
   - port the strongest narrative/public elements from `groundmesh-world` into `GroundMesh/docs`
   - keep the relationship visible through links, Atlas, and the Landscape page
4. Work in smaller safe batches whenever syncing between the two.
5. Revisit a deeper repo merge only when keeping two public surfaces creates more drift than value.

## Consequences
- The public front door can improve immediately without destabilizing the canonical docs/Atlas layer.
- We preserve a clear place for orientation and governance while still using the stronger public seed.
- Smaller integration slices reduce the risk of approval/UI bottlenecks and make recovery easier.
- The project keeps optionality: we can later absorb `groundmesh-world` more fully, or keep it as a parallel public seed if that remains useful.
