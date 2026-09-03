---
title: "GroundMesh Steward Loop"
layout: page
nav_order: 22
---
# GroundMesh Steward Loop

The steward loop is a small local script for broad, memory-heavy, or emotionally charged GroundMesh sessions. It is built for moments when a human or CI assistant has enough access to help, but needs a visible rhythm for choosing the next careful action.

It does not replace human judgment. It creates a compact private report that shows:

- what the current project anchors say
- whether local ChatGPT exports have been imported
- which streams are loudest across the core docs
- which next actions look small, reversible, and useful

## Command

```powershell
.\scripts\groundmesh-steward.ps1
```

The script writes local-only output to:

- `private/steward/steward-latest.md`
- `private/steward/steward-state.json`

That directory is ignored by git because the report may include chat-derived synthesis or local working state.

To validate the steward loop without writing private output:

```powershell
.\scripts\groundmesh-steward.ps1 -CheckOnly
```

## Feeding More Chats

Import a ChatGPT export first:

```powershell
.\scripts\import-chatgpt-export.ps1 -SourcePath <path-to-chatgpt-export.zip>
```

Then run the steward loop again. The loop will notice exported chat manifests under `archives/chatgpt_exports` and propose a grounded promotion step, such as turning one repeated insight into an Atlas note, glossary entry, protocol patch, or test fixture.

## Boundaries

The steward loop must stay boring in the best way:

- no autonomous publishing
- no credential use
- no contacting people
- no private chat publication
- no person assessment, scoring, ranking, motive inference, or enemy labeling
- no broad intake, fundraising, or money-flow launch
- no public release of guarded Behavior Atlas material
- no irreversible actions
- no pretending the project is mature where it is still a prototype

Its job is to preserve rhythm: observe, summarize, choose one smallest real action, and leave a trail.

## Why It Exists

GroundMesh carries structure and source energy. Without structure, the source becomes fog. Without source, the structure becomes paperwork.

The steward loop keeps those two close enough to keep moving.
