# Behavior Atlas Public Alpha — Expiry, Review, Correction, and Withdrawal Policy

Status: M4 public-alpha policy
Date: 2026-08-25

## Purpose

Public alpha is a reversible evidence publication layer, not a declaration of final truth. Every case must remain traceable, challengeable, time-bounded, and withdrawable without erasing history.

## Publication boundary

A public-alpha case must:

- use a project, institution, public program, policy, contract, or event as the primary subject; person scoring is forbidden
- resolve public claims to inspectable sources and locators through the accepted Behavior Atlas evidence chain
- preserve material counterevidence and limitations beside supporting evidence
- state whether claims are sourced, reviewed, contested, corrected, or retired without implying a stronger review state than actually occurred
- display the single-reviewer warning whenever independent plural review is unavailable
- provide a visible correction path
- carry an explicit review-due date
- remain free of composite scores, ranks, moral labels, guilt findings, and inferred motives

## Review-due and expiry rule

The public-alpha release manifest is the machine-readable authority for each published case's review-due date.

Before a new public-alpha release is accepted, CI must reject any case whose review-due date is already in the past.

After a published case passes its review-due date without a superseding reviewed release:

1. the case is **stale / review overdue** and must not be represented as a current assessment;
2. the public case page displays an overdue warning in the browser using its embedded review-due date;
3. the next stewardship action touching the Behavior Atlas must either review and supersede the case, correct it, or withdraw it from the public-alpha index;
4. the source trail and version history remain available for accountability even if the public presentation is withdrawn.

The static site does not pretend to be a real-time adjudication service. The browser warning is a visibility fallback; stewardship and versioned releases remain the authority.

## Corrections

A correction request should identify the specific case, claim, or source and provide an inspectable reference where possible. Ordinary email is currently the public correction path and is not a confidential intake channel.

Corrections must not silently erase prior claims. Accepted changes should create a new version or superseding record so the previous state remains inspectable in Git history and the release changelog.

## Withdrawal and rollback

If a release loses its evidence trail, causes unresolved material harm, becomes materially misleading, or fails validation, the public-alpha layer may be withdrawn while preserving the internal sourced bundles and prior unlisted previews.

The release manifest records the last known-good pre-alpha Git ref. The restore drill must prove that GroundMesh can reconstruct that baseline in a temporary workspace and verify that the public-alpha front door and public case routes are absent there while the prior guarded previews remain present.

Actual rollback of `main` must use normal version-control stewardship (for example, a reviewed revert or superseding corrective PR). The restore drill never rewrites history or silently changes `main`.

## Human responsibility

Computer Intelligence may assist with source handling, validation, contradiction detection, page generation, expiry visibility, and restore drills. It may not autonomously publish, resolve a contested claim, infer motive, or decide that a harmful release should remain public.

Merging the guarded publication PR is the human release gate for M4 public alpha. It does not convert sourced claims into independently reviewed claims.

## Scope limit

This policy governs the M4 public alpha only. It does not authorize M5 monitoring, bulk data collection, person profiling, autonomous publication, or a Cooperation Index.
