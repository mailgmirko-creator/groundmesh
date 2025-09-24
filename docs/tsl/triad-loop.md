# Tranquility Protocol — Triad Loop (Instinct → Reason → Wisdom)

This page documents the minimal TSL decision loop used by GroundNode.

## What it does
- **Detect** raw signals (instinct baseline)
- **Evaluate** with rules/thresholds (reason frame)
- **Align** with contextual weights + guardrails (wisdom integration)
- **Act** the smallest sufficient action, then **Learn** and log a Transparency note

## Run locally
    cd C:\Projects\GroundMesh-DEV
    python .\balance_engine\tsl_loop.py
    # or
    py .\balance_engine\tsl_loop.py

## Output (sample)
- Transparency JSON line
- A final `RESULT:` block with action, assessment, and outcome

**Source:** `balance_engine/tsl_loop.py`
