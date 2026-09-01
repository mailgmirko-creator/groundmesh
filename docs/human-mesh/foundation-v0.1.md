# GroundMesh Human Mesh — Foundation v0.1

Status: foundation / no broad intake
Date: 2026-08-25

## Purpose

GroundMesh intends to make it possible for any human on Earth to voluntarily declare presence, connect with others, and carry an inspectable stewardship history without turning humanity into a centralized identity database, reputation market, or moral ranking system.

The long-range invitation is universal:

**Every human may connect. No human is compelled to connect.**

This foundation extends ADR-0005 (registration begins as a pilot) and the existing Global Node Ledger. It does not open planetary registration by itself.

## Why this exists

Modern systems often make institutions highly visible while leaving ordinary people fragmented, or make ordinary people highly legible to institutions while keeping institutional power opaque.

GroundMesh should invert that asymmetry carefully:

- participation should be easy to declare;
- public authority and stewardship actions should become easier to inspect;
- a person should control what personal information becomes public;
- correction and withdrawal should remain possible;
- opacity should become harder to maintain where someone voluntarily accepts public responsibility;
- no central authority should convert disclosure into a permanent moral identity.

The aim is not to expose private lives. The aim is to make **chosen presence, responsibility, correction, and cooperation** more legible.

## Two-plane architecture

### Plane A — Public Human Declaration

The public plane is intentionally small and consent-bound.

A public human declaration may contain:

- a stable GroundMesh node id;
- a chosen public display identity;
- identity mode: `public_name` or `stable_pseudonym`;
- a coarse, self-declared location at country, region, or city precision;
- an optional public statement;
- optional self-authored accountability commitments;
- the version of the consent language accepted;
- lifecycle state: `candidate`, `active`, or `withdrawn`;
- public provenance for later corrections or changes.

It must not contain:

- government identity numbers;
- passports or document images;
- exact home addresses;
- precise residential coordinates;
- private email addresses or phone numbers;
- birth dates;
- biometrics;
- medical information;
- inferred religion, politics, sexuality, ethnicity, health, criminality, or other sensitive traits;
- hidden reputation scores or model-generated character judgments.

A public declaration is a statement of presence, not proof of legal identity, citizenship, virtue, reliability, or status.

### Plane B — Private Enrollment / Verification

If GroundMesh later needs stronger continuity or verification, that function must live outside the static public docs repository in a separate, hardened intake service.

The private plane should collect only what a current operational purpose genuinely requires. Verification must be proportional to the promise being made and should avoid creating a social hierarchy in which a "verified" human is treated as more worthy than another human.

Public records should reference verification only through the least revealing status necessary, if at all. Private evidence must never be copied into the public ledger merely because it exists.

## Identity continuity without forced legal names

GroundMesh needs accountability, but accountability does not require universal legal-name exposure.

A participant may use:

- a public name; or
- a stable pseudonym that they intentionally maintain as the same GroundMesh identity over time.

The important property is **continuity and ownership of the declaration**, not forced legal-name publication.

Impersonation, rotating throwaway identities used to evade accountability, or multiple identities used to manipulate decisions remain moderation problems for later operational stages.

## Location without unnecessary exposure

Public location is self-declared and coarse by default.

Allowed precision:

- `country`
- `region`
- `city`

Exact residence is unnecessary for planetary participation and should not be requested by the public layer.

If a map later needs a pin, the displayed coordinate should represent an approximate public area chosen for that declaration, not a home location unless a person knowingly and explicitly chooses otherwise through a separately reviewed feature.

## Local expression without forced normalization

Planetary participation does not require one planetary language, alphabet, naming convention, or cultural presentation.

The shared Human Mesh contract should stay small and machine-readable where interoperability requires it: node identity continuity, consent, lifecycle, provenance, correction, withdrawal, and bounded stewardship actions.

Within that contract:

- a public name or stable pseudonym may be written in the participant's own language and script;
- public statements may be written in the participant's own language;
- place names and public location labels should preserve local spelling where practical;
- GroundMesh must not require English or ASCII merely because those forms are easier to normalize;
- translations may be added for accessibility, but should remain visibly secondary to the participant's original expression rather than silently replacing it;
- local categories and practices should not be collapsed into one global ontology unless a shared technical purpose genuinely requires a common field.

A useful architecture rule is:

> **Shared protocol; locally expressed life.**

The current public web and JSON surfaces are already UTF-8 capable. This rule therefore does not authorize a new translation service, locale framework, or schema expansion by itself. Those should be added only when real participation demonstrates a concrete need.

## Bringing darkness to light: the GroundMesh translation

GroundMesh must never implement a "darkness score," confession score, virtue score, sin ledger, trust rank, or model-generated moral profile.

The constructive equivalent is an **Open Accountability Log** owned by the participant.

A human may voluntarily publish events such as:

