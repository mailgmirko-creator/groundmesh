# GroundMesh Architecture: Seed / Trust / Mesh / Edge

## Why this note exists
Two earlier framings turned out to be the same architecture seen from two angles:

- `named components + install lanes + staged rollout` is the **execution view**
- `Seed / Trust / Mesh / Edge` is the **structure view**

This note combines both so GroundMesh has one concrete map instead of two half-maps.

## Core answer
GroundMesh should **not** depend forever on a permanent sovereign core.

GroundMesh **does** need a bootstrap center at first:

- to publish releases
- to coordinate registration and first trust
- to recover from failure
- to keep drift low while the system is still young

So the right target is:

> **temporary seed-centered coordination, progressive decentralization, and eventual non-irreplaceability**

Mirko as origin is compatible with GroundMesh outgrowing Mirko as runtime center.

## Why not choose one extreme

### Fully centralized from the start
Strengths:
- easiest to launch
- easiest to debug
- easiest to moderate
- easiest to keep version alignment

Risks:
- single point of failure
- easier capture
- cost and stewardship burden pile onto one node
- can become the opposite of the values it claims

### Fully distributed from the start
Strengths:
- resilient in principle
- naturally anti-capture
- aligned with commons logic
- stronger as more nodes join

Risks:
- hard node discovery
- hard trust bootstrapping
- hard update coordination
- hard abuse handling
- hard job routing under churn
- hard recovery when many weak nodes disagree

## Recommended shape
GroundMesh should split into four layers:

## 1. Seed
Purpose: start, anchor, publish, and recover.

This is not a forever throne. It is the first stable root.

Named components:
- `Reference Node`
- `Public Gateway`
- `Bootstrap Registry`
- `Release Signer`
- `Steward Console`

What belongs here at first:
- public website / PWA entry point
- first registration path
- node directory bootstrap
- release manifests and signed updates
- initial policy publication
- emergency pause / revoke capability

What should leave this layer over time:
- unique control of trust
- unique control of routing
- unique control of storage
- unique control of compute scheduling

## 2. Trust
Purpose: decide what can be believed, accepted, or acted on.

Trust is not just identity. It is consent, provenance, attestation, review, and graceful exit.

Named components:
- `Consent Ledger`
- `Attestation Ledger`
- `Node Reputation Trail`
- `Policy Bundle`
- `Plural Review Path`

What belongs here:
- registration consent and capability declarations
- signed node identity or steward-backed trust bootstrap
- event attestation
- moderation and review pathways
- quorum or steward review for sensitive actions
- rollback and deprecation rules

GroundMesh value: trust must become harder to fake without becoming harder to join with dignity.

## 3. Mesh
Purpose: carry real work across many nodes.

This is where GroundMesh becomes stronger as participation grows.

Named components:
- `Job Router`
- `Work Queue`
- `Ledger Mirrors`
- `State Replicas`
- `Model Worker Pool`
- `Resource Directory`

What belongs here:
- distributed compute execution
- replication and caching
- model inference on capable nodes
- bandwidth-aware routing
- synchronization of non-sensitive shared state
- node health and capacity reporting

Important rule:
- the mesh should carry work as early as possible
- the seed should carry authority only as long as necessary

## 4. Edge
Purpose: meet people and lightweight devices where they are.

The edge is not weak. It is where participation becomes real.

Named components:
- `GroundMesh PWA`
- `Mobile Client`
- `Desktop Client`
- `Light Node Agent`
- `Local Cache`

What belongs here:
- registration and contact flows
- maps, dashboards, messages, and local notices
- local-first interaction
- optional low-impact contribution
- selective sensing, caching, or relay functions

Important rule:
- phones are excellent clients
- phones are not the first place to anchor the mesh backbone

## Where current GroundMesh pieces fit
- `docs/` public site and future PWA -> `Seed` and `Edge`
- `balance_engine/` -> `Trust` and node-local `Mesh` decision support
- `apps/tsl/` -> local and shared interpretation discipline across `Trust` and `Mesh`
- `docs/protocols/TP-03.md` and `docs/invariants/GM-INV-VIII.md` -> `Trust` constraints
- `docs/echo_archive/EA-0001_soul-and-system.md` -> philosophical grounding for behavior under imbalance

The recent thought-signal work belongs here too:
- interpretation hygiene should run locally at nodes before stronger action
- not only at a central authority

## Local plurality: shared protocol, locally expressed life

GroundMesh is planetary infrastructure, not a uniform planetary culture.

The mesh should preserve a small shared machine contract while allowing people and places to remain recognizably themselves.

The shared contract is about things the system must be able to inspect consistently:

- consent;
- provenance;
- correction and withdrawal;
- lifecycle state;
- bounded stewardship authority;
- evidence and uncertainty where claims affect others;
- common technical identifiers where interoperability requires them.

The local expression around that contract should remain broad:

- participant-chosen public names or stable pseudonyms may use their own language and script;
- public statements should not be forced into English or ASCII;
- place names and local labels should preserve native spelling where practical;
- a translation may be added for accessibility, but should not silently replace the participant's original expression;
- local customs, categories, needs, capabilities, and ways of cooperating should not be flattened merely because one global database field would be easier to count;
- one locality may implement a shared protocol differently from another when the difference does not break consent, provenance, safety, or interoperability.

A useful rule is:

> **Shared protocol; locally expressed life.**

This means global coordination should behave more like a mesh of translations than a pipeline of normalization.

