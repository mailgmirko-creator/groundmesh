# 0007 — Bootstrap Stewardship and Constitutional Authority
Date: 2026-08-21
Status: Proposed

## Context

GroundMesh now has an explicit invariant core, including:

- GM-INV-II — Transparent State
- GM-INV-IV — No Ownership — Only Stewardship
- GM-INV-V — No Derivatives Without Alignment
- GM-INV-VI — Voluntary Participation
- GM-INV-VII — Decentralized Agency
- GM-INV-VIII — Continuity With Consent

There is an important implementation gap between those principles and the current technical reality.
The canonical repository presently lives under one personal GitHub account, and the founder therefore
retains de facto platform-level administrative power over the project. That power can be useful while
GroundMesh is small, but it would be misleading to describe the present topology as fully decentralized.

The opposite mistake would be to distribute authority prematurely to people or systems merely to make
the structure look decentralized. GroundMesh needs a path from founder custody to plural stewardship
without handing constitutional integrity to whichever person happens to receive an admin key.

This decision also clarifies two neighboring questions:

1. Transparent State must coexist with privacy, security, and data minimization.
2. GM-INV-V describes a constitutional condition for aligned modifications, while the current
   Tranquility Commons License — NoDerivatives 1.0 is legally stricter and currently forbids public
   modified versions.

## Decision

GroundMesh will treat authority as **stewardship bounded by the invariant core**, not as personal
sovereignty.

### 1. Constitutional order

The governing order is:

1. the GroundMesh invariant core
2. accepted constitutional decisions and protocols that interpret the invariants without weakening them
3. stewardship roles and delegated permissions
4. implementation choices, repository settings, code, services, and operational procedures

No steward, including the founder, may legitimately use a lower layer to nullify a higher one.
Technical ability and constitutional legitimacy are therefore not the same thing.

### 2. The present state is Founder Custody

GroundMesh explicitly recognizes the current phase as **Founder Custody**.

In this phase the founder retains broad technical control because the system does not yet have enough
trusted, capable, independent stewards or technical mechanisms to distribute critical authority safely.
This is a bootstrap condition and an acknowledged implementation gap under GM-INV-VII, not a claim
that one-person control is the mature constitutional form.

Founder Custody has no invented deadline. GroundMesh must not decentralize merely to satisfy a calendar.
Transition should occur when real participation, trust, capability, and technical safeguards exist.
This preserves GM-INV-VIII: continuity and maturation are not forced through pressure.

### 3. Founder Steward role

During Founder Custody, the founder acts as **Founder Steward** rather than owner or sovereign.

The Founder Steward may:

- maintain the canonical repository and public surfaces
- accept, reject, or request revision of ordinary project changes
- protect the invariant core from dilution, capture, coercion, or hidden alteration
- pause a high-impact change when there is a credible constitutional or safety concern
- appoint provisional maintainers and withdraw provisional permissions while the project remains in bootstrap
- restore the project to a known-good state after technical failure or unauthorized change

The Founder Steward may not legitimately:

- weaken, remove, or privately redefine an invariant by unilateral decision
- convert stewardship into ownership or private enclosure
- coerce participation or make exit conditional on obedience
- conceal material governance decisions while invoking transparency as a public value
- permanently delegate unchecked sovereign authority to another person, institution, or CI system
- treat disagreement with the founder as itself a constitutional violation

### 4. The founder may hold a protective brake, not an unlimited throne

A founder or future constitutional steward may hold a **suspensive protective brake**.

The brake may temporarily pause a proposed high-impact action when the steward can identify a plausible
conflict with the invariant core, safety boundary, or constitutional process. Invoking the brake must
create an inspectable record stating:

- the action being paused
- the invariant or boundary believed to be at risk
- the evidence or reasoning available at the time
- what review would resolve the concern

The brake is suspensive rather than permanently sovereign. In a mature plural phase, no single steward
may use it to block an invariant-compliant action forever. A plural review process must eventually affirm,
modify, or release the pause.

This gives the founder a meaningful ability to protect GroundMesh from capture without making the founder
an exception to GM-INV-VII.

### 5. Stewardship is conditional, including the founder's

Authority attaches to a role only while that role is exercised within the invariant core.
No person receives an irrevocable right to govern GroundMesh.

Possible grounds for suspension or removal from a stewardship role include evidenced patterns such as:

- deliberate weakening or bypass of the invariant core
- concealed high-impact governance or resource decisions
- coercive capture, privatization, or misuse of privileged access
- knowingly falsifying governance records or evidence
- repeated refusal to correct a verified material breach after a fair opportunity to respond

The following are **not**, by themselves, grounds for removal:

- disagreeing with the founder
- proposing a different implementation
- criticizing GroundMesh or its stewards
- pausing participation
- making a good-faith mistake that is disclosed and corrected

### 6. No one person may permanently strip another person of stewardship

Permanent removal must itself satisfy GM-INV-VII.

When plural governance becomes operational, a removal process must include:

1. an inspectable evidence record
2. notice to the steward whose role is under review
3. a meaningful opportunity to answer and correct, except where temporary emergency suspension is needed
4. review by multiple independent eligible stewards, excluding the person whose role is being reviewed
5. a defined supermajority or equivalent plural threshold
6. a recorded outcome and recovery path

Until enough independent stewards exist to perform such a review honestly, GroundMesh must not pretend
that founder removal is technically enforceable. The bootstrap remedy is transparency, preservation of
history, reversible changes, external copies, and progressive reduction of unilateral critical powers.

### 7. Technical decentralization must eventually match the constitutional claim

A repository hosted under one personal account leaves the account holder with platform-level powers that
cannot be removed merely by writing an invariant. This limitation must remain visible.

