# Behavior Atlas: Patterns, Not Enemies

Status: Active guardrail
Date: 2026-09-03

## Purpose

Behavior Atlas maps evidenced coordination patterns. It must not create enemies, moral verdicts, hidden rankings, or person assessments.

This note adopts the useful principle from the extracted "GroundMesh Patterns, Not Enemies v0.1" package as a repository guardrail. The extracted package remains candidate work and historical input. The repository state, accepted ADRs, schema, validators, and public-alpha policy remain authoritative.

## Fit With Existing GroundMesh Work

This principle sits under ADR-0006, "Behavior Atlas Begins as an Evidence-First Pilot." ADR-0006 provides the constitutional boundary. `docs/behavior-atlas/PUBLIC_ALPHA_POLICY.md` provides the M4 publication boundary. The schema and validators provide machine checks. This file gives the principle a short human name and makes the non-adversarial posture easy to reload.

Behavior Atlas may:

- map project, institution, public-program, policy, contract, or event patterns
- link claims to inspectable sources and locators
- preserve counterevidence, limitations, correction paths, and review-due dates
- describe cooperation-supporting, extraction-risk, mixed, or unclear directions through bounded lenses
- withdraw, correct, or supersede public-alpha presentations when the evidence or harm review requires it

Behavior Atlas must not:

- assess people as subjects
- score, rank, or reputation-rate people or institutions
- infer motive, guilt, corruption, virtue, intent, or hidden allegiance
- use enemy labels, verdict labels, or moral labels
- publish automatically through CI or any other tool
- treat a single reviewer as plural adjudication
- publish private evidence, identifying evidence, confidential intake material, or secrets
- convert an internal source bundle into a public case without the public-alpha gate

## M2 And M4 Reconciliation

The current repository contains Behavior Atlas case bundles under `internal/behavior-atlas/cases/` and public-alpha case pages under `docs/behavior-atlas/cases/`. "Internal" is a workflow label, not confidential storage, when the repository is public on GitHub. Anything committed to this public repository must be treated as publicly accessible even if it is not linked from the static site.

For that reason, M2 material must stay non-personal, public-source based, and non-secret. No new M2 source bundle may be represented as a public release unless a separate guarded release records the human steward gate, privacy and harm review, correction path, review-due date, and rollback path.

The existing M4 public-alpha pages remain governed by `docs/behavior-atlas/PUBLIC_ALPHA_POLICY.md`, `docs/behavior-atlas/PRIVACY_HARM_REVIEW.md`, the release manifest, and the restore drill.

## Machine Guard

The Behavior Atlas schema and validator reject forbidden field names such as `enemy_label`, `motive_attribution`, `moral_verdict`, `cooperation_score`, `cooperation_index`, `verdict`, `score`, `rank`, and `automatic_publication`. The semantic validator normalizes separators and casing so equivalent spellings are caught.

Negative fixtures under `tests/behavior-atlas/fixtures/` must keep failing. If one passes, the release gate has weakened.

## Steward Rule

When a case feels tempting because it names villains, stop. Reframe the work as an evidence chain about structures, incentives, resource flows, decision points, public claims, correction paths, and uncertainty. If that reframing cannot be done without person judgment or avoidable harm, the case is not ready for GroundMesh publication.