The Edge should therefore become increasingly multilingual and locally legible. The Trust layer should stay comparatively small and language-neutral wherever possible. The Mesh should move compatible events and work without requiring every node to become culturally identical. The Seed should publish common contracts, not a preferred human mold.

No localization framework is required merely to state this rule. UTF-8 web/JSON surfaces already carry many scripts. Automatic translation, locale catalogs, language negotiation, and region-specific interfaces should be added only when real participants demonstrate a need for them.

## Reality before shortcut

A recovered design thread from earlier GroundMesh work identified three recurring system failures. They are useful as architecture warnings rather than moral labels:

### Resource-loop dominance

Resources, production, money, energy, compute, and material provision are necessary, but they become distorted when the system treats more resource throughput as equivalent to a good outcome.

Counter-patterns already present in GroundMesh:
- Balance rather than profit/power/dominance as the supreme objective;
- Coordination Field separation of need, capacity, commitments, delivery, externalities, trust, and choice;
- multi-objective reasoning rather than one hidden score.

### Signal-loop dominance

Metrics, status, visibility, credentials, dashboards, predictions, and public claims are useful signals, but they become distorted when the signal substitutes for the underlying reality.

Counter-patterns already present in GroundMesh:
- evidence provenance and correction;
- Behavior Atlas separation of source, evidence item, claim, assessment, and case;
- Human Mesh separation of declared actions from moral identity;
- no person-worth, virtue, reputation-caste, or hidden trust score.

### Control-loop dominance

Coordination and temporary authority are sometimes necessary, but they become distorted when control itself is treated as the solution and one node becomes irreplaceable.

Counter-patterns already present in GroundMesh:
- decentralized agency;
- explicit Founder Custody rather than fictional decentralization;
- plural stewardship and bounded reviewer authority;
- Seed authority designed to shrink, mirror, and eventually become non-irreplaceable.

The common architectural warning is:

> **Do not let a useful abstraction become a shortcut around reality.**

GroundMesh should therefore prefer loops that remain corrigible:

```text
observe
-> attach evidence and uncertainty
-> obtain consent where agency is affected
-> choose
-> act
-> verify outcome
-> correct
-> learn
```

This loop is compatible with local plurality because correction occurs against lived outcomes and inspectable commitments, not against pressure to make every place or person look the same.

## Install lanes
GroundMesh should not ship as one giant install. It should have clear lanes.

### Lane A: Public participant
- install nothing
- use the site or PWA
- can register, read, signal interest, follow updates

### Lane B: Light client
- install the PWA or small desktop/mobile app wrapper later if needed
- can receive notifications, sync local state, and participate more smoothly

### Lane C: Node contributor
- install a lightweight node agent on desktop, mini-PC, home server, or edge box
- can contribute compute, storage, cache, relay, or model work

### Lane D: Steward / reference node
- run the reference node stack
- publish releases
- mirror trust data
- perform recovery and review tasks

## Staged rollout

### Phase 0: Seed reality
- Mirko-centered origin
- one public gateway
- one release path
- one bootstrap registry
- no claim of full decentralization yet

### Phase 1: Invited node growth
- first trusted external nodes join
- node capabilities begin to register
- non-sensitive workloads start distributing
- trust remains mostly steward-backed

### Phase 2: Mirrored trust
- at least two or three steward-capable mirrors
- replicated ledgers
- multiple review paths
- seed no longer equals single machine

### Phase 3: Working mesh
- distributed job routing
- replicated shared state
- model work runs across capable nodes
- graceful degradation if one steward node disappears

### Phase 4: Federated GroundMesh
- no irreplaceable single root
- trust decisions can be plural
- multiple public gateways
- Mirko can step back without GroundMesh collapsing

## Design rules
- No function should remain single-home forever unless there is a clear safety reason.
- Every central function should have a migration path to mirror, quorum, or federation.
- Seed authority is acceptable only when it is explicit, reversible, and shrinkable.
- Trust should decentralize more slowly than compute.
- Compute should decentralize more slowly than public access.
- Public access should be easiest of all.
- Edge devices should default to client-first roles and earn heavier roles by demonstrated capacity.
- Energy generation and physical resilience matter, but they should plug into the mesh as resource classes, not define the software architecture.
- Shared technical contracts should be minimal enough that local language, culture, and expression do not have to be normalized away.
- Translation should add accessibility, not overwrite provenance.
- Common fields exist for interoperability, not to imply one universal human ontology.

## What this means in plain GroundMesh terms
GroundMesh does not need a permanent `Core`.

GroundMesh does need:
- a `Seed` at first
- a `Trust` layer that cannot be hand-waved
- a `Mesh` layer that grows with participation
- an `Edge` layer that lets almost anyone join

That gives us a cleaner sentence than "core vs no core":

> Start centered enough to survive.  
> Distribute enough to become real.  
> Design every center so it can eventually be outgrown.

And for the human world carried by that architecture:

> **Many languages, places, and ways of life; one inspectable consent-and-provenance contract.**

## Immediate next build implication
The next concrete software target should be:

1. strengthen the public site/PWA as the universal edge
2. define the first lightweight node agent contract
3. keep trust and registration stewarded for now
4. distribute non-sensitive compute before distributing sensitive authority
5. preserve original local expression at the edge before adding automatic translation or normalization machinery

This is the smallest realistic path from "origin through Mirko" to "GroundMesh continues without requiring Mirko's machine to stay on forever" while also allowing the mesh to become more global without becoming more uniform.
