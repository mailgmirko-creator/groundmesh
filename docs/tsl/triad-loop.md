---
title: "TSL — Triad Decision Loop"
layout: page
nav_order: 20
---
# Tranquility Protocol — Triad Loop (Instinct → Reason → Wisdom)

This page documents the minimal TSL decision loop used by GroundNode.

## What it does
- **Detect** raw signals (instinct baseline)
- **Evaluate** with rules/thresholds (reason frame)
- **Interpret** framing drift before escalation when evidence is thin or certainty is spiking
- **Align** with contextual weights + guardrails (wisdom integration)
- **Act** the smallest sufficient action, then **Learn** and log a Transparency note

## Run locally
    cd <repo-root>
    .\scripts\tsl-run.ps1

## Output (sample)
- Transparency JSON line
- A final `RESULT:` block with action, assessment, and outcome

**Source:** `balance_engine/tsl_loop.py`

**See also:** `docs/tsl/balance-engine-core-spec.md`
