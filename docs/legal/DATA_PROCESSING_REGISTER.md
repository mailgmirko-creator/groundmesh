# GroundMesh Data Processing Register

Status: Working register
Review date: 2026-09-03

## Rule

GroundMesh must know what personal data it processes before it processes it. No broad public registration, confidential intake, identity verification, or participant database is open from the static docs layer today.

Public Git history is not private storage. Do not commit secrets, private correspondence, identifying evidence, or unpublished participant records.

## Current Register

| Area | Data | Purpose | Storage / Recipient | Current Limit |
| --- | --- | --- | --- | --- |
| Public repo and GitHub Pages | Repository files, public docs, public-source project case material, issue/PR metadata if used | Publish documentation and transparent project history | GitHub repository and GitHub Pages | Public by design; no confidential data belongs here |
| Behavior Atlas public alpha | Project, institution, policy, contract, event, and source-reference data | Evidence-first public-alpha case presentation | Public site and repository history | No person subjects, no scores, no private evidence |
| Contact email | Sender-provided message content and email metadata | Respond to questions, corrections, and participation inquiries | Ordinary email provider chosen by steward | Not a confidential reporting channel |
| Registration pilot tooling | Participant-submitted pilot records only if the local steward-run pilot is activated | Small invited-circle pilot handling | Local/protected storage outside the public repo unless explicitly sanitized | Broad public intake is not open |
| Human Mesh examples | Synthetic example declarations and accountability events | Schema and workflow testing | Repository examples | Synthetic only |
| CI/tool logs | Prompts, tool output, generated drafts, validation output, and review notes | Drafting, validation, and project stewardship | Local tools, connected services, and repository records when committed | Do not paste secrets or confidential personal data into CI tools |

## New Processing Record Template

Before adding a new feature or workflow that touches personal data, create a record with:

- feature or process name
- steward/controller contact
- purpose and public explanation
- data categories
- data source
- lawful basis or consent route to review with counsel
- storage location and access controls
- processors or external services
- countries or cross-border transfer points
- retention period and deletion/withdrawal path
- correction path
- security measures
- incident or breach response owner
- review date

## Review Triggers

Review this register before:

- opening registration beyond an invited pilot
- collecting real Human Mesh declarations
- receiving sensitive corrections or evidence
- adding analytics, forms, comments, payments, mailing lists, or third-party widgets
- publishing a new Behavior Atlas real-world case
- changing hosting, repository visibility, or contact channels
