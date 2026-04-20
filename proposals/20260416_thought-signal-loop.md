# Thought Signal Loop for TSL and Balance Engine

## Purpose (why)
The shared idea behind the linked chat is strong for GroundMesh:

- do not wait for harmful action before responding
- treat inner interpretation as part of the system, not just outer behavior
- correct drift at the level of signal formation, not only at the level of output

GroundMesh already has the right shape for this in principle:

- `apps/tsl` learns principles
- `balance_engine/tsl_loop.py` runs `DETECT -> EVALUATE -> ALIGN -> ACT -> LEARN`
- the Balance Engine maps negative motion toward constructive opposites

What is missing is a clear place for **interpretation hygiene**:
an explicit pass that notices when a node is moving from signal into distortion,
fusion, or premature certainty.

## User Story
As a GroundMesh node, steward, or future agent, I want the system to notice
reactive thought patterns before they harden into action, so that balance is
preserved with less force, less shame, and more reversibility.

## Inputs
- Standard external events already handled by the Balance Engine
- Optional internal or reflective signals such as:
  - `offense-reactivity`
  - `certainty-spike`
  - `scarcity-spiral`
  - `adversarial-framing`
  - `fixation`
  - `rumination`
- Context flags:
  - ambiguity level
  - evidence quality
  - reversibility
  - fatigue / load
  - prior unresolved conflict

## Outputs
- A lightweight interpretation assessment alongside the normal event assessment
- A recommended pre-action step when needed, such as:
  - `pause`
  - `request-clarity`
  - `seek-second-witness`
  - `delay-irreversible-action`
  - `restate-observation-without-judgment`
  - `boundary-without-escalation`
- A transparency note that records whether the system corrected interpretation
  before acting

## Acceptance Criteria (checkable)
- [ ] When an event has low evidence and high reactivity, the system prefers
      `request-clarity` or `seek-second-witness` before stronger action.
- [ ] When certainty rises faster than evidence, the system flags interpretation
      risk rather than treating confidence as truth.
- [ ] When an action is irreversible, the system inserts an interpretation
      hygiene step before escalation unless active harm is already confirmed.
- [ ] The added logic remains compatible with current values:
      non-adversarial, proportional, reversible, transparent.

## Non-Goals
- Religious enforcement in code
- Mind reading or coercive emotion scoring
- Replacing human discernment with automated certainty
- Diagnosing mental health states

## Notes / Examples
This idea should be implemented in **shared civic language**, even if the source
inspiration is spiritual. The repo already has that pattern in `TP-03` and
`GM-INV-VIII`: preserve agency, reduce compulsion, treat pressure as
informational, and prefer voluntary re-engagement.

### Best fit in the current code
- `balance_engine/tsl_loop.py`
  Add an `INTERPRET` pass or extend `EVALUATE` so the loop can distinguish:
  - what happened
  - how the node is framing what happened
- `balance_engine/lib/engine.py`
  Add plan templates for interpretation correction, not only opposites-based
  outer response
- `balance_engine/schemas/event.schema.json`
  Add optional reflective fields such as `inner_signals`, `evidence_strength`,
  or `ambiguity_level`
- `balance_engine/schemas/decision.schema.json`
  Add optional fields such as `interpretation_risk`, `pre_action_checks`, and
  `reframe_steps`
- `apps/tsl`
  Teach the learner a principle lexicon around consent, dignity, ambiguity,
  reversibility, and de-escalation so inner drift can be named consistently

### Conceptual translation from the shared chat
The linked conversation repeatedly frames thought as the place where alignment
or captivity begins. In GroundMesh terms, the clean translation is:

- **thought is signal terrain**
- **interpretation is architecture**
- **outputs improve when input framing improves**

That suggests a GroundMesh operating rule:

> Do not only correct action. Correct the interpretation pathway that made the
> action feel necessary.

### Example mappings
- anger -> detect boundary violation, prevent domination
- worry -> slow certainty, improve evidence, preserve reversibility
- offense -> request clarity before attribution
- fixation -> restore dignity, consent, and proportional distance

### Why this matters
Right now the Balance Engine is strongest at responding to explicit event types
like `lie`, `steal`, `kill`, and `destroy`. This proposal extends that same
ethic inward:

- not just "what wrong happened?"
- also "what distortion is forming in the response loop?"

That makes TSL more than a reaction engine. It becomes a balance-preserving
formation loop for GroundMesh in general.
