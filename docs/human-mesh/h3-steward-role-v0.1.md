# GroundMesh Human Mesh H3 Steward Role v0.1

Status: pilot role terms / real-human trial  
Date: 2026-08-30  
Terms id: `human-mesh-h3-steward-role-v0.1`

## Invitation

You are being invited to try a bounded Human Mesh stewardship role.

This is **not** an invitation to agree with GroundMesh, endorse a person, join a governing body, or accept a permanent duty. It is an invitation to inspect a narrow Human Mesh candidate record and make one review decision under visible rules.

Participation is voluntary. You may decline a case, pause, stop serving, or leave the role without penalty.

A steward chair is a responsibility surface, not a throne.

## What a reviewer may do

An active H3 reviewer may inspect a private Human Mesh candidate that has been intentionally presented for review and record one of three bounded decisions:

- `approve` — the candidate may proceed to a separate publication gate;
- `pause` — more information, correction, or clarification is needed before proceeding;
- `reject` — the current candidate should not proceed in its present form.

Every decision should include a short reason that another steward can inspect later.

A reviewer decision **never publishes a person**. The H1-H3 lifecycle bridge has no publish command and records steward decisions as `publication: not_authorized`.

## What accepting this role means

By explicitly accepting the H3 steward role, you agree to review the record rather than judge the human being.

You agree to:

- apply the Human Mesh public contract and consent boundaries rather than personal preference;
- preserve voluntary participation, correction, withdrawal, and the right to pause;
- avoid person scoring, reputation ranking, moral labels, and inferred motives;
- avoid copying private contact details or other unnecessary private information into public material;
- disclose or act on a relevant conflict by declining or pausing the case when appropriate;
- give a reason for a review decision that can be inspected and challenged;
- welcome correction of your own stewardship actions;
- treat uncertainty as a reason to pause rather than invent certainty.

You do **not** agree to be available on demand or to continue indefinitely.

## What this role does not grant

The role does not make a reviewer:

- an owner of GroundMesh;
- a constitutional ruler;
- a legal-identity verifier;
- a moral authority over participants;
- a publisher of Human Mesh records;
- a holder of hidden veto power;
- responsible for every future GroundMesh decision.

The role is deliberately narrower: inspect the candidate, apply the visible boundary, record a reasoned decision, and remain correctable.

## Privacy boundary

The steward roster is kept in the gitignored private Human Mesh pilot workspace.

A steward entry contains only a stable local `steward-*` id, a chosen private display label, assigned roles, active/inactive state, timestamps, and the role-acceptance record. The roster is not a public directory.

The operator should not place private contact details, government identity numbers, home addresses, sensitive traits, or unrelated personal information in the steward label or review reason.

## Explicit acceptance record

GroundMesh H3 does not treat being invited, being named by an operator, or being present during a review as consent to become a steward.

Before reviewer authority becomes active, the person must directly and explicitly accept this terms version. The local operator then records that acceptance as an attestation in the private roster.

The record is intentionally modest. It is **not a cryptographic signature** and does not pretend to prove legal identity. It records that the operator directly received the steward's explicit acceptance of this bounded role.

A clear acceptance is:

> I accept the GroundMesh Human Mesh H3 steward role v0.1 as a reviewer. I understand that it is voluntary, correctable, and does not authorize publication.

Equivalent unambiguous wording is fine.

## First real-human chair test

The first trial should stay small.

1. The invited human reads this role note and the Human Mesh Foundation v0.1.
2. They ask questions, decline, or explicitly accept the reviewer role.
3. Only after acceptance, the local operator adds the steward to the private roster.
4. The reviewer is shown one bounded candidate record and relevant review history. A synthetic or otherwise low-risk case is preferred for orientation before sensitive real work.
5. The reviewer chooses `approve`, `pause`, or `reject` and gives a short reason.
6. The operator records that decision under the reviewer's stable steward id.
7. The reviewer may inspect the stored decision provenance and request correction if it was recorded inaccurately.
8. The reviewer may stop at any time; the operator deactivates the steward without deleting prior provenance.

## Operator commands

From the GroundMesh repository root, after the human has explicitly accepted:

```text
python scripts/human-mesh-pilot-cycle.py steward-add --steward-id steward-<stable-id> --label "<private label>" --role reviewer --accepted-by-human
```

Confirm the roster and human-reviewer count:

```text
python scripts/human-mesh-pilot-cycle.py steward-list
```

Inspect the current candidate and prior decisions:

```text
python scripts/human-mesh-pilot-cycle.py status --node-id <human-node-id>
```

After the reviewer makes a decision:

```text
python scripts/human-mesh-pilot-cycle.py decide --node-id <human-node-id> --decision <approve|pause|reject> --steward-id steward-<stable-id> --reason "<reviewer's reason>"
```

If the steward leaves the role:

```text
python scripts/human-mesh-pilot-cycle.py steward-deactivate --steward-id steward-<stable-id>
```

## What counts as operational plurality

Synthetic reviewers prove that the mechanism works; they do not count as decentralization.

H3 may claim real operational reviewer plurality only when at least two actual humans are simultaneously:

- active;
- assigned the `reviewer` role;
- recorded as having explicitly accepted the current H3 steward-role terms.

A private roster entry without recorded explicit acceptance does not count and cannot exercise reviewer authority.

## Boundary before scale

One successful human trial does not authorize H4 global open invitation, automatic publication, person scoring, identity scraping, or autonomous moderation.

The purpose of this trial is smaller and more important: prove that a second human can understand the responsibility, freely accept it, use it without hidden authority, disagree when needed, and leave cleanly.

## Role rule

**Review the record. Preserve the person's agency. Leave the chair lighter than you found it.**
