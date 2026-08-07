# GroundMesh Coordination Field — Synthetic Breathing Test v0.1

Status: Guarded Stage-B test  
Date: 2026-08-07  
Scope: Fictional need ↔ capacity state transition only  
Related: `docs/coordination/coordination-field.md`, `docs/coordination/coordination-field.v0.1.json`

## Why this test exists

The Coordination Field defines a vocabulary for need, capacity, commitments, delivery, unmet need, planned gap, and spare capacity. Before any real-world dataset or matching service uses those quantities, GroundMesh needs one small example that can be calculated repeatedly and rejected automatically when the state becomes inconsistent.

This test is intentionally fictional. It does not represent a real locality, organization, person, water system, contract, need, or offer. It authorizes no allocation and creates no public matching service.

Its purpose is to answer a narrower engineering question:

> Do the coordination quantities remain coherent as a possible match moves from observation → proposal → consented commitment → partial verified delivery?

## Clarification discovered by the test

Walking the v0.1 equations through delivery exposes an ambiguity that is easy to miss in prose.

The planned-gap expression is:

```text
G = max(0, N - D - K_valid)
```

If `K_valid` includes quantities that have already been delivered, delivery is counted once in `D` and again inside `K`, which is wrong.

For Stage B, GroundMesh therefore uses the following operational interpretation:

- `K_outstanding` = valid commitment that is still outstanding and has **not yet been delivered, cancelled, expired, or otherwise removed**;
- `C_remaining` = capacity still physically or operationally available within the defined time window at the current snapshot, including both outstanding committed capacity and uncommitted spare capacity;
- a pending proposal is **not** a commitment;
- consent may convert a proposal into an outstanding commitment;
- verified delivery transfers quantity out of outstanding commitment and into verified delivery;
- on the supply side, verified delivery also consumes the corresponding remaining capacity.

The Stage-B calculations are therefore:

```text
U = max(0, N - D)
G = max(0, N - D - K_outstanding)
S = max(0, C_remaining - K_outstanding)
```

This is a test clarification, not a claim that the v0.1 vocabulary is final. A later Coordination Field revision should make the snapshot semantics explicit in the core model.

## Fictional scenario

Two invented participants are used:

- **Blue Harbor Locality** — a fictional locality with an assessed potable-water delivery need;
- **Green Ridge Water Cooperative** — a fictional provider with compatible spare delivery capacity.

The resource is fictional potable-water delivery measured in `m3/day` under an invented quality threshold `GM-SYNTH-WQ-1` for one fictional daily window.

No geographic coordinates, real names, real URLs, personal records, or real operational claims are included.

## State 0 — observed

Need side:

```text
N = 100
D = 20
K_outstanding = 30
U = 80
G = 50
```

Capacity side:

```text
C_remaining = 75
K_outstanding = 20
S = 55
```

Interpretation: 50 units of need remain unplanned after existing commitments, while the provider has 55 units of spare compatible capacity.

## State 1 — proposal only

GroundMesh surfaces a possible match of `40` units.

The proposal is pending and non-binding.

Therefore **nothing in the accounting changes yet**:

```text
need:     N=100, D=20, K=30, U=80, G=50
capacity: C=75, K=20, S=55
proposal: 40, consent=pending, binding=false
```

This is important. A recommendation, alert, or CI suggestion must not silently become a commitment.

## State 2 — consented commitment

Both fictional participants accept the 40-unit proposal.

The amount becomes an outstanding commitment on both compatible ledgers:

```text
need:     N=100, D=20, K=70, U=80, G=10
capacity: C=75, K=60, S=15
proposal: 40, consent=accepted, binding=true
```

The planned gap falls from 50 to 10. Spare capacity falls from 55 to 15.

No delivery has happened yet, so `D` and `C_remaining` do not change at this transition.

## State 3 — partial verified delivery

The fictional provider delivers and verifies `35` of the 40 newly committed units.

Delivery moves 35 units from outstanding commitment into verified delivery on the need side, and consumes 35 units of remaining supply-side capacity:

```text
need:     N=100, D=55, K=35, U=45, G=10
capacity: C=40, K=25, S=15
```

Notice two useful invariants:

- `U` falls because real delivery occurred;
- `G` and `S` remain unchanged for the delivered portion because delivery replaces an already-counted outstanding commitment rather than creating new planning coverage.

This is the exact place where an incorrectly defined `K` would double-count.

## What the validator checks

`scripts/coordination-fixture-validate.ps1` checks that:

1. the fixture is explicitly synthetic and non-public;
2. all participants are fictional and no person subject is present;
3. units, quality threshold, time window, provenance, and uncertainty are declared;
4. state IDs are unique and the expected four-stage sequence exists;
5. `U`, `G`, and `S` equal the formulas above in every state;
6. all quantities are non-negative and commitments do not exceed the compatible need/capacity boundary in this fixture;
7. the pending proposal changes no commitment or delivery quantity;
8. the proposed amount fits both the observed planned gap and observed spare capacity;
9. consent moves the proposed amount into outstanding commitment on both sides without inventing delivery;
10. partial delivery increases `D`, decreases outstanding `K`, and consumes `C_remaining` by the same delivered amount;
11. forbidden scoring/ranking/person-worth fields do not appear;
12. the fixture grants GroundMesh no allocation authority.

The validator is wired into `repo-health` so later edits cannot silently break the example.

## What this test does not prove

Passing this fixture does **not** prove that GroundMesh can safely coordinate real water, food, housing, energy, money, medicine, logistics, or emergency resources.

It does not test:

- identity or authorization;
- legal commitments;
- real quality standards;
- transport feasibility;
- price or affordability;
- conflicting claims;
- privacy;
- adversarial data;
- multi-provider matching;
- partial consent among many parties;
- expiry, cancellation, substitution, or correction races;
- scarce-resource fairness;
- emergency prioritization;
- real-world governance.

Those belong to later guarded work.

## Success criterion

Stage B succeeds when the repository can repeatedly demonstrate:

```text
observation
-> non-binding proposal
-> explicit consent
-> outstanding commitment
-> verified partial delivery
```

while keeping the arithmetic coherent and preserving the rule:

> GroundMesh may surface and verify a possible cooperation path; it does not convert a proposal into action without consent.

## Next gate

Only after this fixture remains understandable and stable should GroundMesh consider Stage C: one low-risk, harmless, public-data demonstration with no person ranking and no autonomous decision.
