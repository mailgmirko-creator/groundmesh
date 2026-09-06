# GroundMesh Balance Engine Core Spec v0.1

Status: boundary / experimental local runtime / no public authority
Date: 2026-09-03
Related: GUIDE-COORDINATION-FIELD-V0-1, TP-04, ADR-0006, ADR-0008, CHECKLIST-MONEY-VALUE-EXCHANGE-READINESS

## Purpose

The Balance Engine is the name for a future GroundMesh decision-support layer. Its narrow job is to help turn observed signals into clearer, safer, more reversible next-step proposals.

This document reconciles the existing local `balance_engine/` and `apps/tsl/` files with the current Coordination Field, Human Mesh, Behavior Atlas, legal-readiness, needs/offers, and money/value gates.

This is not a runtime launch, not legal advice, not medical advice, not spiritual authority, not emergency response, and not permission to automate real-world decisions.

## Current Posture

Current ACTIVE state:

- experimental local code exists under `balance_engine/`
- a TinySelfLearner seed exists under `apps/tsl/`
- file-based ledgers and a local dashboard exist outside the public `docs/` Pages surface
- there is no public Balance Engine page, public Balance Engine data feed, autonomous allocator, public scoring surface, money/value optimizer, or live governance engine
- human stewardship remains responsible for release, correction, pause, and rollback

The word "decision" in the current code means an internal decision-support record. It does not mean a binding decision about people, resources, money, governance, publication, registration, or safety.

## Operating Model

The safe v0.1 model is:

```text
observed signal
-> evidence and context
-> interpretation-risk check
-> pre-action checks
-> bounded next-step proposal
-> human review
-> optional non-sensitive log
-> correction or withdrawal when needed
```

The Balance Engine may support:

- clearer framing when evidence is thin
- delay before irreversible action
- proportional and reversible response choices
- visible uncertainty and interpretation risk
- synthetic tests for future coordination patterns
- local-only experimentation with event and decision schemas

The Balance Engine must remain subordinate to the relevant GroundMesh gates. If the work touches real people, Human Mesh and privacy gates apply. If it touches public cases, Behavior Atlas gates apply. If it touches needs/offers or matching, the needs/offers gate applies. If it touches payments, credits, tokens, wallets, grants, sponsorship, rewards, public balances, or value exchange, the money/value gate applies.

## Interpretation Hygiene

The Balance Engine may track fields such as:

- `evidence_strength`
- `ambiguity_level`
- `reversibility`
- `fatigue_load`
- `inner_signals`
- `interpretation_risk`
- `pre_action_checks`

These are process-safety signals. They are not identity claims. They must not become diagnosis, mind reading, motive inference, guilt findings, person-worth scores, public rankings, loyalty metrics, reputation castes, or enemy labels.

Internal confidence values describe how cautious the engine should be about a proposed plan. They must not be used to score a person, group, steward, contributor, donor, applicant, reviewer, node operator, or institution.

## Stop Conditions

Stop and do not publish, automate, or rely on a Balance Engine surface if any of these are true:

- it assigns person-worth, moral worth, reputation, virtue, loyalty, deservingness, or blame scores
- it ranks real people, donors, recipients, reviewers, stewards, contributors, node operators, applicants, or communities
- it infers motives, guilt, corruption, bad faith, enemy status, or inner state as fact
- it performs autonomous allocation, punishment, publication, governance, registration, matching, payment, reward, or resource movement
- it optimizes money/value exchange, Mesh Credits, tokens, wallets, fiat bridges, public balances, sponsorship, grants, or rewards before the money/value gate is passed
- it gives remote shell authority, local machine control, credential use, or node command authority without a specific command contract and human review
- it uses private, sensitive, identifying, emotional, spiritual, medical, legal, payment, wallet, bank, or tax data in public files
- it lets private data, private ledgers, private signals, secrets, or confidential correspondence enter public repository files
- it hides objective functions, weights, thresholds, or evidence handling behind unreviewable automation
- it treats one reviewer, one model, one device, one chat, or one steward loop as plural authority
- it converts private overload, symbolic intensity, or spiritual reflection directly into public doctrine or irreversible action

## First Code Boundary

The first runtime boundary worth hardening is intentionally small:

```text
one synthetic or non-sensitive event JSON
-> one schema-valid decision-support JSON
-> no automatic publication
-> no automatic attestation unless explicitly requested
```

Acceptance criteria:

- valid sample events validate against `balance_engine/schemas/event.schema.json`
- `decide(event)` returns a decision-support record that validates against `balance_engine/schemas/decision.schema.json`
- low-evidence or high-ambiguity inputs add clarification checks before escalation
- confirmed active harm does not stall proportionate protective action behind delay-only checks
- positive event types reinforce and document what worked instead of manufacturing corrective escalation
- tests do not append to ledgers by default
- public `docs/` surfaces remain closed unless a separate release gate opens them deliberately

## Public Surface Boundary

Docs may explain the boundary. Static Pages must not present the Balance Engine as a live public authority.

Before adding a public page, data feed, dashboard, API, issue template, form, hosted service, or workflow around Balance Engine output:

- complete the publication gate
- pass `scripts/balance-engine-boundary-guard.ps1`
- pass `scripts/balance-engine-validate.py`
- define whether the surface is synthetic, internal, invited-pilot, or public
- document privacy handling and rollback
- keep secrets and private ledgers out of the public repository
- update Atlas and `docs/data/status.json`

## Relationship To Preserved Lane Work

The older preserved lane contains useful Balance Engine and Thought Signal Loop material, including a larger candidate core spec and echo note. Those are source signals, not automatic repository truth.

This v0.1 spec deliberately preserves the useful shape while reducing the risk:

- keep interpretation hygiene
- keep event-to-decision-support discipline
- keep human review
- keep synthetic tests
- defer broader runtime, public dashboard, adaptive scoring, remote node orchestration, and value-flow work until their gates are explicit

## Compact Rule

The Balance Engine may help GroundMesh pause, frame, test, and propose.

It may not rule, rank, diagnose, punish, publish, allocate, collect money, move resources, or claim to know the whole person.