A later guarded phase should move critical GroundMesh authority toward a structure such as:

- a dedicated organization or equivalent neutral canonical home
- at least three independent human stewards for constitutional review
- protected constitutional paths and protected release branches
- no routine single-person bypass of critical rules
- split control of recovery credentials, domains, signing keys, and other high-impact assets
- logged approval for constitutional, release, and permission changes
- independent read-only mirrors so no one deletion can erase project history

The exact mechanism is deliberately not fixed in this ADR. It requires a separate guarded design and
should be chosen only when real stewards and real operational needs exist.

### 8. Founder continuity after decentralization

Decentralization does not require erasing the founder's voice.

A mature structure may preserve a **Founder Guardian** role with strong standing to:

- raise constitutional objections
- invoke the suspensive protective brake
- require a documented review of a suspected invariant breach
- participate as one steward in constitutional decisions

But the Founder Guardian should not possess an unreviewable permanent veto or a unilateral power to
remove every other steward. The founder remains unusually important to continuity and interpretation,
without becoming constitutionally absolute.

### 9. Succession is transfer of a bounded role, not transfer of sovereignty

A future steward does not inherit "the founder's power." They receive a defined, reviewable permission
set conditioned on the invariant core.

If a future steward does not follow the constitutional code, the answer is not personal loyalty to the
founder. The answer is evidence, transparent review, suspension where necessary, and removal through the
same plural rules that apply to everyone else.

This allows GroundMesh to survive both failure modes:

- founder capture: one originator becoming permanently unaccountable
- successor capture: authority being handed away to someone who then abandons the invariant core

### 10. Transparent State does not abolish privacy

GM-INV-II requires transparency of the **system**, especially:

- authority and permissions
- governing rules and changes
- decision provenance
- public claims and their evidence
- material system flows and conflicts of interest
- known limitations and review boundaries

It does not require publishing private correspondence, personal data, credentials, security secrets, or
information whose disclosure would create avoidable harm.

Where information must remain private, the existence, category, governing rule, and accountable steward
of that boundary should still be visible where safely possible. GroundMesh therefore distinguishes
**transparent governance** from **total exposure**.

### 11. GM-INV-V and the current NoDerivatives license are layered, not identical

GM-INV-V states that a public modification cannot be GroundMesh-aligned unless it preserves all invariants.
That is a constitutional necessary condition.

The current TCL-ND-1.0 license is stricter: it presently forbids public modified versions altogether and
requires proposed changes to return upstream to the canonical project.

Therefore:

- invariant alignment does not by itself grant legal permission to publish a derivative
- the current license remains controlling for legal permissions while it is in force
- a future license may become more permissive only through a separate guarded review
- no license change may weaken the invariant core or convert stewardship into capture

This clarification avoids silently rewriting either GM-INV-V or TCL-ND-1.0.

## Guarded authority phases

GroundMesh adopts the following orientation model without imposing a timetable:

### S0 — Founder Custody — current

- one founder holds most technical administrative power
- the asymmetry is stated plainly
- protected `main`, PR history, Atlas, CI, and public records reduce accidental or hidden change
- no claim of mature decentralized governance

### S1 — Guarded Founder Stewardship

Trigger: real contributors and operational dependency make additional safeguards useful.

Possible guarded additions:

- constitutional-path review rules
- at least two independent recovery or review stewards
- explicit high-impact action log
- stronger non-bypass branch/ruleset controls where technically possible
- tested recovery from loss or misuse of one credential

### S2 — Constitutional Plurality

Trigger: several trusted independent stewards can actually perform review and recovery.

Expected characteristics:

- canonical authority no longer depends on one personal account
- critical actions require plural approval
- founder retains a Guardian role rather than sovereign control
- stewardship suspension/removal process becomes technically enforceable

### S3 — Distributed Stewardship

Trigger: GroundMesh has enough healthy independent participation and infrastructure that distribution
reduces capture risk rather than merely adding ceremony.

Expected characteristics:

- multiple independent stewardship and infrastructure nodes
- resilient public history and mirrors
- no single person, CI system, institution, credential, or host can silently redefine the project
- constitutional changes remain slower and more guarded than ordinary implementation changes

## Immediate implementation boundary

This decision does **not** transfer repository ownership, appoint a council, share credentials, change
GitHub permissions, modify the invariant statements, change the license, or create an automated removal
system.

The immediate guarded batch is only:

- this decision record
- its Project Atlas registration
- the regenerated Atlas entry
- one Assistant Brief reminder that future governance/authority work must load this ADR first

Any actual change to ownership, administrator permissions, constitutional voting, key custody, domain
control, or steward removal requires a separate guarded batch.

## Consequences

- GroundMesh stops pretending that current founder control already satisfies mature decentralized agency.
- The founder can remain an active protector without becoming constitutionally exempt.
- Future stewards inherit bounded responsibilities rather than personal sovereignty.
- Removal becomes a constitutional process based on evidence and plurality rather than loyalty or faction.
- Transparency is reconciled with privacy and security.
- GM-INV-V is reconciled with the stricter current NoDerivatives license without modifying either.
- Decentralization can proceed at the speed of real trust and capacity rather than pressure.

## Related GroundMesh artifacts

- `docs/invariants/GM-INV-II.md`
- `docs/invariants/GM-INV-IV.md`
- `docs/invariants/GM-INV-V.md`
- `docs/invariants/GM-INV-VI.md`
- `docs/invariants/GM-INV-VII.md`
- `docs/invariants/GM-INV-VIII.md`
- `LICENSE-TRANQUILITY.md`
- `docs/decisions/0004-active-dev-promotion-model.md`
- `docs/assistant-brief.md`
