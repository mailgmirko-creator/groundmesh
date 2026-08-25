# Behavior Atlas M4 Public Alpha — Privacy and Harm Review

Date: 2026-08-25
Release: `behavior-atlas-m4-public-alpha-v0-1`
Review state: completed release-candidate review; activation requires the human merge gate

## Scope reviewed

This review covers the first public-alpha Behavior Atlas release layer over three existing project-level sourced cases:

- Smokovac–Mateševo motorway section, Montenegro
- Elizabeth line / Crossrail, United Kingdom
- Room for the River Waal / Nijmegen, Netherlands

No new evidence is introduced by the public-alpha presentation layer.

## Data and privacy review

### Personal data

The three primary subjects are projects/programs, not people. The public pages do not create person profiles, person scores, private-address datasets, identity records, or sensitive-personal-data collections.

Named organizations and public institutions appear only as source publishers, project actors, or public-role context already present in inspectable public records.

### Correction channel

The current correction path uses ordinary email. This creates a privacy limitation: a person challenging a case may reveal an email address or information in the message body.

Mitigation:

- every public case points to GroundMesh's existing contact/privacy limits;
- correction copy asks for claim/source references rather than personal narratives;
- the public layer does not request passports, identity numbers, private addresses, confidential disclosures, or emergency-only information;
- highly sensitive material should not be sent through ordinary email.

Residual risk: GroundMesh does not yet provide a hardened confidential correction/intake system.

## Harm review

### 1. Reputational spillover

Risk: readers could mistake a project-level pattern assessment for a judgment about a government, institution, contractor, community, or individual.

Mitigations:

- repeated "footprint, not the soul" boundary;
- no person is a Behavior Atlas subject in these cases;
- no motive inference, guilt finding, moral ranking, or composite score;
- single-reviewer warning says the alpha is not adjudicated truth;
- material counterevidence and limitations remain beside supporting evidence.

Residual risk: some readers may still generalize beyond the stated unit of analysis.

### 2. False certainty / visual authority

Risk: a polished public page may feel more certain than the underlying evidence warrants.

Mitigations:

- claims remain visibly `sourced`, not independently adjudicated;
- assessments use named confidence bands (`emerging`) rather than numeric certainty;
- the public index explains the evidence chain and the limits of public alpha;
- pages preserve unresolved tradeoffs instead of forcing a single verdict.

Residual risk: concise summaries necessarily compress evidence.

### 3. Stale evidence

Risk: a correct-at-publication assessment could become misleading as new data appears.

Mitigations:

- each case has an explicit review-due date;
- client-side stale warning appears after the due date;
- release CI rejects already-expired review dates;
- policy requires review, correction, or withdrawal when overdue;
- changelog and Git history preserve superseded states.

Residual risk: static hosting cannot guarantee an immediate steward action on the exact due date.

### 4. Source rot / inaccessible evidence

Risk: external public sources may move, disappear, or change.

Mitigations:

- repo-health checks public links at release time;
- internal case bundles retain source metadata, locators, short integrity fragments, and hashes scoped to those retained fragments;
- public claims remain paraphrased with direct source trails.

Residual risk: GroundMesh does not yet maintain independent archival copies of every source.

### 5. Framing imbalance / missing counterevidence

Risk: source selection can produce an unfair pattern even when every included source is authentic.

Mitigations:

- counterevidence is first-class in the schema and page design;
- each case lists evidence gaps and limitations;
- correction/challenge path explicitly invites missing inspectable counterevidence;
- three different cases were validated before public alpha to test that the model does not force one direction.

Residual risk: all three cases remain small source sets assembled with CI assistance and one human publication gate.

### 6. Political or institutional misuse

Risk: a third party could quote a case selectively as support for an adversarial campaign or institutional attack.

Mitigations:

- public pages avoid moral labels and blame assignment;
- direct source links and limitations make selective quotation easier to challenge;
- GroundMesh publishes project footprints, not target lists or reputation rankings;
- no automation converts these cases into sanctions, eligibility decisions, policing, employment, credit, or access decisions.

Residual risk: GroundMesh cannot control how public text is quoted elsewhere.

## Release decision

Within the current M4 boundary, the foreseeable privacy and harm risks are acceptable for a **small, reversible public alpha** because:

- subjects are projects/programs rather than people;
- evidence trails and limitations remain inspectable;
- independent-review limitations are stated prominently;
- corrections, expiry, and withdrawal paths exist;
- a restore drill is required before release;
- no scoring, automated publication, or consequential decision system is enabled.

This review does **not** approve expansion to person subjects, bulk monitoring, a Cooperation Index, confidential disclosures, or automated public judgments. Those would require separate review and stronger safeguards.
