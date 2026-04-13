# 0003 — ChatGPT, Codex, and GitHub Operating Pattern
Date: 2026-04-13T20:05:00Z
Status: Accepted

## Context
GroundMesh now operates across multiple active surfaces:

- ChatGPT for strategy, review, continuity, and interpretation
- Codex for concentrated implementation and repo-local execution
- GitHub for versioned public memory, merge control, and inspectable work history

Those tools are useful together, but they do not automatically share one internal memory across tabs,
products, or sessions. That makes hidden or implied continuity fragile.

GroundMesh also needs a working rule that reduces confusion when many conversations, patches, PRs,
and ideas are alive at once.

## Decision
Use GitHub as the shared external spine between tools.

The working pattern is:

1. ChatGPT is used for:
   - strategy
   - architecture
   - review
   - issue shaping
   - continuity keeping
2. Codex is used for:
   - concrete repo edits
   - implementation batches
   - debugging
   - patch generation
   - local verification
3. GitHub is used for:
   - canonical source of truth
   - issue and PR memory
   - merge gate
   - execution ledger visible to humans and systems

The core rule is:

> Nothing important exists until it is anchored in GitHub.

That anchor may be:

- a repo file
- an issue
- a pull request
- an ADR
- an Atlas entry
- a comment that records a real decision or state change

## Operating guidance

When speed matters:

- let Codex work in a branch-sized batch
- let ChatGPT inspect the diff, PR, or repo state
- merge only what fits Atlas, Tranquility Protocol, and current GroundMesh reality

When clarity matters:

- ask ChatGPT to reduce repo state, PRs, and issues into the next smallest useful step

When continuity matters:

- record decisions in repo docs, ADRs, Atlas, issues, PR bodies, or comments
- do not rely on tool memory alone

When many things are in motion:

- prefer smaller safe batches over large hidden sweeps
- summarize touched files and the next step after each meaningful chunk

## Consequences

- GroundMesh gains a stable cross-tool memory pattern instead of depending on hidden state.
- Work becomes easier to review, recover, and continue after pauses or platform friction.
- ChatGPT, Codex, and GitHub become complementary rather than redundant.
- Stewardship stays human-led while implementation can scale through clearer delegation.
