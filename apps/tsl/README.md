# TinySelfLearner (TSL) — seed

Purpose: learn and internalize the project’s Seven Principles, starting with a simple
token-based pass (no external ML libs). This sets the contract so donated compute
(Transparency Grid) can run learning jobs later.

## Layout
- apps/tsl/principles/principles.yaml — canonical 7 principles (edit this with final wording).
- apps/tsl/tsl_core/learner.py — pure-Python “learning” stub: tokenizes/summarizes principles.
- apps/tsl/jobs/learn_principles.json — example job spec for future distributed runs.
- apps/tsl/artifacts/ — model outputs (e.g., principles_model.json).

## Local test (optional)
Requires Python 3.8+ on PATH.
Run:
python apps/tsl/tsl_core/learner.py apps/tsl/principles/principles.yaml apps/tsl/artifacts

This writes: apps/tsl/artifacts/principles_model.json