- `commitment` — a promise or responsibility they choose to make visible;
- `conflict_disclosure` — a conflict of interest relevant to a GroundMesh role or public claim;
- `correction` — acknowledgement that an earlier public statement or action was wrong or incomplete;
- `stewardship_action` — a public GroundMesh action performed under a role;
- `withdrawal` — ending or pausing a commitment;
- `restoration` — a self-authored note explaining how a prior problem was corrected.

These events describe **what was declared or done**. They do not define what a person *is*.

GroundMesh may validate provenance and format. It may not infer unspoken wrongdoing, force disclosure, or calculate moral worth from the log.

## Public lifecycle

A declaration has an explicit lifecycle:

`candidate → active → withdrawn`

A future operational system may add review states, but withdrawal must remain a first-class action.

Withdrawal means:

- the public profile is no longer presented as an active participant;
- historical public events that were already published may remain in an inspectable provenance trail where legally and ethically appropriate;
- private enrollment data follows the separate retention/deletion policy of the future intake service;
- withdrawal never becomes a punishment label.

## Consent model

Public participation requires explicit affirmative consent to:

1. publish the named public fields;
2. publish the chosen location precision;
3. preserve public provenance for later corrections and status changes;
4. the current version of Human Mesh rules;
5. the right to correct or withdraw.

Consent to one field does not imply consent to additional fields.

Silence, browsing the site, being mentioned in a source, or appearing in an external dataset is **not registration**.

GroundMesh must never scrape or import people into the Human Mesh without their own declaration.

## What membership may never determine

Human Mesh participation must not become a prerequisite for ordinary human dignity, rights, aid, employment, credit, housing, healthcare, voting, movement, or access to essential services.

GroundMesh may use declared capabilities and consent to coordinate voluntary work. It may not turn membership into a social-credit gate.

## Scale architecture direction

Planetary scale should grow from append-only events rather than one mutable master profile.

Conceptual layers:

1. **Declaration record** — the current public identity/location/consent envelope.
2. **Accountability events** — self-authored public commitments, corrections, disclosures, and withdrawals.
3. **Stewardship provenance** — who accepted, changed, or moderated a public record and why.
4. **Private enrollment service** — separate handling for contact or proportionate verification when operationally needed.
5. **Public projections** — maps, directories, counts, and coordination views derived from consented public records.

Later scaling may use signatures, content-addressed events, regional replicas, and multiple independent stewards. Those are implementation questions for later guarded stages; v0.1 does not pretend they are already solved.

## Rollout gates

### H0 — Foundation

- human-readable architecture
- public-record schema
- synthetic fixture
- validator and CI
- public foundation page
- broad intake remains closed

### H1 — Trusted-circle dry run

Reuse ADR-0005 pilot infrastructure with the Human Mesh schema. Test correction, withdrawal, duplicate handling, moderation, and private/public separation with a very small invited cohort.

### H2 — Limited public invitation

Open a bounded public cohort only after the registration readiness checklist is green and H1 operational evidence exists.

### H3 — Multi-steward registration

Introduce independent stewardship/review capacity so one person is no longer the operational bottleneck for acceptance, correction, or withdrawal.

### H4 — Global open invitation

Any human may submit a declaration. This is still voluntary participation, not compulsory registration. Capacity, abuse handling, privacy, moderation, rollback, and independent stewardship must already exist at scale.

### H5 — Distributed Human Mesh

Multiple independent nodes can preserve and serve consented public declarations and accountability events without one account, host, person, institution, or CI becoming the sole registry authority.

No timetable is implied by these stages.

## Relationship to Behavior Atlas

The Human Mesh and Behavior Atlas must stay distinct.

Behavior Atlas maps evidence-backed footprints of projects, institutions, programs, policies, contracts, or events. It does not generate a Human Mesh reputation score.

Human Mesh records voluntary human declarations and self-authored accountability events. It does not convert Behavior Atlas findings into labels on people.

A public action performed by a steward may be provenance-linked across systems, but interpretation remains evidence-specific rather than identity-wide.

## Relationship to the Global Node Ledger

The existing Global Node Ledger is the earliest public prototype of this idea. Human Mesh v0.1 does not erase it.

The ledger should evolve from "real name + real city" toward:

- stable public identity or stable pseudonym;
- coarse location chosen by the participant;
- explicit consent;
- lifecycle status;
- later append-only accountability events.

Existing public records should not be silently rewritten. Any migration should be explicit and reviewable.

## Invariant checks

This foundation is intentionally constrained by:

- **GM-INV-I** — accountability without unnecessary adversarial escalation;
- **GM-INV-II** — visible rules, provenance, and public stewardship boundaries while preserving legitimate privacy;
- **GM-INV-III** — no optimization for dominance or engagement capture;
- **GM-INV-IV** — the registry is stewardship infrastructure, not proprietary ownership of human identity;
- **GM-INV-V** — later public modifications must preserve the invariant core;
- **GM-INV-VI** — joining, remaining, correcting, and leaving remain voluntary;
- **GM-INV-VII** — no single human or CI may become permanent absolute registry authority;
- **GM-INV-VIII** — participation may pause without loss of dignity.

## Foundation rule

**Make voluntary responsibility easier to see; never make human worth computable.**
