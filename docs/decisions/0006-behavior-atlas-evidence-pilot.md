# 0006 — Behavior Atlas Begins as an Evidence-First Pilot
Date: 2026-07-22
Status: Accepted

## Context

GroundMesh has long aimed to make patterns of extraction, cooperation, concentration, stewardship,
and shared benefit easier to see through public evidence. The next phase is the **Behavior Atlas**:
a readable evidence map that can connect public records, audits, procurement, ownership,
environmental data, rigorous journalism, and other inspectable sources.

This creates real risks if interpretation outruns evidence. A behavior map could become a hidden
reputation system, collapse a person into a label, conceal uncertainty behind a score, or automate
publication before correction and review paths exist. It could also be confused with **Project
Atlas**, whose existing purpose is to inventory GroundMesh artifacts and show repository health.

The current GroundMesh public layer is static, versioned, and intentionally honest about its
privacy limits. The Behavior Atlas should begin inside those limits rather than pretending that a
hardened research, intake, or adjudication system already exists.

## Decision

GroundMesh will begin the Behavior Atlas as a narrow, evidence-first pilot.

1. **Project Atlas and the Behavior Atlas remain distinct.**
   - Project Atlas continues to map what exists in the GroundMesh repository and its health.
   - The Behavior Atlas maps public evidence, claims, observable conduct, consequences, and
     cautiously stated patterns.

2. **The unit of analysis is an evidenced action or system footprint, not a moral identity.**
   - Primary subjects are projects, institutions, public programs, policies, contracts, and events.
   - A person may appear only when a relevant public role is necessary to understand an evidenced
     action.
   - The pilot will not create person scores, moral rankings, guilt findings, inferred motives, or
     permanent labels.

3. **The evidence chain must remain inspectable.**
   - The core chain is: source → evidence item → atomic claim → pattern assessment → case.
   - Every public claim must resolve to identifiable sources and an exact locator.
   - Fact, allegation, inference, and pattern assessment must remain visibly distinct.
   - Contradictory and exculpatory evidence are first-class records, not footnotes to be hidden.

4. **Interpretation must expose its limits.**
   - Pattern assessments may use transparent lenses such as consent and agency, distribution of
     benefits and burdens, transparency and answerability, resource stewardship, reciprocity and
     cooperation, and concentration or capture risk.
   - Direction may be described as cooperation-supporting, extraction-risk, mixed, or unclear.
   - Confidence uses named bands and explicit rationale, not false-precision percentages.

5. **Humans remain responsible for publication.**
   - Computer Intelligence may help collect metadata, detect duplicates, propose atomic claims,
     and flag possible contradictions.
   - It may not assign motive, resolve a contested claim, create a public score, or publish without
     human approval.
   - Each release must be reviewable, date-stamped, reproducible, reversible, and preserved in
     version history.

6. **The first pilot uses public sources only.**
   - No confidential disclosures, sensitive personal data, anonymous accusations, or emergency
     reporting enter the static public repository.
   - Tips, posts, and unverified assertions may be treated only as leads until independently
     verified.
   - Data minimization and the existing GroundMesh privacy posture apply throughout.

7. **Correction and rollback precede public scale.**
   - A public preview requires visible provenance, limitations, counterevidence, review history,
     a correction path, a review-due date, and a way to supersede a record without erasing history.
   - If a release causes unresolved harm, loses its evidence trail, or fails validation, the static
     output can be withdrawn and restored to the last known-good version while the review record
     remains visible.

8. **The Cooperation Index remains research-only.**
   - GroundMesh will not publish a composite index until several cases have passed public-alpha
     review and the methodology has received independent scrutiny.
   - Early work must first prove that claim-level evidence and corrections remain understandable.

## Guarded rollout

The rollout proceeds through explicit gates:

- **M0 — constitutional anchor:** this ADR, shared terms, prohibited uses, and rollback ownership.
- **M1 — schema sandbox:** one versioned schema, one synthetic fixture, and one validator; no real
  subject data and no public route.
- **M2 — internal case:** one institutional or project case with atomic claims, counterevidence,
  limitations, and a complete reviewer log.
- **M3 — unlisted preview:** one accessible static case page with source trails, corrections, and a
  visible single-reviewer warning when plural review is unavailable.
- **M4 — public alpha:** several cases, a changelog, expiry policy, privacy and harm review, and a
  successful restore drill.
- **M5 — assisted monitoring:** read-only watchers may propose diffs; humans still approve every
  public release.

## Immediate implementation boundary

This first guarded batch adds only:

- this decision record
- its Project Atlas registry entry
- the regenerated Atlas page

It does **not** add a Behavior Atlas page, database, API, scraper, real-subject dataset, score,
watcher, or automated publisher.

## Consequences

- GroundMesh gains a durable constitutional boundary before it gains new data machinery.
- The Behavior Atlas can grow from evidence and correction practices rather than from labels.
- Early progress will be slower than automated bulk collection, but easier to inspect, reverse,
  and trust.
- Project Atlas remains the canonical orientation map and records each durable Behavior Atlas
  artifact as it is accepted.
- Future schema or interface work requires a separate guarded batch and must pass the applicable
  rollout gate.

## Related GroundMesh artifacts

- `docs/decisions/0001-why-atlas.md`
- `docs/decisions/0004-active-dev-promotion-model.md`
- `docs/atlas/seed-trust-mesh-edge.md`
- `docs/privacy.html`
- `docs/assistant-brief.md`
