# 0001 — Why Project Atlas
Date: 2025-09-19T21:49:28Z
Status: Accepted

## Context
We added many moving parts (docs, scripts, pages). People lost overview and we risked duplicating work.

## Decision
Create a small registry (docs/atlas/registry.json) and publish a simple Atlas page (docs/atlas/index.html) with health checks. Update the registry whenever new artifacts are added.

## Consequences
- Faster orientation, less drift, smaller safer changes.
- A place for humans and tools to agree on “what exists”.
