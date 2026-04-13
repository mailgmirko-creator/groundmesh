---
layout: default
title: Get Started
permalink: /get-started/
---

# Get Started - GroundMesh

This markdown page is the lightweight fallback for the builder start path.
If the richer HTML page is available, prefer [the builder start page](index.html).

## GroundMesh in one line

GroundMesh is the canonical core repo for the public docs layer, Atlas, contributor flow,
governance artifacts, and trust scaffolding around the wider project.

## Two-repo working pattern

- `GroundMesh` = canonical core, Atlas, docs, contributor and trust layer
- `groundmesh-world` = narrative public seed and design reference
- merge by careful translation, not by hard repo collapse

## Quick local start

```powershell
git clone https://github.com/mailgmirko-creator/groundmesh.git
cd groundmesh
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\bootstrap-node.ps1
.\scripts\health-check.ps1
.\scripts\atlas-generate.ps1
```

## First safe steps

1. Open `docs/atlas/index.html`
2. Inspect what already exists before adding anything new
3. Make one small batch of changes
4. Update public status if the visible state changed
5. Regenerate Atlas and rerun health checks

## Useful public pages

- [Front door](../index.html)
- [Atlas](../atlas/index.html)
- [Contributors Hub](../contribute.html)
- [Contact](../contact.html)
- [Privacy](../privacy.html)
