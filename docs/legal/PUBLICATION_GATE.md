# GroundMesh Publication Gate

Status: Active release checklist
Date: 2026-09-03

## Applies To

Use this gate before publishing or expanding:

- Behavior Atlas public-alpha cases
- Human Mesh or registration intake
- public claims about real projects, institutions, contracts, or events
- donation, sponsorship, grant, payment, or value-exchange pages
- any page that could be read as legal, safety, emergency, medical, financial, or rights guidance

## Required Before Release

- Scope is named: what is being released, where, and for whom.
- Repository state is clean or every dirty change is preserved and understood.
- Atlas registry has an entry for the artifact or a clear reason one is not needed.
- Source rights are checked; no copied material exceeds safe quotation or license boundaries.
- Personal data is absent, minimized, or covered by an approved data-processing record.
- No secrets, private evidence, credentials, or confidential correspondence are committed.
- Claims are evidence-linked, limited, and carry counterevidence or uncertainty where material.
- Person subjects, scores, rankings, enemy labels, motive inference, guilt findings, and moral verdicts are absent.
- CI assistance is logged or disclosed when material to public-interest text.
- A human steward signs the release by PR, commit, or written release note.
- Correction, withdrawal, and rollback paths are visible.
- The relevant validation scripts pass.

## Stop Conditions

Stop and do not publish if any of these are true:

- a real person becomes the subject of assessment
- a case relies on private, leaked, identifying, or unlicensed evidence
- a claim implies criminality, motive, guilt, corruption, bad faith, or enemy status without counsel-approved wording and an evidence process
- a reviewer is being treated as plural review when only one reviewer acted
- a page invites broad real-human registration before moderation, consent, retention, and withdrawal handling exist
- a money path is public before the recipient, purpose, tax/accounting posture, and refund/error handling are documented
- the publication would be hard to reverse without erasing history
- the release depends on an unreviewed CI-generated conclusion

## Behavior Atlas Extra Gate

Before any Behavior Atlas public-alpha expansion:

- run schema validation on the case bundle
- run semantic validation on the case bundle
- run negative fixture validation
- update or confirm privacy/harm review
- update or confirm public-alpha policy fit
- confirm review-due date is in the future
- confirm public page has correction path and single-reviewer warning where applicable
- confirm restore drill still proves rollback from the release manifest

## Release Record

Each high-risk release should leave a short record containing:

- release name and paths
- date and steward
- source of authority, such as ADR, policy, issue, or PR
- validation commands and outcomes
- known residual risks
- next review date
