# Needs / Offers Readiness Checklist

Use this before opening any public GroundMesh needs/offers doorway, including a GitHub issue template, public page, public data feed, external form, matching workflow, or public coordination board.

Current posture: no public needs/offers feed is live. GroundMesh may describe the coordination model, but it must not invite broad real-world requests or offers until this checklist is honestly green.

## 1. Scope And Promise

- The doorway has a named purpose, audience, and steward.
- The first release is narrow: trusted circle, limited geography, limited categories, or read-only demonstration.
- Public copy says it is not an emergency service, not a confidential intake channel, not a live aid-routing platform, not a verified marketplace, and not a guaranteed matching service.
- The doorway states what GroundMesh can do today and what remains experimental.
- The release can be paused without stranding participants.

## 2. Data And Privacy

- Every submitted field is necessary for the named purpose.
- Public-by-default fields are clearly separated from private review-only fields.
- No field requests private addresses, identity documents, secrets, medical details, legal claims, emergency-only information, or high-risk personal data.
- Any real person name, image, story, location, or contact detail requires explicit consent for the exact public use.
- A data-processing record exists before collecting real submissions.
- Retention, deletion, correction, and withdrawal handling are named.

## 3. Consent And Posting

- The submitter sees a clear public-posting warning before submitting anything public.
- The submitter can choose ordinary public contact without implying membership, obligation, or acceptance.
- Email copy says ordinary email is not confidential.
- The flow does not invite minors, vulnerable people, or crisis situations into a public issue queue.
- The flow never treats silence, excitement, or repeated contact as consent.

## 4. Moderation And Capacity

- At least one human steward is responsible for reviewing new signals.
- Expected review timing is stated.
- The steward can pause intake quickly.
- Spam, harassment, accusations, doxxing, scams, and urgent safety material have rejection or removal rules.
- There is a route for corrections and disputes that does not shame the submitter.
- The system refuses requests beyond handling capacity.

## 5. Coordination Integrity

- Need and capacity records include unit, place, time window, quality threshold, source, and uncertainty where applicable.
- Self-declared information is labeled as self-declared unless independently verified.
- A possible match is presented as a proposal, not a command or promise.
- No autonomous allocation, dispatch, prioritization, or publication occurs.
- No person-worth, moral, reputation, reliability, desperation, generosity, or deservingness score is created.
- No public ranking of people, households, donors, volunteers, or recipients is created.

## 6. Legal And Safety Gate

- ADR-0008 and `docs/legal/PUBLICATION_GATE.md` have been read for the exact release.
- The release does not request money, donations, fees, custody of funds, or value exchange unless the separate money-flow gate is complete.
- The release does not provide legal, medical, mental-health, emergency, immigration, benefits, tax, investment, or safety advice.
- The release does not publish accusations about named people.
- The release has a human steward sign-off through a PR, issue, or release record.

## 7. Technical Handling

- The public surface has been tested with synthetic submissions only.
- Public and private storage paths are separate.
- The static docs layer does not pretend to be a secure private intake system.
- The page, issue template, or feed has a rollback path and can be rolled back by one normal PR revert.
- Atlas entries, status notes, privacy text, and public navigation are updated only for the surfaces actually opened.
- CI includes a guard that makes accidental public opening visible in review.

## 8. Launch Discipline

- A release record names the paths opened, steward, scope, review date, validation commands, and residual risks.
- First use is observed before expansion.
- Expansion happens after demonstrated handling, not enthusiasm alone.
- If the doorway creates confusion, harm, spam, or pressure, it is paused before being widened.

## Stop Conditions

Do not open or expand a needs/offers doorway if any of these are true:

- emergency, confidential, sensitive, or identifying material is likely to enter a public queue
- no steward is available to review new submissions
- the release implies guaranteed aid, matching, protection, delivery, funding, or verification
- the release creates public person rankings or reputation dynamics
- money, fundraising, or value exchange is involved without a separate legal/accounting gate
- the public surface cannot be paused or reverted quickly
- the release depends on unreviewed CI-generated conclusions

## Green Definition

This checklist is green only when the exact proposed needs/offers release can pass every section above with honest evidence, named human stewardship, and a reversible launch path.
