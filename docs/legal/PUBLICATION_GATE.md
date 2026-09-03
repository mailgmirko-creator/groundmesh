# GroundMesh Publication Gate

Status: Active release checklist
Date: 2026-09-03

## Applies To

Use this gate before publishing or expanding:

- Behavior Atlas public-alpha cases
- Human Mesh or registration intake
- needs/offers, public coordination, or capacity-matching intake
- Mesh Credits, seed-vault economy material, tokens, wallets, fiat bridges, public balances, rewards, or other money/value-exchange designs
- Balance Engine, TSL, CI action-selection, optimization, decision-support API, public ledger, dashboard, or runtime surfaces
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
- a needs/offers or matching surface opens before moderation, privacy, correction, rollback, no-emergency, no-confidential, and no-ranking rules are in place
- a token, credit, wallet, fiat bridge, public balance, reward, payment, fundraising, or other value-exchange surface opens before legal, tax/accounting, privacy, anti-fraud, and rollback review
- a Balance Engine or TSL surface performs autonomous allocation, publication, governance, punishment, scoring of people, motive inference, remote authority, or money/value optimization before the relevant gates pass

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

## Needs / Offers Extra Gate

Before any public needs/offers doorway opens:

- complete `docs/checklists/Needs_Offers_Readiness_Checklist.md`
- keep public and private fields separated
- confirm the static docs layer is not presented as confidential intake
- confirm the flow rejects emergencies, sensitive personal data, accusations, scams, and high-risk location details
- confirm no money-flow, fundraising, or value-exchange promise is included
- confirm no autonomous matching, allocation, prioritization, or public person ranking is enabled
- add a release record and status update for the exact opened paths
- deliberately update `scripts/needs-offers-readiness-guard.ps1` or its CI invocation if the release intentionally opens a public surface

## Money / Value Exchange Extra Gate

Before any money/value feature or seed-vault economy material opens:

- complete `docs/checklists/Money_Value_Exchange_Readiness_Checklist.md`
- identify the operator, recipient, purpose, audience jurisdictions, and accounting category
- confirm public copy creates no expectation of profit, charitable deduction, asset ownership, redemption, guaranteed value, passive income, or access-conditioned payment
- confirm no token, wallet, fiat bridge, transferable credit, public balance, reward, exchange, or custody path is enabled without counsel/accounting review
- document refund/error handling, anti-fraud handling, payment-processor/platform terms, privacy handling, and incident response
- keep private payment, wallet, tax, bank, receipt, and support data out of the public repo
- add a release record and status update for the exact opened paths
- deliberately update `scripts/money-value-readiness-guard.ps1` or its CI invocation if the release intentionally opens a public surface

## Balance Engine / CI Action-Selection Extra Gate

Before any Balance Engine or TSL surface becomes public, relied upon, or connected to live action:

- read `docs/tsl/balance-engine-core-spec.md`
- run `scripts/balance-engine-boundary-guard.ps1`
- run `scripts/balance-engine-validate.py`
- confirm outputs are decision-support proposals, not binding governance or allocation orders
- confirm no person-worth score, public ranking, motive inference, enemy label, diagnosis, guilt finding, or loyalty metric is produced
- confirm no autonomous publication, punishment, registration, matching, payment, reward, resource movement, or remote command authority is enabled
- confirm the money/value gate is passed before any value optimization, credit, token, wallet, fiat bridge, payment, reward, sponsorship, grant, or public balance feature exists
- keep private signals, logs, credentials, ledgers, and sensitive correspondence out of the public repo
- add a release record and status update for the exact opened paths
- deliberately update `scripts/balance-engine-boundary-guard.ps1` or its CI invocation if a public surface is intentionally opened

## Release Record

Each high-risk release should leave a short record containing:

- release name and paths
- date and steward
- source of authority, such as ADR, policy, issue, or PR
- validation commands and outcomes
- known residual risks
- next review date
