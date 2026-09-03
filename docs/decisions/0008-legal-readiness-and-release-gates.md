# 0008 - Legal Readiness and Release Gates
Date: 2026-09-03
Status: Accepted

## Context

GroundMesh now has public documentation, Atlas records, Human Mesh foundations, and Behavior Atlas public-alpha material. The project is becoming understandable enough for outside people to inspect, copy, contact, and possibly rely on.

That makes legal readiness an operating concern, not a final polish task. The immediate need is not to claim legal completeness. The need is to prevent unsafe release steps before counsel, privacy review, evidence review, and human stewardship are ready.

This decision also records one practical fact: files committed to a public GitHub repository are publicly accessible even when they live under a folder named `internal/`. Internal workflow labels do not create confidentiality.

## Decision

GroundMesh adopts legal readiness as a release gate.

The following are now governed by documented gates before expansion:

- Behavior Atlas public cases
- Human Mesh and registration intake
- donation, sponsorship, payment, or other value-exchange surfaces
- public claims about real projects, institutions, contracts, policies, events, or people
- CI-assisted public-interest text
- license and contribution posture

The working documents are:

- `docs/legal/LEGAL_READINESS.md`
- `docs/legal/PUBLICATION_GATE.md`
- `docs/legal/DATA_PROCESSING_REGISTER.md`
- `docs/legal/CI_USE_AND_DISCLOSURE.md`
- `LICENSING.md`
- `docs/behavior-atlas/PATTERNS_NOT_ENEMIES.md`

These documents are guardrails, not legal advice. They preserve a counsel-ready trail and mark stop conditions.

## Behavior Atlas Rule

Behavior Atlas remains patterns, not enemies. It may describe evidenced project-level patterns through bounded lenses. It must not become a person-assessment system, reputation system, enemy map, motive inference engine, guilt-finding process, autonomous publisher, or Cooperation Index.

No new M2 material may be published or expanded into public-alpha form without the public-alpha gate, privacy/harm review, correction path, review-due date, and rollback path.

## CI Rule

CI may assist drafting, validation, comparison, and source review. It may not publish, merge, resolve contested claims, infer motive, make legal judgments, or replace human steward responsibility.

Material CI assistance for public-interest text should be logged and, where appropriate, disclosed.

## License Rule

GroundMesh must not describe TCL-ND-1.0 as OSI open source. Current public wording should use source-available, public source, public docs, or commons-stewarded language unless and until a separate guarded license review changes the license.

## Immediate Implementation Boundary

This decision does not:

- publish a new public case
- open registration
- create a confidential intake
- request donations
- change repository ownership
- change the license
- appoint counsel
- certify legal compliance

It only adds release gates, documentation, tracked hook protection, and tests that make accidental weakening easier to catch.

## Consequences

- GroundMesh can keep moving without pretending risk has disappeared.
- Sensitive material has a clearer place: outside the public repo unless explicitly reviewed and sanitized.
- Public claims get correction and withdrawal paths before expansion.
- License language becomes more honest.
- CI remains an assistant under human stewardship rather than a hidden publisher.
